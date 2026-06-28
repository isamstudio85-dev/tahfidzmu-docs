import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/setoran_continuation.dart';
import '../models/surah_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
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
      // Explicit override from caller (e.g. QuranReader tap)
      _selectedSurah = widget.initialSurah;
      _type = widget.initialType ?? SetoranType.ziyadah;
      _ayahStart = widget.initialAyahStart ?? 1;
      _ayahEnd =
          widget.initialAyahEnd ??
          widget.initialSurah!.numberOfAyahs.clamp(1, 10);
      _ayahStartCtrl.text = _ayahStart.toString();
      _ayahEndCtrl.text = _ayahEnd.toString();
    } else if (widget.santri != null) {
      // Auto-fill continuation on next frame (provider may not be ready yet)
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
            if (provider.santriList.isEmpty)
              _warnCard('Belum ada santri. Tambahkan dulu di menu Santri.')
            else
              _buildSantriPicker(provider),
            // Continuation hint
            if (_selectedSantri != null &&
                _selectedSurah != null &&
                _selectedSantri!.setoranHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lanjutan setoran: Surah ${_selectedSurah!.englishName} '
                          'Ayat $_ayahStart–$_ayahEnd',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedSurah = null;
                          _ayahStart = 1;
                          _ayahEnd = 7;
                          _ayahStartCtrl.text = '1';
                          _ayahEndCtrl.text = '7';
                        }),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            _sectionTitle('2. Jenis Setoran'),
            const SizedBox(height: 8),
            _buildTypePicker(),
            const SizedBox(height: 20),
            _sectionTitle('3. Pilih Surah'),
            const SizedBox(height: 8),
            _buildSurahPicker(provider),
            const SizedBox(height: 20),
            _sectionTitle('4. Rentang Ayat'),
            const SizedBox(height: 8),
            _buildAyahRange(),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic_rounded, size: 22),
                label: const Text('Mulai Setoran'),
                onPressed: _canStart() ? _startSetoran : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
  );

  Widget _warnCard(String msg) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber.shade300),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.amber.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg, style: TextStyle(color: Colors.amber.shade900)),
        ),
      ],
    ),
  );

  Widget _buildSantriPicker(AppProvider provider) {
    return DropdownButtonFormField<Santri>(
      isExpanded: true,
      initialValue: _selectedSantri,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.person_outline),
        hintText: 'Pilih santri...',
      ),
      items:
          (provider.isMusyrif && provider.linkedMusyrif != null
                  ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
                  : provider.santriList)
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s.name + (s.kelas != null ? ' (${s.kelas})' : ''),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
              .toList(),
      onChanged: (s) {
        setState(() => _selectedSantri = s);
        if (s != null) _applyContinuation(provider, s);
      },
    );
  }

  /// Auto-fills surah & ayah from the santri's last setoran.
  void _applyContinuation(AppProvider provider, Santri santri) {
    // If surah list not loaded yet, load it then apply
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

  Widget _buildTypePicker() {
    return Row(
      children: SetoranType.values
          .map(
            (t) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TypeChip(
                  label: t.label,
                  icon: t == SetoranType.ziyadah
                      ? Icons.add_circle_outline
                      : Icons.replay_rounded,
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSurahPicker(AppProvider provider) {
    return GestureDetector(
      onTap: () => _openSurahSearch(provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              color: AppTheme.primaryGreen,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedSurah == null
                  ? Text(
                      'Pilih surah...',
                      style: TextStyle(color: Colors.grey.shade500),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedSurah!.number}. ${_selectedSurah!.englishName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _selectedSurah!.name,
                          style: GoogleFonts.amiri(
                            fontSize: 18,
                            color: AppTheme.primaryGreen,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
            ),
            if (provider.isSurahListLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahRange() {
    final max = _selectedSurah?.numberOfAyahs ?? 999;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _ayahStartCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Dari Ayat',
              prefixIcon: const Icon(Icons.first_page_rounded),
              suffixText: 'max $max',
            ),
            onChanged: (v) {
              final n = int.tryParse(v) ?? 1;
              setState(() => _ayahStart = n.clamp(1, max));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _ayahEndCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Sampai Ayat',
              prefixIcon: const Icon(Icons.last_page_rounded),
              suffixText: 'max $max',
            ),
            onChanged: (v) {
              final n = int.tryParse(v) ?? 7;
              setState(() => _ayahEnd = n.clamp(1, max));
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openSurahSearch(AppProvider provider) async {
    if (provider.isSurahListLoading) return;
    if (provider.surahList.isEmpty) {
      await provider.refreshSurahList();
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<SurahInfo>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SurahSearchSheet(surahList: provider.surahList),
    );

    if (result != null) {
      setState(() {
        _selectedSurah = result;
        _ayahStart = 1;
        _ayahEnd = result.numberOfAyahs.clamp(1, 10);
        _ayahStartCtrl.text = '1';
        _ayahEndCtrl.text = _ayahEnd.toString();
      });
    }
  }

  bool _canStart() =>
      _selectedSantri != null &&
      _selectedSurah != null &&
      _ayahStart >= 1 &&
      _ayahEnd >= _ayahStart &&
      _ayahEnd <= (_selectedSurah?.numberOfAyahs ?? 0);

  void _startSetoran() {
    context.read<AppProvider>().startSetoranSession(
      santri: _selectedSantri!,
      type: _type,
      surah: _selectedSurah!,
      ayahStart: _ayahStart,
      ayahEnd: _ayahEnd,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QuranReaderScreen()),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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

  List<SurahInfo> get _filtered {
    if (_query.isEmpty) return widget.surahList;
    final q = _query.toLowerCase();
    return widget.surahList
        .where(
          (s) =>
              s.englishName.toLowerCase().contains(q) ||
              s.name.contains(q) ||
              s.number.toString() == q,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari nama surah...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final s = _filtered[i];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.number.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        s.englishName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.numberOfAyahs} ayat · ${s.revelationType}',
                      ),
                      trailing: Text(
                        s.name,
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          color: AppTheme.primaryGreen,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      onTap: () => Navigator.pop(context, s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
