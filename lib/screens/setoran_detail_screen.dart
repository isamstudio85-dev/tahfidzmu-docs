import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/error_mark.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../theme/app_theme.dart';
import '../widgets/quran_widgets.dart';

import '../providers/app_provider.dart';
import 'quran_reader_screen.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Rincian Hafalan'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryCard(record: record, santri: santri),
            const SizedBox(height: 20),
            
            // Tombol Inti: Lihat di Mushaf
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  final provider = context.read<AppProvider>();
                  // Memulai sesi "Baca Saja" dengan data lama
                  provider.startSetoranSession(
                    santri: santri,
                    type: record.type,
                    surah: provider.surahList.firstWhere((s) => s.number == record.surahNumber),
                    ayahStart: record.ayahStart,
                    ayahEnd: record.ayahEnd,
                  );
                  // Load errors into session so they appear in reader
                  provider.clearErrors();
                  for (var e in record.errorMarks) {
                    provider.toggleError(
                      surahNumber: e.surahNumber,
                      ayahNumber: e.ayahNumber,
                      wordIndex: e.wordIndex,
                      word: e.word,
                      errorType: e.errorType,
                    );
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranReaderScreen(isReadOnly: true)));
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('LIHAT DI AL-QURAN'),
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Lokasi Hafalan'),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.map_rounded,
              title: '${record.surahEnglishName} (${record.surahName})',
              subtitle:
                  '${record.ayahRange} • ${record.juzLabel} • ${record.type.label}',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Analisis Penilaian'),
            const SizedBox(height: 10),
            _AssessmentTile(record: record),
            const SizedBox(height: 24),
            _sectionTitle('Detail Kesalahan'),
            const SizedBox(height: 10),
            if (record.errorMarks.isEmpty)
              _EmptyState(
                message: 'MasyaAllah! Tidak ada catatan kesalahan pada setoran ini.',
              )
            else
              ...record.errorMarks.map((error) => _ErrorTile(error: error)),
            const SizedBox(height: 40),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.finalScore.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    StarRatingWidget(rating: record.starCount, size: 14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.music_note, 'Tajwid: ${record.tajwidErrorCount}', AppTheme.tajwidColor),
                _chip(Icons.record_voice_over, 'Makhroj: ${record.makhrojErrorCount}', AppTheme.makhrojColor),
                _chip(Icons.accessibility_new, 'Lancar: ${record.fluencyRating}/5', AppTheme.primaryGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.record});
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Skor Akhir: ${record.finalScore.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    record.gradeName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (record.finalScore / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade100,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title; final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type.bgColor,
          child: Icon(type.icon, color: type.color, size: 18),
        ),
        title: Text('${type.label} • Ayat ${error.ayahNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('Kata: ${error.word} • ${type.description}', style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
    );
  }
}
