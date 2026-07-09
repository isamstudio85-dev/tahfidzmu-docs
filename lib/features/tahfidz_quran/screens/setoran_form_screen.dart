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

class SetoranFormScreen extends StatefulWidget {
  const SetoranFormScreen({
    super.key,
    this.santri,
    this.initialSurah,
    this.initialAyahStart,
    this.initialType,
  });
  final Santri? santri;
  final SurahInfo? initialSurah;
  final int? initialAyahStart;
  final SetoranType? initialType;

  @override
  State<SetoranFormScreen> createState() => _SetoranFormScreenState();
}

class _SetoranFormScreenState extends State<SetoranFormScreen> {
  Santri? _selectedSantri;
  SetoranType _type = SetoranType.ziyadah;
  SurahInfo? _selectedSurah;
  int _ayahStart = 1;

  @override
  void initState() {
    super.initState();
    _selectedSantri = widget.santri;
    if (widget.initialSurah != null) {
      _selectedSurah = widget.initialSurah;
      _type = widget.initialType ?? SetoranType.ziyadah;
      _ayahStart = widget.initialAyahStart ?? 1;
    } else if (widget.santri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<AppProvider>();
        _applyContinuation(provider, widget.santri!);
      });
    }
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
                    final verified = await VerificationGate.show(
                      context: context,
                      expectedSantri: targetSantri,
                    );
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(title: const Text('Mulai Setoran Baru')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
          
          if (isTablet) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('1. Pilih Santri'),
                        const SizedBox(height: 10),
                        _buildSantriSelector(),
                        const SizedBox(height: 32),
                        const Center(child: Text('Musyrif hanya perlu menandai ayat yang lulus/gagal.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, color: Colors.grey.shade300),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('2. Atur Sesi Simak'),
                        const SizedBox(height: 12),
                        _buildTypePicker(),
                        const SizedBox(height: 12),
                        _buildSurahSelector(provider),
                        const SizedBox(height: 12),
                        _buildAyahStartInfo(),
                        const SizedBox(height: 60),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded, size: 28),
                            label: const Text('MULAI SIMAK SEKARANG', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            onPressed: _canStart() ? _startSetoran : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('1. Pilih Santri'),
                const SizedBox(height: 10),
                _buildSantriSelector(),

                const SizedBox(height: 32),
                _sectionTitle('2. Atur Sesi Simak'),
                const SizedBox(height: 12),
                _buildTypePicker(),
                const SizedBox(height: 12),
                _buildSurahSelector(provider),
                const SizedBox(height: 12),
                _buildAyahStartInfo(),

                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text('MULAI SIMAK SEKARANG', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                    onPressed: _canStart() ? _startSetoran : null,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: Text('Musyrif hanya perlu menandai ayat yang lulus/gagal.', style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic))),
              ],
            ),
          );
        },
      ),
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

  Widget _buildAyahStartInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.1))),
      child: Row(
        children: [
          const Icon(Icons.history_edu_rounded, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 16),
          const Text('Ayat Mulai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          _circleBtn(Icons.remove, () => setState(() => _ayahStart = (_ayahStart - 1).clamp(1, 999))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$_ayahStart', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
          ),
          _circleBtn(Icons.add, () => setState(() => _ayahStart = (_ayahStart + 1).clamp(1, _selectedSurah?.numberOfAyahs ?? 999))),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2))), child: Icon(icon, size: 18, color: AppTheme.primaryGreen)));

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
        _selectedSurah = result; _ayahStart = 1;
      });
    }
  }

  bool _canStart() => _selectedSantri != null && _selectedSurah != null;

  void _startSetoran() {
    final maxAyah = _selectedSurah!.numberOfAyahs;
    final targetEnd = (_ayahStart + 9).clamp(_ayahStart, maxAyah);
    context.read<AppProvider>().startSetoranSession(
      santri: _selectedSantri!, 
      type: _type, 
      surah: _selectedSurah!, 
      ayahStart: _ayahStart, 
      ayahEnd: targetEnd,
    );
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuranReaderScreen()));
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
