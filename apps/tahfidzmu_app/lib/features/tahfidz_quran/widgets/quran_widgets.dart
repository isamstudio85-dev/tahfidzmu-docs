import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

import 'package:tahfidz_app/core/tajwid/tajwid_types.dart';

/// A single tappable Arabic word in the Quran reader.
/// Single tap  = Tajwid error (or advance state)
/// Double tap  = Makhroj error
class WordWidget extends StatefulWidget {
  const WordWidget({
    super.key,
    required this.word,
    required this.errorMark,
    required this.onTap,
    this.onDoubleTap,
    this.wordTajweed,
    this.showTajwid = false,
  });

  final String word;
  final ErrorMark? errorMark;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final WordTajweed? wordTajweed;
  final bool showTajwid;

  @override
  State<WordWidget> createState() => _WordWidgetState();
}

class _WordWidgetState extends State<WordWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(WordWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Play a quick "bounce" if the error mark changed
    if (widget.errorMark?.errorType != oldWidget.errorMark?.errorType) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorMark != null;
    Color fgColor = hasError ? widget.errorMark!.errorType.color : Colors.black87;
    final Color bgColor = hasError ? widget.errorMark!.errorType.bgColor : Colors.transparent;
    final Color borderColor = hasError ? widget.errorMark!.errorType.color : Colors.transparent;
    FontWeight fontWeight = FontWeight.normal;

    if (!hasError && widget.showTajwid && widget.wordTajweed != null && widget.wordTajweed!.rule != null) {
      final type = parseCpfairRule(widget.wordTajweed!.rule!);
      if (type != null) {
        fgColor = type.color;
        fontWeight = FontWeight.w600;
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            widget.word,
            style: GoogleFonts.amiri(
              fontSize: 26,
              color: fgColor,
              fontWeight: fontWeight,
              height: 2.0,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

/// Shows a bottom sheet to let musyrif choose the error type for a tapped word.
Future<void> showWordErrorSheet({
  required BuildContext context,
  required String word,
  required ErrorMark? currentMark,
  required void Function(ErrorType type) onSelect,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              word,
              style: GoogleFonts.amiri(fontSize: 36, color: Colors.black87),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'Tandai kesalahan pada lafadz ini',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _ErrorTypeButton(
              errorType: ErrorType.tajwid,
              isActive: currentMark?.errorType == ErrorType.tajwid,
              onTap: () {
                Navigator.pop(ctx);
                onSelect(ErrorType.tajwid);
              },
            ),
            const SizedBox(height: 10),
            _ErrorTypeButton(
              errorType: ErrorType.makhroj,
              isActive: currentMark?.errorType == ErrorType.makhroj,
              onTap: () {
                Navigator.pop(ctx);
                onSelect(ErrorType.makhroj);
              },
            ),
            if (currentMark != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onClear();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Hapus Tanda'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _ErrorTypeButton extends StatelessWidget {
  const _ErrorTypeButton({
    required this.errorType,
    required this.isActive,
    required this.onTap,
  });

  final ErrorType errorType;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? errorType.bgColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? errorType.color : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: errorType.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(errorType.icon, color: errorType.color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kesalahan ${errorType.label}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? errorType.color : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                Text(
                  errorType.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const Spacer(),
            if (isActive)
              Icon(Icons.check_circle, color: errorType.color, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Displays 1–5 stars, optionally interactive.
class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 28,
    this.onChanged,
    this.color,
  });

  final int rating;
  final int maxStars;
  final double size;
  final void Function(int)? onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppTheme.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (i) {
        final filled = i < rating;
        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(i + 1) : null,
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: filled ? starColor : Colors.grey.shade300,
            size: size,
          ),
        );
      }),
    );
  }
}

/// Badge chip showing grade name and stars.
class GradeBadgeWidget extends StatelessWidget {
  const GradeBadgeWidget({
    super.key,
    required this.gradeName,
    required this.stars,
    this.large = false,
  });

  final String gradeName;
  final int stars;
  final bool large;

  static Color _badgeColor(int stars) {
    switch (stars) {
      case 5:
        return const Color(0xFF6A1B9A); // purple – mumtaz
      case 4:
        return const Color(0xFF1565C0); // blue – jayyid jiddan
      case 3:
        return const Color(0xFF2E7D32); // green – jayyid
      case 2:
        return const Color(0xFFF57F17); // amber – maqbul
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(stars);
    final iconSize = large ? 18.0 : 14.0;
    final fontSize = large ? 14.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech_rounded, color: color, size: iconSize + 4),
          const SizedBox(width: 4),
          Text(
            gradeName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
