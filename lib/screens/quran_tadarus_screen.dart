import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/surah_model.dart';
import '../services/quran_service.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

// ── Entry: surah list ──────────────────────────────────────────────────────────

class QuranTadarusScreen extends StatefulWidget {
  const QuranTadarusScreen({super.key});

  @override
  State<QuranTadarusScreen> createState() => _QuranTadarusScreenState();
}

class _QuranTadarusScreenState extends State<QuranTadarusScreen> {
  List<SurahInfo> _all = [];
  List<SurahInfo> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await QuranService.getSurahList();
      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all
                .where(
                  (s) =>
                      s.englishName.toLowerCase().contains(q) ||
                      s.number.toString().contains(q),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Al-Quran'),
            Text(
              '114 Surah',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari surah...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _SurahTile(surah: _filtered[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Surah list tile ────────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah});
  final SurahInfo surah;

  @override
  Widget build(BuildContext context) {
    final isMeccan = surah.revelationType == 'Meccan';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _SurahReaderScreen(info: surah)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // English + metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.numberOfAyahs} ayat · ${isMeccan ? 'Makkiyah' : 'Madaniyah'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Arabic name
              Text(
                surah.name,
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  color: AppTheme.primaryGreen,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Surah reader ───────────────────────────────────────────────────────────────

class _SurahReaderScreen extends StatefulWidget {
  const _SurahReaderScreen({required this.info});
  final SurahInfo info;

  @override
  State<_SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<_SurahReaderScreen> {
  SurahDetail? _surah;
  bool _loading = true;
  String? _error;
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await QuranService.getSurah(widget.info.number);
      setState(() {
        _surah = s;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              widget.info.name,
              style: GoogleFonts.amiri(fontSize: 20, color: Colors.white),
              textDirection: TextDirection.rtl,
            ),
            Text(
              widget.info.englishName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _showTranslation
                ? 'Sembunyikan terjemah'
                : 'Tampilkan terjemah',
            icon: Icon(
              _showTranslation
                  ? Icons.translate_rounded
                  : Icons.translate_outlined,
            ),
            onPressed: () =>
                setState(() => _showTranslation = !_showTranslation),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: _surah!.ayahs.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _buildBismillahHeader();
                }
                return _buildAyahCard(_surah!.ayahs[i - 1]);
              },
            ),
    );
  }

  Widget _buildBismillahHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (widget.info.number != 1 && widget.info.number != 9)
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              style: GoogleFonts.amiri(
                fontSize: 24,
                color: Colors.white,
                height: 2,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            '${widget.info.englishName}  •  ${widget.info.numberOfAyahs} Ayat  •  '
            '${widget.info.revelationType == 'Meccan' ? 'Makkiyah' : 'Madaniyah'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard(AyahModel ayah) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah number
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ayat ${ayah.numberInSurah}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Arabic text
          Text(
            '${ayah.text}  ﴿${ayah.numberInSurah}﴾',
            style: GoogleFonts.amiri(
              fontSize: 26,
              color: Colors.black87,
              height: 2.0,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          // Translation
          if (_showTranslation && ayah.translation != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              ayah.translation!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
