import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hadith.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class HaditsDetailScreen extends StatelessWidget {
  const HaditsDetailScreen({super.key, required this.hadith});

  final Hadith hadith;

  @override
  Widget build(BuildContext context) {
    final title = hadith.isArbain
        ? 'Arbain Nawawi No. ${hadith.arbainNo}'
        : 'Hadits ${hadith.id}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Tema badge ────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              children: [
                if (hadith.isArbain)
                  _badge(
                    'Arbain Nawawi #${hadith.arbainNo}',
                    const Color(0xFF1A237E),
                  ),
                _badge(Hadith.temaLabel(hadith.tema), _temaColor(hadith.tema)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Matan Arabic ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.darkGreen.withValues(alpha: 0.9),
                    AppTheme.primaryGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                hadith.matanArab,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  color: Colors.white,
                  height: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Terjemah ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TERJEMAH',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hadith.terjemah,
                    style: const TextStyle(fontSize: 15, height: 1.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Perawi & Sumber ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(
                    Icons.person_rounded,
                    'Perawi',
                    hadith.perawi,
                    AppTheme.primaryGreen,
                  ),
                  const Divider(height: 16),
                  _infoRow(
                    Icons.import_contacts_rounded,
                    'Sumber',
                    hadith.sumber,
                    const Color(0xFF1A237E),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
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
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
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
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _temaColor(String tema) {
  switch (tema) {
    case 'niat':
      return const Color(0xFF00897B);
    case 'akidah':
      return const Color(0xFF1565C0);
    case 'ibadah':
      return AppTheme.primaryGreen;
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
