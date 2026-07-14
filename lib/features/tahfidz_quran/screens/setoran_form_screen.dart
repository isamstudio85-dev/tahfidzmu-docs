import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/models/setoran_continuation.dart';
import 'package:tahfidz_app/models/surah_model.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/services/quran_service.dart';
import 'package:tahfidz_app/core/utils/gamification_utils.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_reader_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/verification_gate.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';

class SetoranFormScreen extends StatefulWidget {
  const SetoranFormScreen({
    super.key,
    this.santri,
    this.initialSurah,
    this.initialAyahStart,
    this.initialType,
    this.isQuickModeInitial = false,
  });
  final Santri? santri;
  final SurahInfo? initialSurah;
  final int? initialAyahStart;
  final SetoranType? initialType;
  final bool isQuickModeInitial;

  @override
  State<SetoranFormScreen> createState() => _SetoranFormScreenState();
}

class _SetoranFormScreenState extends State<SetoranFormScreen> {
  Santri? _selectedSantri;
  SetoranType _type = SetoranType.ziyadah;
  SurahInfo? _selectedSurah;
  int _ayahStart = 1;
  String _calculationMethod = 'ayat';
  
  // Halaman & Baris fisik untuk Mode Cepat Per Baris
  int _pageStart = 1;
  int _lineStart = 1;
  int _pageEnd = 1;
  int _lineEnd = 15;
  
  // QUICK MODE STATE
  late bool _isQuickMode;
  int _ayahEnd = 10;
  int _tajwidErrors = 0;
  int _makhrojErrors = 0;
  int _fluencyRating = 5;
  bool _showDetailedErrors = false;
  bool _isSaving = false;

  // WIDE MODE SEARCH
  final TextEditingController _santriSearchCtrl = TextEditingController();
  String _santriQuery = '';

  @override
  void initState() {
    super.initState();
    _isQuickMode = widget.isQuickModeInitial;
    _selectedSantri = widget.santri;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      
      // AUTO-SELECT FIRST STUDENT IF NONE PROVIDED
      if (_selectedSantri == null) {
        final list = provider.isMusyrif && provider.linkedMusyrif != null
            ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
            : provider.santriList;
        if (list.isNotEmpty) {
          setState(() => _selectedSantri = list.first);
        }
      }

      if (_selectedSantri != null) {
        _applyContinuation(provider, _selectedSantri!);
      }
    });

    if (widget.initialSurah != null) {
      _selectedSurah = widget.initialSurah;
      _type = widget.initialType ?? SetoranType.ziyadah;
      _ayahStart = widget.initialAyahStart ?? 1;
      _ayahEnd = (_ayahStart + 9).clamp(_ayahStart, _selectedSurah!.numberOfAyahs);
    }
  }

  @override
  void dispose() {
    _santriSearchCtrl.dispose();
    super.dispose();
  }

  void _showSantriPicker() {
    final provider = context.read<AppProvider>();
    final list = provider.isMusyrif && provider.linkedMusyrif != null
        ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
        : provider.santriList;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Pilih Santri', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: CircleAvatar(backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1), child: Text(list[i].name[0], style: const TextStyle(color: AppTheme.primaryGreen))),
                  title: Text(list[i].name),
                  onTap: () async {
                    final targetSantri = list[i];
                    final bool needsVerification = !_isQuickMode;
                    final verified = needsVerification 
                      ? await VerificationGate.show(context: context, expectedSantri: targetSantri)
                      : targetSantri;

                    if (verified != null && context.mounted) {
                      setState(() => _selectedSantri = verified);
                      _applyContinuation(provider, verified);
                      Navigator.pop(context);
                    }
                  },
                  trailing: _selectedSantri?.id == list[i].id ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyContinuation(AppProvider provider, Santri santri) async {
    await provider.fetchSantriHistoryOnce(santri.id);
    if (!mounted) return;

    if (provider.surahList.isEmpty) {
      await provider.refreshSurahList();
      if (!mounted) return;
    }
    final suggestion = provider.getNextSetoranSuggestion(santri.id);
    if (suggestion != null) _fillFromSuggestion(suggestion);
  }

  void _fillFromSuggestion(SetoranContinuation s) {
    setState(() {
      _selectedSurah = s.surah;
      _type = s.type;
      _ayahStart = s.ayahStart;
      _ayahEnd = s.ayahEnd;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'BRIEFING SETORAN',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Switch(
                  value: _isQuickMode,
                  activeThumbColor: Colors.orange,
                  onChanged: (v) {
                    setState(() {
                      _isQuickMode = v;
                      if (!v) _calculationMethod = 'ayat';
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: isWide 
          ? Row(
              children: [
                // Left Column: Student List with Search
                Container(
                  width: 280, 
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
                  ),
                  child: _buildWideSantriList(provider),
                ),
                // Right Column: Form Settings (Top Aligned)
                Expanded(
                  child: Container(
                    height: double.infinity,
                    color: const Color(0xFFF8F9FA),
                    alignment: Alignment.topLeft, 
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedSantri == null)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 100),
                                child: Text('MEMILIH HERO...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              ),
                            )
                          else ...[
                            _santriProfileCard(_selectedSantri!),
                            const SizedBox(height: 32),
                            _sectionTitle('KONFIGURASI SETORAN'),
                            const SizedBox(height: 20),
                            _buildTypePicker(),
                            const SizedBox(height: 16),
                            if (_isQuickMode) ...[
                              _buildCalculationMethodPicker(),
                              const SizedBox(height: 16),
                            ],
                            _buildSurahSelector(provider),
                            const SizedBox(height: 16),
                            _buildAyahRangeInput(provider),
                            
                            if (_isQuickMode) ...[
                              const SizedBox(height: 32),
                              _sectionTitle('LAPORAN HASIL (TACTICAL)'),
                              const SizedBox(height: 16),
                              _buildAssessmentModeToggle(),
                              const SizedBox(height: 16),
                              if (_showDetailedErrors) ...[
                                _buildErrorCounters(),
                                const SizedBox(height: 16),
                              ],
                              _buildFluencyPicker(),
                            ],

                            const SizedBox(height: 48),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: _executeButton(),
                            ),
                          ),
                            const SizedBox(height: 16),
                            Text(
                              _isQuickMode 
                                ? 'Mode Cepat: Cocok untuk merekap hasil setoran dari catatan fisik.' 
                                : 'Mode Interaktif: Membuka mushaf digital untuk menyimak ayat.', 
                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSantriSelector(),

                if (_selectedSantri != null) ...[
                  const SizedBox(height: 16),
                  _buildCombinedPickers(),
                  const SizedBox(height: 12),
                  _buildSurahSelector(provider),
                  const SizedBox(height: 12),
                  _buildAyahRangeInput(provider),

                  if (_isQuickMode) ...[
                    const SizedBox(height: 12),
                    _buildAssessmentModeToggle(),
                    const SizedBox(height: 8),
                    if (_showDetailedErrors) ...[
                      _buildErrorCounters(),
                      const SizedBox(height: 8),
                    ],
                    _buildFluencyPicker(),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _executeButton(),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _isQuickMode 
                      ? 'MODE REKAP: Mencatat hasil setoran secara manual.' 
                      : 'MODE INTERAKTIF: Menyimak langsung dengan mushaf digital.', 
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  )
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildWideSantriList(AppProvider provider) {
    final allList = provider.isMusyrif && provider.linkedMusyrif != null
        ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
        : provider.santriList;
    
    final filteredList = _santriQuery.isEmpty 
        ? allList 
        : allList.where((s) => s.name.toLowerCase().contains(_santriQuery.toLowerCase()) || (s.nis?.contains(_santriQuery) ?? false)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text('Daftar Santri', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _santriSearchCtrl,
            onChanged: (v) => setState(() => _santriQuery = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari nama/NIS...',
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredList.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade50),
            itemBuilder: (ctx, i) {
              final s = filteredList[i];
              final isSelected = _selectedSantri?.id == s.id;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: isSelected ? 0.2 : 0.05), 
                  child: Text(s.name[0], style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold))
                ),
                title: Text(
                  s.name, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryGreen : Colors.black87
                  )
                ),
                onTap: () async {
                  final bool needsVerification = !_isQuickMode;
                  final verified = needsVerification 
                    ? await VerificationGate.show(context: context, expectedSantri: s)
                    : s;

                  if (verified != null && mounted) {
                    setState(() => _selectedSantri = verified);
                    _applyContinuation(context.read<AppProvider>(), verified);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSantriSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_selectedSantri != null) return _santriProfileCard(_selectedSantri!);

    return InkWell(
      onTap: _showSantriPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
            const SizedBox(width: 16),
            const Expanded(child: Text('Pilih Santri...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey))),
            const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedPickers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _buildTypePicker(),
        if (_isQuickMode) ...[
          const SizedBox(height: 8),
          _buildCalculationMethodPicker(),
        ],
      ],
    );
  }

  Widget _buildTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: SetoranType.values.map((t) {
        final isSelected = _type == t;
        final color = t == SetoranType.ziyadah ? AppTheme.primaryGreen : Colors.purple;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: t == SetoranType.ziyadah ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : (isDark ? AppTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : (isDark ? Colors.white10 : Colors.grey.shade200), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    t == SetoranType.ziyadah ? Icons.auto_awesome_rounded : Icons.history_edu_rounded,
                    color: isSelected ? Colors.white : color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.label.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalculationMethodPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _calcChip('Ayat', Icons.list_alt_rounded, _calculationMethod == 'ayat', () => setState(() => _calculationMethod = 'ayat'), isDark),
        const SizedBox(width: 8),
        _calcChip('Baris', Icons.format_align_justify_rounded, _calculationMethod == 'baris', () => setState(() => _calculationMethod = 'baris'), isDark),
      ],
    );
  }

  Widget _calcChip(String label, IconData icon, bool selected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? AppTheme.primaryGreen : Colors.grey),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? AppTheme.primaryGreen : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahSelector(AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _openSurahSearch(provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _selectedSurah?.number.toString() ?? '?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: AppTheme.primaryGreen, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILIH SURAH',
                    style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1),
                  ),
                  Text(
                    _selectedSurah?.englishName ?? 'Pilih Surah...',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),
            if (_selectedSurah != null) 
              Text(_selectedSurah!.name, style: GoogleFonts.amiri(fontSize: 16, color: AppTheme.primaryGreen), textDirection: TextDirection.rtl),
            const SizedBox(width: 8),
            const Icon(Icons.map_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahRangeInput(AppProvider provider) {
    if (_isQuickMode && _calculationMethod == 'baris') {
      return _buildLineRangeInput();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxAyahs = _selectedSurah?.numberOfAyahs ?? 999;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        children: [
          _rangeCounterTile('START', _ayahStart, (v) => setState(() => _ayahStart = v.clamp(1, maxAyahs)), max: maxAyahs, color: AppTheme.primaryGreen),
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider(height: 1, thickness: 0.5)),
          _rangeCounterTile('END', _ayahEnd, (v) => setState(() => _ayahEnd = v.clamp(_ayahStart, maxAyahs)), max: maxAyahs, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildLineEstimation(AppProvider provider) {
    if (_selectedSurah == null) return const SizedBox.shrink();
    
    final int endAyah = _isQuickMode ? _ayahEnd : _ayahStart;
    
    return FutureBuilder<int?>(
      future: provider.calculateLinesForRange(_selectedSurah!.number, _ayahStart, endAyah),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 20,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          );
        }
        
        final lines = snapshot.data;
        if (lines == null) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.format_align_justify_rounded, color: AppTheme.primaryGreen, size: 16),
              const SizedBox(width: 8),
              Text(
                'Estimasi: $lines Baris Mushaf',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rangeCounterTile(String label, int value, ValueChanged<int> onChanged, {int max = 999, Color color = AppTheme.primaryGreen}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const Spacer(),
          _circleBtn(Icons.remove, () => onChanged(value - 1), color: color),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _showAyahPicker(label, value, max, onChanged),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text('$value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down_rounded, color: color, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _circleBtn(Icons.add, () => onChanged(value + 1), color: color),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = AppTheme.primaryGreen, bool small = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: EdgeInsets.all(small ? 4 : 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: small ? 14 : 18, color: color),
      ),
    );
  }

  void _showAyahPicker(String title, int current, int max, ValueChanged<int> onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pilih $title', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: max,
                itemBuilder: (ctx, i) {
                  final ayahNum = i + 1;
                  final isSelected = ayahNum == current;
                  return InkWell(
                    onTap: () {
                      onChanged(ayahNum);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          '$ayahNum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentModeToggle() {
    return Row(
      children: [
        _modeChip('Hanya Kelancaran', Icons.star_half_rounded, !_showDetailedErrors, () => setState(() => _showDetailedErrors = false)),
        const SizedBox(width: 8),
        _modeChip('Detail (Koreksi)', Icons.playlist_add_check_rounded, _showDetailedErrors, () => setState(() => _showDetailedErrors = true)),
      ],
    );
  }

  Widget _modeChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label, 
                style: TextStyle(
                  fontSize: 11, 
                  fontWeight: FontWeight.bold, 
                  color: isSelected ? Colors.white : Colors.grey.shade600
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCounters() {
    return Row(
      children: [
        _errorTacticalMeter('TAJWID ERR', _tajwidErrors, (v) => setState(() => _tajwidErrors = v), AppTheme.tajwidColor),
        const SizedBox(width: 12),
        _errorTacticalMeter('MAKHROJ ERR', _makhrojErrors, (v) => setState(() => _makhrojErrors = v), AppTheme.makhrojColor),
      ],
    );
  }

  Widget _errorTacticalMeter(String label, int val, ValueChanged<int> onChanged, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          children: [
             Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
             const SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _circleBtn(Icons.remove_rounded, () => onChanged((val - 1).clamp(0, 99)), color: color.withValues(alpha: 0.5)),
                 Text('$val', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                 _circleBtn(Icons.add_rounded, () => onChanged((val + 1).clamp(0, 99)), color: color),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildFluencyPicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2), width: 1.5)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MISSION FLUENCY RATING', 
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amber.shade900, letterSpacing: 1)
          ),
          const SizedBox(height: 16),
          StarRatingWidget(
            rating: _fluencyRating, 
            onChanged: (v) => setState(() => _fluencyRating = v),
            size: 40,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getFluencyLabel(_fluencyRating).toUpperCase(), 
              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)
            ),
          ),
        ],
      ),
    );
  }

  String _getFluencyLabel(int r) {
    if (r >= 5) return 'Sangat Lancar';
    if (r == 4) return 'Lancar';
    if (r == 3) return 'Cukup Lancar';
    if (r == 2) return 'Kurang Lancar';
    return 'Tidak Lancar';
  }

  Future<void> _openSurahSearch(AppProvider provider) async {
    if (provider.isSurahListLoading) return;
    if (provider.surahList.isEmpty) await provider.refreshSurahList();
    if (!mounted) return;
    final result = await showModalBottomSheet<SurahInfo>(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _SurahSearchSheet(surahList: provider.surahList),
    );
    if (result != null) {
      setState(() {
        _selectedSurah = result; 
        _ayahStart = 1;
        _ayahEnd = (10).clamp(1, result.numberOfAyahs);
      });
      _updateDefaultPages(result);
    }
  }

  Future<void> _updateDefaultPages(SurahInfo surah) async {
    try {
      final s = await QuranService.getSurah(surah.number);
      if (s.ayahs.isNotEmpty && mounted) {
        final startPage = s.ayahs.first.pageNumber ?? 1;
        final startLine = s.ayahs.first.startLine ?? 1;
        setState(() {
          _pageStart = startPage;
          _pageEnd = startPage;
          _lineStart = startLine;
          _lineEnd = 15;
        });
      }
    } catch (e) {
      debugPrint("Error updating default pages: $e");
    }
  }

  bool _canStart() => _selectedSantri != null && _selectedSurah != null;

  void _startSetoran() async {
    final provider = context.read<AppProvider>();
    final bool isAlreadyVerified = widget.santri?.id == _selectedSantri?.id;

    final verified = isAlreadyVerified 
      ? _selectedSantri 
      : await VerificationGate.show(context: context, expectedSantri: _selectedSantri);

    if (!mounted) return;

    if (verified != null) {
      final maxAyah = _selectedSurah!.numberOfAyahs;
      final targetEnd = (_ayahStart + 9).clamp(_ayahStart, maxAyah);
      provider.startSetoranSession(
        santri: verified, 
        type: _type, 
        surah: _selectedSurah!, 
        ayahStart: _ayahStart, 
        ayahEnd: targetEnd,
        calculationMethod: _calculationMethod,
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuranReaderScreen()));
      }
    }
  }

  void _saveQuickSetoran() async {
    if (!_canStart()) return;
    if (!mounted) return;
    setState(() => _isSaving = true);
    
    try {
      final provider = context.read<AppProvider>();
      int finalAyahStart = _ayahStart;
      int finalAyahEnd = _ayahEnd;

      if (_calculationMethod == 'baris') {
        final resolved = await provider.resolveAyahRangeFromLines(
          surahNum: _selectedSurah!.number,
          startPage: _pageStart,
          startLine: _lineStart,
          endPage: _pageEnd,
          endLine: _lineEnd,
        );
        if (resolved != null) {
          finalAyahStart = resolved['ayahStart']!;
          finalAyahEnd = resolved['ayahEnd']!;
        }
      }
      
      final record = await provider.saveManualSetoran(
        santri: _selectedSantri!,
        type: _type,
        surah: _selectedSurah!,
        ayahStart: finalAyahStart,
        ayahEnd: finalAyahEnd,
        tajwidErrors: _showDetailedErrors ? _tajwidErrors : 0,
        makhrojErrors: _showDetailedErrors ? _makhrojErrors : 0,
        fluencyRating: _fluencyRating,
        calculationMethod: _calculationMethod,
      );

      if (mounted && record != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran berhasil disimpan (Mode Cepat).'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildLineRangeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _numberInputTile(
          'Nomor Halaman Mushaf (1-604):', 
          _pageStart, 
          (v) => setState(() {
            _pageStart = v.clamp(1, 604);
            _pageEnd = v.clamp(1, 604);
          }),
          min: 1,
          max: 604,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _numberInputTile(
                'Baris Mulai:', 
                _lineStart, 
                (v) => setState(() {
                  _lineStart = v.clamp(1, 15);
                  if (_lineEnd < _lineStart) _lineEnd = _lineStart;
                }),
                min: 1,
                max: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numberInputTile(
                'Baris Selesai:', 
                _lineEnd, 
                (v) => setState(() {
                  _lineEnd = v.clamp(_lineStart, 15);
                }),
                min: _lineStart,
                max: 15,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberInputTile(
    String label, 
    int value, 
    ValueChanged<int> onChanged, {
    int min = 1, 
    int max = 999, 
    Color color = AppTheme.primaryGreen,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withValues(alpha: 0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleBtn(Icons.remove, () {
                if (value > min) onChanged(value - 1);
              }, color: color, small: true),
              
              InkWell(
                onTap: () {
                  _showGeneralNumberPicker(label, value, min, max, onChanged);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text('$value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down_rounded, color: color, size: 18),
                    ],
                  ),
                ),
              ),
              
              _circleBtn(Icons.add, () {
                if (value < max) onChanged(value + 1);
              }, color: color, small: true),
            ],
          ),
        ],
      ),
    );
  }

  void _showGeneralNumberPicker(String title, int current, int min, int max, ValueChanged<int> onChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempSelected = current;
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                height: 120,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: tempSelected > min ? () => setDialogState(() => tempSelected--) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '$tempSelected',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: tempSelected < max ? () => setDialogState(() => tempSelected++) : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: tempSelected.toDouble().clamp(min.toDouble(), max.toDouble()),
                      min: min.toDouble(),
                      max: max.toDouble(),
                      divisions: max - min > 0 ? max - min : 1,
                      onChanged: (v) => setDialogState(() => tempSelected = v.round()),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text('Pilih'),
              onPressed: () {
                onChanged(tempSelected);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _santriProfileCard(Santri santri) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = GamificationUtils.calculateLevel(santri.totalXP);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          AppAvatar(name: santri.name, radius: 24, imagePath: santri.photoPath, activeFrame: santri.activeFrame, streakDays: santri.streakDays, jenisKelamin: santri.jenisKelamin),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  santri.name.toUpperCase(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text('LVL $level', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Text('${santri.totalXP} XP', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showSantriPicker,
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryGreen, size: 20),
            tooltip: 'Ganti Santri',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _executeButton() {
    final canExecute = _canStart() && !_isSaving;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          if (canExecute)
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: FilledButton.icon(
        icon: Icon(_isQuickMode ? Icons.check_circle_outline_rounded : Icons.menu_book_rounded, size: 28),
        label: Text(
          _isQuickMode ? 'SIMPAN REKAP' : 'SIMAK SETORAN', 
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: canExecute ? (_isQuickMode ? _saveQuickSetoran : _startSetoran) : null,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(
          title, 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900, 
            fontSize: 12, 
            color: isDark ? Colors.white54 : Colors.grey.shade600, 
            letterSpacing: 1.5
          )
        ),
      ],
    );
  }
}

class _SurahSearchSheet extends StatefulWidget {
  const _SurahSearchSheet({required this.surahList});
  final List<SurahInfo> surahList;
  @override
  State<_SurahSearchSheet> createState() => _SurahSearchSheetState();
}

class _SurahSearchSheetState extends State<_SurahSearchSheet> {
  String _query = '';
  List<SurahInfo> get _filtered => _query.isEmpty ? widget.surahList : widget.surahList.where((s) => s.englishName.toLowerCase().contains(_query.toLowerCase()) || s.number.toString() == _query).toList();
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          TextField(decoration: const InputDecoration(hintText: 'Cari surah...', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: 12),
          Expanded(child: ListView.builder(controller: scrollCtrl, itemCount: _filtered.length, itemBuilder: (_, i) {
            final s = _filtered[i];
            return ListTile(
              leading: Text(s.number.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              title: Text(s.englishName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s.numberOfAyahs} ayat'),
              trailing: Text(s.name, style: GoogleFonts.amiri(fontSize: 18, color: AppTheme.primaryGreen), textDirection: TextDirection.rtl),
              onTap: () => Navigator.pop(context, s),
            );
          })),
        ]),
      ),
    );
  }
}
