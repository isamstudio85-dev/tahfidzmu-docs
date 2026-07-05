import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';
import 'package:tahfidz_app/models/error_mark.dart';
import 'package:tahfidz_app/models/surah_model.dart';

class BismillahHeader extends StatelessWidget {
  const BismillahHeader({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class ReaderLegend extends StatelessWidget {
  const ReaderLegend({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class AyahBlock extends StatelessWidget {
  const AyahBlock({
    super.key,
    required this.ayah,
    required this.surahNumber,
    required this.sessionErrors,
    required this.onWordTap,
    this.isPassed = false,
    this.isFailed = false,
    this.onTogglePassed,
    this.onToggleFailed,
    this.isReadOnly = false,
  });

  final AyahModel ayah;
  final int surahNumber;
  final Map<String, ErrorMark> sessionErrors;
  final void Function(int wordIndex, String word) onWordTap;
  final bool isPassed;
  final bool isFailed;
  final VoidCallback? onTogglePassed;
  final VoidCallback? onToggleFailed;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final words = ayah.words;
    final Color borderColor = isPassed 
        ? Colors.green 
        : (isFailed ? Colors.red : Colors.grey.shade100);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isPassed || isFailed ? 2 : 1),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.green.withValues(alpha: 0.1) : (isFailed ? Colors.red.withValues(alpha: 0.1) : AppTheme.primaryGreen.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ayat ${ayah.numberInSurah}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPassed ? Colors.green : (isFailed ? Colors.red : AppTheme.primaryGreen),
                  ),
                ),
              ),
              const Spacer(),
              if (!isReadOnly) ...[
                _actionBtn(Icons.check_circle_rounded, isPassed ? Colors.green : Colors.grey.shade300, onTogglePassed!),
                const SizedBox(width: 8),
                _actionBtn(Icons.cancel_rounded, isFailed ? Colors.red : Colors.grey.shade300, onToggleFailed!),
              ],
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 28),
    );
  }
}
