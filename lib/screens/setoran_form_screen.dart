import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/setoran_continuation.dart';
import '../models/surah_model.dart';
import '../providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'quran_reader_screen.dart';

class SetoranFormScreen extends StatefulWidget {
  const SetoranFormScreen({
    super.key,
    this.santri,
    this.initialSurah,
    this.initialAyahStart,
    this.initialAyahEnd,
    this.initialType,
  });
  final Santri? santri;
  final SurahInfo? initialSurah;
  final int? initialAyahStart;
  final int? initialAyahEnd;
  final SetoranType? initialType;

  @override
  State<SetoranFormScreen> createState() => _SetoranFormScreenState();
}

class _SetoranFormScreenState extends State<SetoranFormScreen> {
  Santri? _selectedSantri;
  SetoranType _type = SetoranType.ziyadah;
  SurahInfo? _selectedSurah;
  int _ayahStart = 1;
  int _ayahEnd = 7;

  final _ayahStartCtrl = TextEditingController(text: '1');
  final _ayahEndCtrl = TextEditingController(text: '7');

  @override
  void initState() {
    super.initState();
    _selectedSantri = widget.santri;
    if (widget.initialSurah != null) {
      _selectedSurah = widget.initialSurah;
      _type = widget.initialType ?? SetoranType.ziyadah;
      _ayahStart = widget.initialAyahStart ?? 1;
      _ayahEnd = widget.initialAyahEnd ?? widget.initialSurah!.numberOfAyahs.clamp(1, 10);
      _ayahStartCtrl.text = _ayahStart.toString();
      _ayahEndCtrl.text = _ayahEnd.toString();
    } else if (widget.santri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = context.read<AppProvider>();
        _applyContinuation(provider, widget.santri!);
      });
    }
  }

  @override
  void dispose() {
    _ayahStartCtrl.dispose();
    _ayahEndCtrl.dispose();
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
                  subtitle: Text(provider.getHalaqahById(list[i].halaqahId)?.nama ?? 'Tanpa Halaqah'),
                  onTap: () {
                    setState(() => _selectedSantri = list[i]);
                    _applyContinuation(provider, list[i]);
                    Navigator.pop(context);
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

  void _applyContinuation(AppProvider provider, Santri santri) {
    if (provider.surahList.isEmpty) {
      provider.refreshSurahList().then((_) {
        if (!mounted) return;
        final suggestion = provider.getNextSetoranSuggestion(santri.id);
        if (suggestion != null) _fillFromSuggestion(suggestion);
      });
      return;
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
      _ayahStartCtrl.text = s.ayahStart.toString();
      _ayahEndCtrl.text = s.ayahEnd.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mulai Setoran Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('1. Pilih Santri'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _showSantriPicker,
              child: IgnorePointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                    hintText: _selectedSantri?.name ?? '-- Pilih Santri --',
                    floatingLabelBehavior: _selectedSantri != null ? FloatingLabelBehavior.always : null,
                  ),
                  controller: TextEditingController(text: _selectedSantri?.name),
                ),
              ),
            ),

            if (_selectedSantri != null && _selectedSurah != null && _selectedSantri!.setoranHistory.isNotEmpty)
              _buildContinuationHint(),

            const SizedBox(height: 24),
            _sectionTitle('2. Jenis Setoran'),
            const SizedBox(height: 12),
            _buildTypePicker(),

            const SizedBox(height: 24),
            _sectionTitle('3. Pilih Surah'),
            const SizedBox(height: 12),
            _buildSurahPicker(provider),

            const SizedBox(height: 24),
            _sectionTitle('4. Rentang Ayat'),
            const SizedBox(height: 12),
            _buildAyahRange(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic_rounded, size: 22),
                label: const Text('Mulai Setoran Sekarang'),
                onPressed: _canStart() ? _startSetoran : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinuationHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2))),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 18, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Expanded(child: Text('Lanjutan: ${_selectedSurah!.englishName} Ayat $_ayahStart–$_ayahEnd', style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _selectedSurah = null), color: AppTheme.primaryGreen, visualDensity: VisualDensity.compact),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87));

  Widget _buildTypePicker() {
    return Row(
      children: SetoranType.values.map((t) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _TypeChip(
            label: t.label,
            icon: t == SetoranType.ziyadah ? Icons.trending_up_rounded : Icons.history_rounded,
            selected: _type == t,
            onTap: () => setState(() => _type = t),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildSurahPicker(AppProvider provider) {
    return InkWell(
      onTap: () => _openSurahSearch(provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEEEEE))),
        child: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: _selectedSurah == null
                  ? Text('Pilih surah...', style: TextStyle(color: Colors.grey.shade400))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_selectedSurah!.number}. ${_selectedSurah!.englishName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_selectedSurah!.name, style: GoogleFonts.amiri(fontSize: 18, color: AppTheme.primaryGreen), textDirection: TextDirection.rtl),
                      ],
                    ),
            ),
            if (provider.isSurahListLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            else const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahRange() {
    final max = _selectedSurah?.numberOfAyahs ?? 999;
    return Row(
      children: [
        Expanded(child: TextFormField(controller: _ayahStartCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Dari Ayat', suffixText: 'max $max'),
            onChanged: (v) => setState(() => _ayahStart = (int.tryParse(v) ?? 1).clamp(1, max)))),
        const SizedBox(width: 16),
        Expanded(child: TextFormField(controller: _ayahEndCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Sampai Ayat', suffixText: 'max $max'),
            onChanged: (v) => setState(() => _ayahEnd = (int.tryParse(v) ?? 1).clamp(1, max)))),
      ],
    );
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
        _selectedSurah = result; _ayahStart = 1; _ayahEnd = result.numberOfAyahs.clamp(1, 10);
        _ayahStartCtrl.text = '1'; _ayahEndCtrl.text = _ayahEnd.toString();
      });
    }
  }

  bool _canStart() => _selectedSantri != null && _selectedSurah != null && _ayahStart >= 1 && _ayahEnd >= _ayahStart;

  void _startSetoran() {
    context.read<AppProvider>().startSetoranSession(santri: _selectedSantri!, type: _type, surah: _selectedSurah!, ayahStart: _ayahStart, ayahEnd: _ayahEnd);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuranReaderScreen()));
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label; final IconData icon; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: selected ? AppTheme.primaryGreen : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey.shade200, width: 1.5)),
        child: Column(children: [Icon(icon, color: selected ? Colors.white : Colors.grey, size: 20), const SizedBox(height: 4), Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade700, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal))]),
      ),
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
