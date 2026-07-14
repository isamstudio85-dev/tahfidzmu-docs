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
    this.isEndAyah = false,
    this.onTogglePassed,
    this.onToggleFailed,
    this.onMarkEnd,
    this.isReadOnly = false,
    this.showTajwid = true,
  });

  final AyahModel ayah;
  final int surahNumber;
  final Map<String, ErrorMark> sessionErrors;
  final void Function(int wordIndex, String word) onWordTap;
  final bool isPassed;
  final bool isFailed;
  final bool isEndAyah;
  final VoidCallback? onTogglePassed;
  final VoidCallback? onToggleFailed;
  final VoidCallback? onMarkEnd;
  final bool isReadOnly;
  final bool showTajwid;

  @override
  Widget build(BuildContext context) {
    final words = ayah.words;
    
    // Bottom border color reflects the ayah's assessment status
    final Color lineBorderColor = isEndAyah
        ? Colors.orange.shade400
        : (isPassed 
            ? Colors.green.shade400
            : (isFailed 
                ? Colors.red.shade400
                : const Color(0xFFE5D5B8))); // Neutral gold divider

    final Color lineBgColor = isEndAyah
        ? Colors.orange.shade50.withValues(alpha: 0.3)
        : (isPassed
            ? Colors.green.shade50.withValues(alpha: 0.3)
            : (isFailed
                ? Colors.red.shade50.withValues(alpha: 0.3)
                : Colors.transparent));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isReadOnly ? null : onTogglePassed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: lineBgColor,
          border: Border(
            bottom: BorderSide(
              color: lineBorderColor,
              width: isEndAyah || isPassed || isFailed ? 2.0 : 1.2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEndAyah
                            ? Colors.orange.withValues(alpha: 0.15)
                            : (isPassed
                                ? Colors.green.withValues(alpha: 0.15)
                                : (isFailed
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : const Color(0xFF2E5A27).withValues(alpha: 0.1))),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Ayat ${ayah.numberInSurah}${isEndAyah ? ' (Batas)' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isEndAyah
                              ? Colors.orange.shade800
                              : (isPassed ? Colors.green.shade800 : (isFailed ? Colors.red.shade800 : const Color(0xFF2E5A27))),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isReadOnly)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionBtn(
                          isEndAyah ? Icons.flag_rounded : Icons.outlined_flag_rounded,
                          isEndAyah ? Colors.orange : Colors.grey.shade400,
                          onMarkEnd,
                          isActive: isEndAyah,
                        ),
                        const SizedBox(width: 2),
                        _actionBtn(
                          Icons.check_circle_rounded, 
                          isPassed ? Colors.green : Colors.grey.shade400, 
                          onTogglePassed,
                          isActive: isPassed,
                        ),
                        const SizedBox(width: 2),
                        _actionBtn(
                          Icons.cancel_rounded, 
                          isFailed ? Colors.red : Colors.grey.shade400, 
                          onToggleFailed,
                          isActive: isFailed,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Words list row
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 6,
                runSpacing: 8,
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
                      showTajwid: showTajwid,
                      wordTajweed: i < ayah.wordsTajweed.length ? ayah.wordsTajweed[i] : null,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '﴿${toArabicNumeral(ayah.numberInSurah)}﴾',
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        color: const Color(0xFF2E5A27).withValues(alpha: 0.8),
                        height: 2.2,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
            if (!isReadOnly && sessionErrors.length >= 3)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AYAT KRITIS (KESALAHAN >= 3)',
                      style: GoogleFonts.poppins(
                        color: Colors.red.shade700,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback? onTap, {bool isActive = false}) {
    return _EmpukButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6), // Even more compact
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon, 
          color: color, 
          size: 20, // Scaled down icon
        ),
      ),
    );
  }
}

/// A wrapper widget that adds a "cushioned" scale effect on tap
class _EmpukButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  
  const _EmpukButton({required this.child, this.onTap});

  @override
  State<_EmpukButton> createState() => _EmpukButtonState();
}

class _EmpukButtonState extends State<_EmpukButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
