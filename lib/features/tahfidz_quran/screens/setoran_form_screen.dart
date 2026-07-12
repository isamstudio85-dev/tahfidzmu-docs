import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/models/setoran_continuation.dart';
import 'package:tahfidz_app/models/surah_model.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Mulai Setoran Baru'),
        actions: [
          Row(
            children: [
              Text(
                'Mode Cepat',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _isQuickMode ? Colors.white : Colors.white60,
                ),
              ),
              Switch(
                value: _isQuickMode,
                activeThumbColor: Colors.orange,
                onChanged: (v) => setState(() => _isQuickMode = v),
              ),
            ],
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
                                child: Text('Sedang memuat data santri...', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                          else ...[
                            _sectionTitle('Konfigurasi Setoran: ${_selectedSantri!.name}'),
                            const SizedBox(height: 20),
                            _buildTypePicker(),
                            const SizedBox(height: 16),
                            _buildSurahSelector(provider),
                            const SizedBox(height: 16),
                            _buildAyahRangeInput(),
                            
                            if (_isQuickMode) ...[
                              const SizedBox(height: 32),
                              _sectionTitle('Hasil Setoran (Manual)'),
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
                              child: FilledButton.icon(
                                icon: Icon(_isQuickMode ? Icons.save_rounded : Icons.play_arrow_rounded, size: 28),
                                label: Text(
                                  _isQuickMode ? 'SIMPAN HASIL SETORAN' : 'MULAI SIMAK SEKARANG', 
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)
                                ),
                                onPressed: _canStart() && !_isSaving ? (_isQuickMode ? _saveQuickSetoran : _startSetoran) : null,
                              ),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('1. Pilih Santri'),
                const SizedBox(height: 10),
                _buildSantriSelector(),

                const SizedBox(height: 32),
                _sectionTitle('2. Atur Sesi Setoran'),
                const SizedBox(height: 12),
                _buildTypePicker(),
                const SizedBox(height: 12),
                _buildSurahSelector(provider),
                const SizedBox(height: 12),
                _buildAyahRangeInput(),

                if (_isQuickMode) ...[
                  const SizedBox(height: 24),
                  _sectionTitle('3. Hasil Setoran (Manual)'),
                  const SizedBox(height: 12),
                  _buildAssessmentModeToggle(),
                  const SizedBox(height: 16),
                  if (_showDetailedErrors) ...[
                    _buildErrorCounters(),
                    const SizedBox(height: 16),
                  ],
                  _buildFluencyPicker(),
                ],

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    icon: Icon(_isQuickMode ? Icons.save_rounded : Icons.play_arrow_rounded, size: 28),
                    label: Text(
                       _isQuickMode ? 'SIMPAN HASIL SETORAN' : 'MULAI SIMAK SEKARANG', 
                       style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0)
                    ),
                    onPressed: _canStart() && !_isSaving ? (_isQuickMode ? _saveQuickSetoran : _startSetoran) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _isQuickMode 
                      ? 'Mode Cepat: Cocok untuk merekap hasil setoran dari catatan fisik.' 
                      : 'Mode Interaktif: Membuka mushaf digital untuk menyimak ayat.', 
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
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
        
        // QUICK SEARCH BOX
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
    return InkWell(
      onTap: _showSantriPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: _selectedSantri != null ? AppTheme.primaryGreen : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(_selectedSantri?.name ?? 'Pilih Santri...', style: TextStyle(fontSize: 16, fontWeight: _selectedSantri != null ? FontWeight.bold : FontWeight.normal, color: _selectedSantri != null ? Colors.black87 : Colors.grey))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePicker() {
    return Row(
      children: SetoranType.values.map((t) {
        final isSelected = _type == t;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = t),
            child: Container(
              margin: EdgeInsets.only(right: t == SetoranType.ziyadah ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: isSelected ? AppTheme.primaryGreen : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200)),
              child: Center(child: Text(t.label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSurahSelector(AppProvider provider) {
    return InkWell(
      onTap: () => _openSurahSearch(provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: _selectedSurah == null
                  ? const Text('Pilih Surah...', style: TextStyle(color: Colors.grey))
                  : Text('${_selectedSurah!.number}. ${_selectedSurah!.englishName}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            if (_selectedSurah != null) Text(_selectedSurah!.name, style: GoogleFonts.amiri(fontSize: 18, color: AppTheme.primaryGreen), textDirection: TextDirection.rtl),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahRangeInput() {
    return Column(
      children: [
        _rangeCounterTile(
          'Ayat Mulai:', 
          _ayahStart, 
          (v) => setState(() => _ayahStart = v.clamp(1, _selectedSurah?.numberOfAyahs ?? 999)),
          max: _selectedSurah?.numberOfAyahs ?? 999
        ),
        if (_isQuickMode) ...[
          const SizedBox(height: 10),
           _rangeCounterTile(
            'Ayat Selesai:', 
            _ayahEnd, 
            (v) => setState(() => _ayahEnd = v.clamp(_ayahStart, _selectedSurah?.numberOfAyahs ?? 999)),
            max: _selectedSurah?.numberOfAyahs ?? 999,
            color: Colors.blue
          ),
        ],
      ],
    );
  }

  Widget _rangeCounterTile(String label, int value, ValueChanged<int> onChanged, {int max = 999, Color color = AppTheme.primaryGreen}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: color.withValues(alpha: 0.1))
      ),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          _circleBtn(Icons.remove, () => onChanged(value - 1), color: color),
          
          InkWell(
            onTap: () => _showAyahPicker(label, value, max, onChanged),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, color: color, size: 20),
                ],
              ),
            ),
          ),
          
          _circleBtn(Icons.add, () => onChanged(value + 1), color: color),
        ],
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
        _errorCounter('T. Tajwid', _tajwidErrors, (v) => setState(() => _tajwidErrors = v), AppTheme.tajwidColor),
        const SizedBox(width: 12),
        _errorCounter('T. Makhroj', _makhrojErrors, (v) => setState(() => _makhrojErrors = v), AppTheme.makhrojColor),
      ],
    );
  }

  Widget _errorCounter(String label, int val, ValueChanged<int> onChanged, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
             Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
             const SizedBox(height: 8),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _circleBtn(Icons.remove, () => onChanged((val - 1).clamp(0, 99)), color: color, small: true),
                 Text('$val', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                 _circleBtn(Icons.add, () => onChanged((val + 1).clamp(0, 99)), color: color, small: true),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tingkat Kelancaran:', 
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)
          ),
          const SizedBox(height: 12),
          StarRatingWidget(
            rating: _fluencyRating, 
            onChanged: (v) => setState(() => _fluencyRating = v),
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            _getFluencyLabel(_fluencyRating), 
            style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.bold)
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

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = AppTheme.primaryGreen, bool small = false}) => 
    InkWell(onTap: onTap, child: Container(padding: EdgeInsets.all(small ? 4 : 6), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: color.withValues(alpha: 0.2))), child: Icon(icon, size: small ? 14 : 18, color: color)));

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
      final record = await provider.saveManualSetoran(
        santri: _selectedSantri!,
        type: _type,
        surah: _selectedSurah!,
        ayahStart: _ayahStart,
        ayahEnd: _ayahEnd,
        tajwidErrors: _showDetailedErrors ? _tajwidErrors : 0,
        makhrojErrors: _showDetailedErrors ? _makhrojErrors : 0,
        fluencyRating: _fluencyRating,
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
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _sectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800, letterSpacing: 0.5));
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
