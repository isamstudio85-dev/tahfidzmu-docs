import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/ayah_model_ext.dart';
import 'package:tahfidz_app/models/error_mark.dart';
import 'package:tahfidz_app/models/surah_model.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/assessment_screen.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key, this.isReadOnly = false});
  final bool isReadOnly;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      p.loadSurahForReader(p.activeSetoranSurahNumber);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _nextSurah(AppProvider p) async {
    if (p.activeSetoranSurahNumber < 114) {
      await p.loadSurahForReader(p.activeSetoranSurahNumber + 1);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFDE7),
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  provider.activeSetoranSurahName.isNotEmpty
                      ? provider.activeSetoranSurahName
                      : 'Al-Quran',
                  style: GoogleFonts.amiri(fontSize: 20, color: Colors.white),
                  textDirection: TextDirection.rtl,
                ),
                Text(
                  '${provider.activeSetoranSurahEnglishName}  ·  '
                  'Ayat ${provider.activeSetoranAyahStart}–${provider.activeSetoranAyahEnd}  ·  '
                  '${provider.activeSetoranType.label}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (widget.isReadOnly) {
                  provider.clearErrors();
                  Navigator.pop(context);
                } else {
                  _confirmExit(context, provider);
                }
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Row(
                    children: [
                      _errorBadge(
                        provider.sessionTajwidCount,
                        AppTheme.tajwidColor,
                        Icons.music_note,
                      ),
                      const SizedBox(width: 6),
                      _errorBadge(
                        provider.sessionMakhrojCount,
                        AppTheme.makhrojColor,
                        Icons.record_voice_over,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: provider.isSurahLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.surahLoadError != null
              ? _buildError(provider)
              : provider.currentSurah == null
              ? const Center(child: CircularProgressIndicator())
              : _buildReader(provider),
          bottomNavigationBar: _buildBottomBar(context, provider),
        );
      },
    );
  }

  Widget _buildError(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Gagal memuat Al-Quran',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              provider.surahLoadError ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              onPressed: () => provider.loadSurahForReader(
                provider.activeSetoranSurahNumber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader(AppProvider provider) {
    final surah = provider.currentSurah!;
    final isTasmi = provider.isTasmiSession;
    
    final start = isTasmi ? 1 : provider.activeSetoranAyahStart;
    final end = isTasmi ? surah.ayahs.length : provider.activeSetoranAyahEnd;

    final ayahs = surah.ayahs
        .where((a) => a.numberInSurah >= start && a.numberInSurah <= end)
        .toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: ayahs.length + (surah.number != 1 && surah.number != 9 && start == 1 ? 2 : 1),
      itemBuilder: (context, index) {
        // Bismillah Header
        if (surah.number != 1 && surah.number != 9 && start == 1 && index == 0) {
          return _buildBismillah();
        }
        
        // Legend Header (only for non-read only)
        int legendIndex = (surah.number != 1 && surah.number != 9 && start == 1) ? 1 : 0;
        if (!widget.isReadOnly && index == legendIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                _buildLegend(),
                const SizedBox(height: 8),
                _buildSantriInfo(provider),
              ],
            ),
          );
        }

        // Adjust index for Ayah blocks
        int actualAyahIndex = index - (legendIndex + 1);
        if (surah.number != 1 && surah.number != 9 && start == 1) actualAyahIndex--;
        
        if (actualAyahIndex < 0 || actualAyahIndex >= ayahs.length) return const SizedBox.shrink();

        final ayah = ayahs[actualAyahIndex];
        return _AyahBlock(
          ayah: ayah,
          surahNumber: surah.number,
          sessionErrors: provider.sessionErrors,
          onWordTap: widget.isReadOnly ? (idx, word) {} : (wordIndex, word) => _onWordTap(
            context,
            provider,
            surah.number,
            ayah.numberInSurah,
            wordIndex,
            word,
          ),
        );
      },
    );
  }

  Widget _buildBismillah() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          style: GoogleFonts.amiri(
            fontSize: 28,
            color: AppTheme.darkGreen,
            height: 2,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(
            AppTheme.tajwidColor,
            '1× Tajwid',
            Icons.touch_app_rounded,
          ),
          const SizedBox(width: 14),
          _legendItem(
            AppTheme.makhrojColor,
            '2× Makhroj',
            Icons.touch_app_rounded,
          ),
          const SizedBox(width: 14),
          _legendItem(Colors.grey, '3× Hapus', Icons.clear_rounded),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSantriInfo(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            provider.activeSetoranSantri?.name ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            provider.activeSetoranType.label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppProvider provider) {
    if (widget.isReadOnly) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: const Text(
          'Mode Baca Saja • Menampilkan riwayat kesalahan setoran.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    final isTasmi = provider.isTasmiSession;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTasmi) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.activeSetoranSurahNumber < 114 
                    ? () => _nextSurah(provider)
                    : null,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('LANJUT SURAH BERIKUTNYA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                // Error summary
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Kesalahan: '
                      '${provider.sessionTajwidCount + provider.sessionMakhrojCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Tajwid: ${provider.sessionTajwidCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.tajwidColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Makhroj: ${provider.sessionMakhrojCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.makhrojColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _confirmFinish(context, provider),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Selesai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBadge(int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _onWordTap(
    BuildContext context,
    AppProvider provider,
    int surahNumber,
    int ayahNumber,
    int wordIndex,
    String word,
  ) {
    final key = ErrorMark.generateKey(surahNumber, ayahNumber, wordIndex);
    final current = provider.sessionErrors[key];
    if (current == null) {
      provider.toggleError(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordIndex: wordIndex,
        word: word,
        errorType: ErrorType.tajwid,
      );
    } else if (current.errorType == ErrorType.tajwid) {
      provider.toggleError(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordIndex: wordIndex,
        word: word,
        errorType: ErrorType.makhroj,
      );
    } else {
      provider.removeError(key);
    }
  }

  void _confirmFinish(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesai Setoran?'),
        content: Text(
          'Total kesalahan: ${provider.sessionTajwidCount + provider.sessionMakhrojCount}\n'
          '(Tajwid: ${provider.sessionTajwidCount}, Makhroj: ${provider.sessionMakhrojCount})\n\n'
          'Lanjut ke penilaian akhir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AssessmentScreen()),
              );
            },
            child: const Text('Lanjut Penilaian'),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Setoran?'),
        content: const Text('Semua tanda kesalahan akan hilang. Yakin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              provider.clearErrors();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _AyahBlock extends StatelessWidget {
  const _AyahBlock({
    required this.ayah,
    required this.surahNumber,
    required this.sessionErrors,
    required this.onWordTap,
  });

  final AyahModel ayah;
  final int surahNumber;
  final Map<String, ErrorMark> sessionErrors;
  final void Function(int wordIndex, String word) onWordTap;

  @override
  Widget build(BuildContext context) {
    final words = ayah.words;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Ayat ${ayah.numberInSurah}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.start,
              children: [
                for (int i = 0; i < words.length; i++)
                  WordWidget(
                    word: words[i],
                    errorMark:
                        sessionErrors[ErrorMark.generateKey(
                          surahNumber,
                          ayah.numberInSurah,
                          i,
                        )],
                    onTap: () => onWordTap(i, words[i]),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '﴿${toArabicNumeral(ayah.numberInSurah)}﴾',
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                      height: 2.2,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
