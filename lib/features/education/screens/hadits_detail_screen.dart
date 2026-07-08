import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tahfidz_app/models/hadith.dart';

class HaditsDetailScreen extends StatelessWidget {
  const HaditsDetailScreen({super.key, required this.hadith});

  final Hadith hadith;

  @override
  Widget build(BuildContext context) {
    final title = hadith.isArbain
        ? 'Arbain Nawawi No. ${hadith.arbainNo}'
        : 'Hadits ${hadith.id}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F0), // Classic warm parchment (Kitab Kuning background)
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2E5A27), // Deep olive green
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                    const Color(0xFF2E5A27),
                  ),
                _badge(Hadith.temaLabel(hadith.tema), _temaColor(hadith.tema)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Matan Arabic ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EAD4), // Classic yellow highlight backing
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5D5B8), width: 1.5),
              ),
              child: Text(
                hadith.matanArab,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  color: const Color(0xFF1B5E20), // Deep Islamic Green
                  height: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Terjemah ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF9F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE8DF), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TERJEMAH',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: const Color(0xFF2E5A27),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hadith.terjemah,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.7,
                      color: const Color(0xFF4E342E), // Soft Espresso
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Perawi & Sumber ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF9F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEDE8DF), width: 1.2),
              ),
              child: Column(
                children: [
                  _infoRow(
                    Icons.person_rounded,
                    'Perawi',
                    hadith.perawi,
                    const Color(0xFF2E5A27),
                  ),
                  const Divider(height: 16, color: Color(0xFFEDE8DF)),
                  _infoRow(
                    Icons.import_contacts_rounded,
                    'Sumber',
                    hadith.sumber,
                    const Color(0xFF2E5A27),
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
          fontSize: 11,
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
                  color: const Color(0xFF4E342E),
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
