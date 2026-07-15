import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

import 'package:core_models/core_models.dart';

class HaditsDetailScreen extends StatelessWidget {
  const HaditsDetailScreen({super.key, required this.hadith, this.hideAppBar = false});

  final Hadith hadith;
  final bool hideAppBar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = hadith.isArbain
        ? 'Arbain Nawawi No. ${hadith.arbainNo}'
        : 'Hadits ${hadith.id}';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: hideAppBar ? null : AppBar(
        title: Text(title),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hideAppBar) ...[
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: isDark ? Colors.white : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE5D5B8)),
              const SizedBox(height: 20),
            ],
            // ── Tema badge ────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              children: [
                if (hadith.isArbain)
                  _badge(
                    'Arba\'in Nawawi #${hadith.arbainNo}',
                    AppTheme.primaryGreen,
                  ),
                _badge(Hadith.temaLabel(hadith.tema), _temaColor(hadith.tema)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Matan Arabic ─────────────────────────────────────────────
            const Text(
              'MATAN ARAB',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF10B981),
                letterSpacing: 1.2,
              ),
            ),
            _buildArabicCard(context, hadith.matanArab),
            const SizedBox(height: 12),

            // ── Terjemah ──────────────────────────────────────────────────
            const Text(
              'TERJEMAH INDONESIA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF10B981),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, 
                  width: 1.2,
                ),
              ),
              child: Text(
                hadith.terjemah,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                ),
              ),
            ),

            // ── Perawi & Sumber ───────────────────────────────────────────
            const Text(
              'INFORMASI HADITS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFF10B981),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, 
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  _infoRow(
                    context,
                    Icons.person_rounded,
                    'Perawi',
                    hadith.perawi,
                    AppTheme.primaryGreen,
                  ),
                  Divider(
                    height: 20, 
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                  _infoRow(
                    context,
                    Icons.import_contacts_rounded,
                    'Sumber Kitab',
                    hadith.sumber,
                    AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicCard(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200, 
          width: 1.2,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 22,
          color: isDark ? AppTheme.accentGreen : AppTheme.darkGreen,
          height: 1.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _temaColor(String? tema) {
  if (tema == null) return Colors.blueGrey;
  switch (tema) {
    case 'niat':
      return const Color(0xFF00897B);
    case 'akidah':
      return const Color(0xFF1565C0);
    case 'ibadah':
      return const Color(0xFF2E5A27);
    case 'akhlak':
      return const Color(0xFF6A1B9A);
    case 'quran':
      return const Color(0xFFE65100);
    case 'ilmu':
      return const Color(0xFF00838F);
    case 'muamalah':
      return const Color(0xFF558B2F);
    case 'keluarga':
      return const Color(0xFFC62828);
    case 'doa':
      return const Color(0xFF4527A0);
    case 'larangan':
      return const Color(0xFFBF360C);
    case 'dunia':
      return const Color(0xFF37474F);
    case 'kesehatan':
      return const Color(0xFF2E7D32);
    default:
      return Colors.blueGrey;
  }
}
