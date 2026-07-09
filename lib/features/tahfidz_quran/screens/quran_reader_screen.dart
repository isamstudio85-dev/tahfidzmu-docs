import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/error_mark.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/models/surah_model.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F0), // Classic warm parchment (Kitab Kuning background)
      appBar: _buildAppBar(context),
      body: Selector<AppProvider, bool>(
        selector: (context, p) => p.isSurahLoading,
        builder: (context, isLoading, child) {
          if (isLoading) return const Center(child: CircularProgressIndicator());
          
          return Selector<AppProvider, String?>(
            selector: (context, p) => p.surahLoadError,
            builder: (context, error, child) {
              if (error != null) return _buildErrorState(context.read<AppProvider>());
              
              return Selector<AppProvider, bool>(
                selector: (context, p) => p.currentSurah == null,
                builder: (context, isSurahNull, child) {
                  if (isSurahNull) return const Center(child: CircularProgressIndicator());
                  
                  return Column(
                    children: [
                      if (!widget.isReadOnly) const _LiveDashboardWrapper(),
                      Expanded(
                        child: _ReaderContentWrapper(
                          isReadOnly: widget.isReadOnly,
                          scrollController: _scrollController,
                          onWordTap: (surahNum, ayahNum, wordIdx, word) =>
                              _onWordTap(context, context.read<AppProvider>(), surahNum, ayahNum, wordIdx, word),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : Selector<AppProvider, int>(
              selector: (context, p) => p.sessionPassedAyahs.length + p.sessionFailedAyahs.length,
              builder: (context, totalMarked, child) {
                final provider = context.read<AppProvider>();
                return FloatingActionButton.extended(
                  onPressed: totalMarked > 0 ? () => _confirmFinish(context, provider) : null,
                  backgroundColor: totalMarked > 0 ? AppTheme.primaryGreen : Colors.grey.shade400,
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: const Text(
                    'SELESAI',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.primaryGreen, // Match logo/dashboard green
      elevation: 0,
      foregroundColor: Colors.white,
      title: Selector<AppProvider, ({String name, String englishName, SetoranType type})>(
        selector: (context, p) => (
          name: p.activeSetoranSurahName,
          englishName: p.activeSetoranSurahEnglishName,
          type: p.activeSetoranType,
        ),
        builder: (context, data, child) {
          return Column(
            children: [
              Text(
                data.name.isNotEmpty ? data.name : 'Al-Quran',
                style: GoogleFonts.amiri(fontSize: 22, color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
              Text(
                '${data.englishName}  ·  ${data.type.label}',
                style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
            ],
          );
        },
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          final provider = context.read<AppProvider>();
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
    final start = provider.activeSetoranAyahStart;
    final end = provider.activeSetoranAyahEnd;
    final total = provider.sessionPassedAyahs.length;
    final surahName = provider.activeSetoranSurahEnglishName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              provider.isFlagChanged ? Icons.save_rounded : Icons.warning_amber_rounded,
              color: provider.isFlagChanged ? AppTheme.primaryGreen : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.isFlagChanged ? 'Simpan Hafalan?' : 'Konfirmasi Batas',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            provider.isFlagChanged
                ? 'Anda akan menyimpan setoran $surahName Ayat $start-$end (Total $total ayat lancar).'
                : 'Anda belum menentukan batas akhir setoran (bendera).\n\nSecara default, setoran akan disimpan dari Ayat $start-$end (Total $total ayat lancar).\n\nApakah ini sudah sesuai?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(provider.isFlagChanged ? 'Batal' : 'Ubah Batas'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AssessmentScreen()),
              );
            },
            child: Text(provider.isFlagChanged ? 'Simpan' : 'Ya, Simpan'),
          ),
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
          TextButton(onPressed: () { provider.endSetoranSession(); Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Ya, Batal', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _LiveDashboardWrapper extends StatelessWidget {
  const _LiveDashboardWrapper();

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({int passed, int failed, Santri? santri, int tajwidCount, int makhrojCount})>(
      selector: (context, p) => (
        passed: p.sessionPassedAyahs.length,
        failed: p.sessionFailedAyahs.length,
        santri: p.activeSetoranSantri,
        tajwidCount: p.sessionTajwidCount,
        makhrojCount: p.sessionMakhrojCount,
      ),
      builder: (context, data, child) {
        final provider = context.read<AppProvider>();
        final passed = data.passed;
        final failed = data.failed;
        final santri = data.santri;
        
        // Yearly Target Progress
        final totalMemorized = santri?.totalZiyadahAyahs ?? 0;
        final yearlyTargetDoc = santri != null ? provider.getYearlyTarget(santri.id) : null;
        final yearlyTarget = yearlyTargetDoc?.ayahCount ?? 604;
        final yearlyProgress = (totalMemorized / yearlyTarget).clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4), // Extremely compact padding
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(santri?.name ?? 'Santri', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                          Text('Target Tahunan: ${(yearlyProgress * 100).toStringAsFixed(0)}% Selesai', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    _statusCircle('Lulus', passed, Colors.green),
                    const SizedBox(width: 8),
                    _statusCircle('Gagal', failed, Colors.red),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // Reduced vertical spacing
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12), // Reduced internal padding
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _errorItem('KESALAHAN TAJWID', data.tajwidCount, AppTheme.tajwidColor),
                    Container(width: 1, height: 14, color: Colors.grey.shade300), // Shorter divider
                    _errorItem('KESALAHAN MAKHROJ', data.makhrojCount, AppTheme.makhrojColor),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _statusCircle(String label, int val, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24, height: 24, // Compact size
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Center(child: Text('$val', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))),
        ),
        Text(label, style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _errorItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)), // Smaller digit size
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.3)),
      ],
    );
  }
}

class _ReaderContentWrapper extends StatelessWidget {
  const _ReaderContentWrapper({
    required this.isReadOnly,
    required this.scrollController,
    required this.onWordTap,
  });

  final bool isReadOnly;
  final ScrollController scrollController;
  final void Function(int surahNumber, int ayahNumber, int wordIndex, String word) onWordTap;

  @override
  Widget build(BuildContext context) {
    return Selector<AppProvider, ({SurahDetail? currentSurah, int startAyah, SetoranType type})>(
      selector: (context, p) => (
        currentSurah: p.currentSurah,
        startAyah: p.activeSetoranAyahStart,
        type: p.activeSetoranType,
      ),
      builder: (context, data, child) {
        final surah = data.currentSurah!;
        final ayahs = surah.ayahs.where((a) => a.numberInSurah >= data.startAyah).toList();

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: ayahs.length + (surah.number != 1 && surah.number != 9 && data.startAyah == 1 ? 2 : 1),
          itemBuilder: (context, index) {
            if (surah.number != 1 && surah.number != 9 && data.startAyah == 1 && index == 0) {
              return const BismillahHeader();
            }

            int legendIndex = (surah.number != 1 && surah.number != 9 && data.startAyah == 1) ? 1 : 0;
            if (!isReadOnly && index == legendIndex) {
              return const Padding(padding: EdgeInsets.only(bottom: 20), child: ReaderLegend());
            }

            int actualAyahIndex = index - (legendIndex + 1);
            if (surah.number != 1 && surah.number != 9 && data.startAyah == 1) actualAyahIndex--;

            if (actualAyahIndex < 0 || actualAyahIndex >= ayahs.length) return const SizedBox.shrink();

            final ayah = ayahs[actualAyahIndex];
            
            return Selector<AppProvider, _AyahState>(
              selector: (context, p) {
                final ayahErrors = Map<String, ErrorMark>.fromEntries(
                  p.sessionErrors.entries.where((e) => e.value.surahNumber == surah.number && e.value.ayahNumber == ayah.numberInSurah)
                );
                return _AyahState(
                  errors: ayahErrors,
                  isPassed: p.sessionPassedAyahs.contains(ayah.numberInSurah),
                  isFailed: p.sessionFailedAyahs.contains(ayah.numberInSurah),
                  isEndAyah: p.activeSetoranAyahEnd == ayah.numberInSurah,
                );
              },
              builder: (context, state, child) {
                return RepaintBoundary(
                  child: AyahBlock(
                    key: ValueKey('${surah.number}_${ayah.numberInSurah}'),
                    ayah: ayah,
                    surahNumber: surah.number,
                    sessionErrors: state.errors,
                    isPassed: state.isPassed,
                    isFailed: state.isFailed,
                    isEndAyah: state.isEndAyah,
                    isReadOnly: isReadOnly,
                    onTogglePassed: () => context.read<AppProvider>().toggleAyahPassed(ayah.numberInSurah),
                    onToggleFailed: () => context.read<AppProvider>().toggleAyahFailed(ayah.numberInSurah),
                    onMarkEnd: () => context.read<AppProvider>().setSessionEndAyah(ayah.numberInSurah),
                    onWordTap: (wordIndex, word) => onWordTap(surah.number, ayah.numberInSurah, wordIndex, word),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AyahState {
  final Map<String, ErrorMark> errors;
  final bool isPassed;
  final bool isFailed;
  final bool isEndAyah;

  _AyahState({
    required this.errors,
    required this.isPassed,
    required this.isFailed,
    required this.isEndAyah,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _AyahState) return false;
    if (isPassed != other.isPassed || isFailed != other.isFailed || isEndAyah != other.isEndAyah) return false;
    if (errors.length != other.errors.length) return false;
    for (final key in errors.keys) {
      if (errors[key]?.errorType != other.errors[key]?.errorType) return false;
    }
    return true;
  }

  @override
  int get hashCode => errors.hashCode ^ isPassed.hashCode ^ isFailed.hashCode ^ isEndAyah.hashCode;
}
