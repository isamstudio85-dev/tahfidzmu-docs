import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/error_mark.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_reader_widgets.dart';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFDE7),
          appBar: _buildAppBar(provider),
          body: provider.isSurahLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.surahLoadError != null
                  ? _buildErrorState(provider)
                  : provider.currentSurah == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            if (!widget.isReadOnly) _buildLiveDashboard(provider),
                            Expanded(child: _buildReaderContent(provider)),
                          ],
                        ),
          bottomNavigationBar: _buildBottomBar(context, provider),
        );
      },
    );
  }

  Widget _buildLiveDashboard(AppProvider provider) {
    final passed = provider.sessionPassedAyahs.length;
    final failed = provider.sessionFailedAyahs.length;
    final santri = provider.activeSetoranSantri;
    
    // Yearly Target Progress
    final totalMemorized = santri?.totalZiyadahAyahs ?? 0;
    final yearlyTargetDoc = santri != null ? provider.getYearlyTarget(santri.id) : null;
    final yearlyTarget = yearlyTargetDoc?.ayahCount ?? 604;
    final yearlyProgress = (totalMemorized / yearlyTarget).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // 1. Santri Info & Yearly Goal
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(santri?.name ?? 'Santri', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Target Tahunan: ${(yearlyProgress * 100).toStringAsFixed(0)}% Selesai', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                _statusCircle('Lulus', passed, Colors.green),
                const SizedBox(width: 8),
                _statusCircle('Gagal', failed, Colors.red),
              ],
            ),
          ),
          
          // 2. Error Counters (More prominent)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _errorItem('KESALAHAN TAJWID', provider.sessionTajwidCount, AppTheme.tajwidColor),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                _errorItem('KESALAHAN MAKHROJ', provider.sessionMakhrojCount, AppTheme.makhrojColor),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statusCircle(String label, int val, Color color) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Center(child: Text('$val', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _errorItem(String label, int count, Color color) {
    return Row(
      children: [
        Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
      ],
    );
  }

  AppBar _buildAppBar(AppProvider provider) {
    return AppBar(
      title: Column(
        children: [
          Text(
            provider.activeSetoranSurahName.isNotEmpty ? provider.activeSetoranSurahName : 'Al-Quran',
            style: GoogleFonts.amiri(fontSize: 22, color: Colors.white),
            textDirection: TextDirection.rtl,
          ),
          Text(
            '${provider.activeSetoranSurahEnglishName}  ·  ${provider.activeSetoranType.label}',
            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
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
    );
  }

  Widget _buildErrorState(AppProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Gagal memuat Al-Quran'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => provider.loadSurahForReader(provider.activeSetoranSurahNumber), child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildReaderContent(AppProvider provider) {
    final surah = provider.currentSurah!;
    final ayahs = surah.ayahs.where((a) => a.numberInSurah >= provider.activeSetoranAyahStart).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: ayahs.length + (surah.number != 1 && surah.number != 9 && provider.activeSetoranAyahStart == 1 ? 2 : 1),
      itemBuilder: (context, index) {
        if (surah.number != 1 && surah.number != 9 && provider.activeSetoranAyahStart == 1 && index == 0) {
          return const BismillahHeader();
        }

        int legendIndex = (surah.number != 1 && surah.number != 9 && provider.activeSetoranAyahStart == 1) ? 1 : 0;
        if (!widget.isReadOnly && index == legendIndex) {
          return const Padding(padding: EdgeInsets.only(bottom: 20), child: ReaderLegend());
        }

        int actualAyahIndex = index - (legendIndex + 1);
        if (surah.number != 1 && surah.number != 9 && provider.activeSetoranAyahStart == 1) actualAyahIndex--;

        if (actualAyahIndex < 0 || actualAyahIndex >= ayahs.length) return const SizedBox.shrink();

        final ayah = ayahs[actualAyahIndex];
        return RepaintBoundary(
          child: AyahBlock(
            key: ValueKey('${surah.number}_${ayah.numberInSurah}'),
            ayah: ayah,
            surahNumber: surah.number,
            sessionErrors: provider.sessionErrors,
            isPassed: provider.sessionPassedAyahs.contains(ayah.numberInSurah),
            isFailed: provider.sessionFailedAyahs.contains(ayah.numberInSurah),
            isReadOnly: widget.isReadOnly,
            onTogglePassed: () => provider.toggleAyahPassed(ayah.numberInSurah),
            onToggleFailed: () => provider.toggleAyahFailed(ayah.numberInSurah),
            onWordTap: (wordIndex, word) => _onWordTap(context, provider, surah.number, ayah.numberInSurah, wordIndex, word),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, AppProvider provider) {
    if (widget.isReadOnly) return const SizedBox.shrink();

    final totalMarked = provider.sessionPassedAyahs.length + provider.sessionFailedAyahs.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                totalMarked == 0 ? 'Tandai ayat untuk menyimpan' : 'Ayat terakhir ditandai: ${[...provider.sessionPassedAyahs, ...provider.sessionFailedAyahs].reduce((a, b) => a > b ? a : b)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: totalMarked > 0 ? () => _confirmFinish(context, provider) : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('SELESAI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onWordTap(BuildContext context, AppProvider provider, int surahNumber, int ayahNumber, int wordIndex, String word) {
    final key = ErrorMark.generateKey(surahNumber, ayahNumber, wordIndex);
    final current = provider.sessionErrors[key];
    if (current == null) {
      provider.toggleError(surahNumber: surahNumber, ayahNumber: ayahNumber, wordIndex: wordIndex, word: word, errorType: ErrorType.tajwid);
    } else if (current.errorType == ErrorType.tajwid) {
      provider.toggleError(surahNumber: surahNumber, ayahNumber: ayahNumber, wordIndex: wordIndex, word: word, errorType: ErrorType.makhroj);
    } else {
      provider.removeError(key);
    }
  }

  void _confirmFinish(BuildContext context, AppProvider provider) {
    final sessionAyahsWithErrors = provider.sessionErrors.values.map((e) => e.ayahNumber).toSet();
    final neglectedAyahs = sessionAyahsWithErrors.where((n) => !provider.sessionFailedAyahs.contains(n) && !provider.sessionPassedAyahs.contains(n)).toList();

    if (neglectedAyahs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange), const SizedBox(width: 10), const Text('Belum Selesai')]),
          content: Text('Ayat ke-${neglectedAyahs.join(", ")} memiliki kesalahan kata tapi belum Anda beri status (Lulus/Gagal).\n\nPastikan semua ayat ditandai agar tidak terbuang.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('KEMBALI')),
            FilledButton(onPressed: () { Navigator.pop(ctx); _proceedToAssessment(context, provider); }, child: const Text('TETAP SIMPAN')),
          ],
        ),
      );
      return;
    }

    _proceedToAssessment(context, provider);
  }

  void _proceedToAssessment(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Hafalan?'),
        content: Text('Sesi ini akan berakhir pada ayat terakhir yang Anda tandai Lulus.\n\nTotal: ${provider.sessionPassedAyahs.length} ayat lancar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AssessmentScreen())); }, child: const Text('Simpan')),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan?'),
        content: const Text('Seluruh tanda di layar akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          TextButton(onPressed: () { provider.clearErrors(); Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Ya, Batal', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
