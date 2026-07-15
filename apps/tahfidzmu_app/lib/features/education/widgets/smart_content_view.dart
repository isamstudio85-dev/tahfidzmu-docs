import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class SmartContentView extends StatelessWidget {
  const SmartContentView({
    super.key,
    required this.content,
    this.onLinkTap,
  });

  final String content;
  final Function(String)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lines = content.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return const SizedBox(height: 8);

        // Detect Link Placeholder [LINK:...]
        if (trimmed.startsWith('[LINK:')) {
          return _buildLinkButton(context, trimmed);
        }

        // Detect Arabic lines (Must contain at least one Arabic letter and NO Latin alphabetic characters)
        final hasArabicLetters = RegExp(r'[\u0621-\u064A\u0671-\u06D3]').hasMatch(line);
        final hasLatinLetters = RegExp(r'[a-zA-Z]').hasMatch(line);

        if (hasArabicLetters && !hasLatinLetters) {
          return _buildArabicCard(context, line);
        }

        // Detect Numbering (e.g. 1. Niat)
        final numMatch = RegExp(r'^(\d+)\.\s(.*)').firstMatch(trimmed);
        if (numMatch != null) {
          return _buildListItem(context, numMatch.group(1)!, numMatch.group(2)!, isNumeric: true);
        }

        // Detect Bullet (e.g. - Membasuh)
        final bulletMatch = RegExp(r'^([\-\*])\s(.*)').firstMatch(trimmed);
        if (bulletMatch != null) {
          return _buildListItem(context, '•', bulletMatch.group(2)!, isNumeric: false);
        }

        // Regular line (Paragraph part)
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            line,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              height: 1.6,
              fontWeight: line.contains(':') ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, String leading, String text, {required bool isNumeric}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNumeric)
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                leading,
                style: TextStyle(
                  color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 7, right: 12, left: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.accentGreen : AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicCard(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(
            fontSize: 24,
            color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
            height: 1.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String label = "Buka Panduan";

    if (tag.contains("TAHSIN_FATIHAH")) {
      label = "Belajar Tahsin Surat Al-Fatihah";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: OutlinedButton.icon(
        onPressed: onLinkTap != null ? () => onLinkTap!(tag) : null,
        icon: const Icon(Icons.record_voice_over_rounded, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
          side: BorderSide(color: isDark ? AppTheme.accentGreen : AppTheme.primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
