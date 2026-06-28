import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/error_mark.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../theme/app_theme.dart';
import '../widgets/quran_widgets.dart';

class SetoranDetailScreen extends StatelessWidget {
  const SetoranDetailScreen({
    super.key,
    required this.record,
    required this.santri,
  });

  final SetoranRecord record;
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Setoran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded),
            tooltip: 'Mode baca saja',
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(record: record, santri: santri),
            const SizedBox(height: 16),
            _sectionTitle('Target Ayat'),
            const SizedBox(height: 8),
            _InfoCard(
              icon: Icons.menu_book_rounded,
              title: '${record.surahEnglishName} (${record.surahName})',
              subtitle:
                  '${record.ayahRange} • ${record.juzLabel} • ${record.type.label}',
            ),
            const SizedBox(height: 16),
            _sectionTitle('Ringkasan Penilaian'),
            const SizedBox(height: 8),
            _AssessmentTile(record: record),
            const SizedBox(height: 16),
            _sectionTitle('Detail Kesalahan'),
            const SizedBox(height: 8),
            if (record.errorMarks.isEmpty)
              _EmptyState(
                message: 'Tidak ada catatan kesalahan pada setoran ini.',
              )
            else
              ...record.errorMarks.map((error) => _ErrorTile(error: error)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.record, required this.santri});
  final SetoranRecord record;
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        santri.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.type.label} • ${_formatDate(record.date)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.finalScore.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    StarRatingWidget(rating: record.starCount, size: 16),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  Icons.music_note,
                  'Tajwid: ${record.tajwidErrorCount}',
                  AppTheme.tajwidColor,
                ),
                _chip(
                  Icons.record_voice_over,
                  'Makhroj: ${record.makhrojErrorCount}',
                  AppTheme.makhrojColor,
                ),
                _chip(
                  Icons.accessibility_new,
                  'Kelancaran: ${record.fluencyRating}/5',
                  AppTheme.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.record});
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nilai akhir: ${record.finalScore.toStringAsFixed(1)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Predikat: ${record.gradeName}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (record.finalScore / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.error});
  final ErrorMark error;

  @override
  Widget build(BuildContext context) {
    final type = error.errorType;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type.bgColor,
          child: Icon(type.icon, color: type.color, size: 18),
        ),
        title: Text(
          '${type.label} • Ayat ${error.ayahNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Kata: ${error.word} • ${type.description}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}
