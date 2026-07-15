import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/services/quran_service.dart';
import 'package:tahfidz_app/services/tafsir_service.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/tajwid_text_widget.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/tajwid_info_bar.dart';
import 'package:tahfidz_app/features/education/screens/educational_list_screen.dart';

/// Mode baca Al-Quran.
enum _ReadMode { mushaf, terjemah, tafsir }

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
  SurahInfo? _selectedSurah;

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
        if (_all.isNotEmpty) {
          _selectedSurah = _all.first;
        }
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
    final bool isWide = MediaQuery.of(context).size.width > 900;

    Widget content = _loading
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
                  itemBuilder: (_, i) => _SurahTile(
                    surah: _filtered[i],
                    isWide: isWide,
                    isSelected: _selectedSurah?.number == _filtered[i].number,
                    onTap: () {
                      if (isWide) {
                        setState(() => _selectedSurah = _filtered[i]);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => _SurahReaderScreen(info: _filtered[i])),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F0),
        appBar: AppBar(
          title: const Text('Al-Quran & Tafsir'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Row(
          children: [
            SizedBox(
              width: 320,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Color(0xFFE5E5E0), width: 1)),
                ),
                child: content,
              ),
            ),
            Expanded(
              child: _selectedSurah == null
                  ? const Center(child: Text('Pilih surah untuk membaca'))
                  : _SurahReaderScreen(
                      key: ValueKey('surah_${_selectedSurah!.number}'),
                      info: _selectedSurah!,
                      hideAppBar: true,
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Al-Quran & Tafsir'),
            Text(
              '114 Surah',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: content,
    );
  }
}

// ── Surah list tile ────────────────────────────────────────────────────────────

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.isWide, required this.isSelected, required this.onTap});
  final SurahInfo surah;
  final bool isWide;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMeccan = surah.revelationType == 'Meccan';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: isSelected && isWide ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
              if (!isWide) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Surah reader ───────────────────────────────────────────────────────────────

class _SurahReaderScreen extends StatefulWidget {
  const _SurahReaderScreen({super.key, required this.info, this.hideAppBar = false});
  final SurahInfo info;
  final bool hideAppBar;

  @override
  State<_SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<_SurahReaderScreen> {
  SurahDetail? _surah;
  bool _loading = true;
  String? _error;
  bool _showTajwid = true;
  _ReadMode _readMode = _ReadMode.terjemah;
  String? _tappedWord;
  String? _tappedRule;

  // Tafsir state
  TafsirSource _selectedTafsir = TafsirSource.quraish;
  Map<int, TafsirEntry> _tafsirData = {};
  bool _tafsirLoading = false;

  String _formatRuleName(String rawRule) {
    switch (rawRule) {
      case 'ghunnah': return 'Ghunnah';
      case 'idghaam_ghunnah': return 'Idgham Bighunnah';
      case 'idghaam_no_ghunnah': return 'Idgham Bilaghunnah';
      case 'ikhfa': return 'Ikhfa Haqiqi';
      case 'ikhfa_shafawi': return 'Ikhfa Syafawi';
      case 'iqlab': return 'Iqlab';
      case 'izhar': return 'Izhar Halqi';
      case 'izhar_shafawi': return 'Izhar Syafawi';
      case 'qalqalah': return 'Qalqalah';
      case 'madd_2': return 'Mad Tabi\'i';
      case 'madd_246': return 'Mad Aridh Lissukun';
      case 'madd_45': return 'Mad Jaiz/Wajib';
      case 'madd_muttasil': return 'Mad Wajib Muttasil';
      case 'madd_munfasil': return 'Mad Jaiz Munfasil';
      case 'madd_6':
      case 'madd_lazim': return 'Mad Lazim';
      default: return rawRule.split('_').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ');
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SurahReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.info.number != widget.info.number) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await QuranService.getSurah(widget.info.number);
      if (mounted) {
        setState(() {
          _surah = s;
          _loading = false;
        });
        // Pre-load tafsir di background
        _loadTafsir();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadTafsir() async {
    setState(() => _tafsirLoading = true);
    try {
      final data = await TafsirService.getTafsirForSurah(
        _selectedTafsir,
        widget.info.number,
      );
      if (mounted) {
        setState(() {
          _tafsirData = data;
          _tafsirLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tafsir: $e');
      if (mounted) setState(() => _tafsirLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _readMode == _ReadMode.mushaf ? Colors.white : const Color(0xFFFFFDE7),
      appBar: widget.hideAppBar ? null : AppBar(
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
            tooltip: _showTajwid
                ? 'Sembunyikan tajwid'
                : 'Tampilkan tajwid berwarna',
            icon: Icon(
              _showTajwid
                  ? Icons.palette_rounded
                  : Icons.palette_outlined,
            ),
            onPressed: () =>
                setState(() => _showTajwid = !_showTajwid),
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
          : Column(
              children: [
                _buildModeToggle(),
                if (_readMode == _ReadMode.tafsir) _buildTafsirSourcePicker(),
                Expanded(
                  child: Stack(
                    children: [
                      _readMode == _ReadMode.mushaf
                          ? _buildRealMushafPageView()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                              itemCount: _surah!.ayahs.length + 1,
                              itemBuilder: (_, i) {
                                if (i == 0) {
                                  return _buildBismillahHeader();
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: _buildAyahCard(_surah!.ayahs[i - 1]),
                                );
                              },
                            ),
                      if (widget.hideAppBar)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'toggle_tajwid_wide',
                                backgroundColor: _showTajwid
                                    ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                                    : AppTheme.primaryGreen.withValues(alpha: 0.1),
                                elevation: 0,
                                onPressed: () => setState(() => _showTajwid = !_showTajwid),
                                child: Icon(
                                  _showTajwid ? Icons.palette_rounded : Icons.palette_outlined,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_tappedWord != null && _tappedRule != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: TajwidInfoBar(
                            ruleName: _tappedRule!,
                            word: _tappedWord!,
                            onClose: () {
                              setState(() {
                                _tappedWord = null;
                                _tappedRule = null;
                              });
                            },
                            onLearnMore: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EducationalListScreen(type: 'tajwid'),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _ReadMode.values.map((mode) {
            final isSelected = _readMode == mode;
            final icon = switch (mode) {
              _ReadMode.mushaf => Icons.menu_book_rounded,
              _ReadMode.terjemah => Icons.translate_rounded,
              _ReadMode.tafsir => Icons.auto_stories_rounded,
            };
            final label = switch (mode) {
              _ReadMode.mushaf => 'Mushaf',
              _ReadMode.terjemah => 'Terjemah',
              _ReadMode.tafsir => 'Tafsir',
            };
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _readMode = mode);
                  if (mode == _ReadMode.tafsir && _tafsirData.isEmpty) {
                    _loadTafsir();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTafsirSourcePicker() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.auto_stories_rounded, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Text(
              'Sumber Tafsir:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TafsirSource>(
                  value: _selectedTafsir,
                  isExpanded: true,
                  isDense: false,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryGreen, size: 28),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Roboto',
                  ),
                  items: TafsirSource.values.map((source) {
                    return DropdownMenuItem(
                      value: source,
                      child: Text(source.label),
                    );
                  }).toList(),
                  onChanged: (source) {
                    if (source != null && source != _selectedTafsir) {
                      setState(() => _selectedTafsir = source);
                      _loadTafsir();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMushafPageView() {
    if (_surah == null || _surah!.ayahs.isEmpty) return const SizedBox.shrink();

    final startPage = _surah!.ayahs.first.pageNumber ?? 1;
    final endPage = _surah!.ayahs.last.pageNumber ?? 1;
    final pageCount = (endPage - startPage + 1).clamp(1, 604);

    return PageView.builder(
      itemCount: pageCount,
      reverse: true, // Membalik halaman dari kanan ke kiri seperti buku Arab asli
      itemBuilder: (context, index) {
        final actualPage = startPage + index;
        final pageAyahs = _surah!.ayahs.where((a) => a.pageNumber == actualPage).toList();
        final String juzLabel = pageAyahs.isNotEmpty 
            ? 'Juz ${QuranJuzUtils.juzOf(_surah!.number, pageAyahs.first.numberInSurah)}'
            : 'Juz';

        return _buildMushafPage(actualPage, pageAyahs, juzLabel);
      },
    );
  }

  Widget _buildMushafPage(int pageNum, List<AyahModel> pageAyahs, String juzLabel) {
    final spans = <InlineSpan>[];
    bool showBismillah = false;
    if (pageAyahs.isNotEmpty && pageAyahs.first.numberInSurah == 1 && widget.info.number != 1 && widget.info.number != 9) {
      showBismillah = true;
    }

    for (final ayah in pageAyahs) {
      spans.addAll(TajwidRichText.buildAyahSpans(
        ayah: ayah,
        showTajwid: _showTajwid,
        onWordTap: (word, rule) {
          setState(() {
            _tappedWord = word;
            _tappedRule = _formatRuleName(rule);
          });
        },
      ));
      spans.add(const TextSpan(text: '  '));
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.info.englishName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen, fontSize: 13),
                ),
                Text(
                  juzLabel,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEEEEEE), thickness: 1),
          const SizedBox(height: 4),
          
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showBismillah) ...[
                      Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                        style: GoogleFonts.amiri(
                          fontSize: 25,
                          color: Colors.black87,
                          height: 1.8,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    RichText(
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: GoogleFonts.amiri(
                          fontSize: 24,
                          color: Colors.black87,
                          height: 2.1,
                        ),
                        children: spans,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFEEEEEE), thickness: 1),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              pageNum.toString(),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBismillahHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Column(
        children: [
          if (widget.info.number != 1 && widget.info.number != 9)
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              style: GoogleFonts.amiri(
                fontSize: 28,
                color: Colors.black87,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          Text(
            '${widget.info.englishName}  •  ${widget.info.numberOfAyahs} Ayat  •  '
            '${widget.info.revelationType == 'Meccan' ? 'Makkiyah' : 'Madaniyah'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
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
          const SizedBox(height: 14),
          // Arabic text with optional tajwid coloring
          if (_showTajwid)
            TajwidRichText(
              ayah: ayah,
              showTajwid: true,
              fontSize: 26,
              onWordTap: (word, rule) {
                setState(() {
                  _tappedWord = word;
                  _tappedRule = _formatRuleName(rule);
                });
              },
            )
          else
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
          // Translation (tampil di mode Terjemah & Tafsir)
          if (_readMode != _ReadMode.mushaf && ayah.translation != null) ...[
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
          // Tafsir
          if (_readMode == _ReadMode.tafsir) ...[
            const SizedBox(height: 10),
            _buildTafsirSection(ayah.numberInSurah),
          ],
        ],
      ),
    );
  }

  Widget _buildTafsirSection(int ayahNumber) {
    if (_tafsirLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final entry = _tafsirData[ayahNumber];
    if (entry == null) {
      return Text(
        'Tafsir tidak tersedia untuk ayat ini.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9), // Light green tint
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Text(
                'Tafsir ${_selectedTafsir.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tafsir text (short / main)
          Text(
            entry.text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
