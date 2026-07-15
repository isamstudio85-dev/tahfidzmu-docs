import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/verification_gate.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_reader_screen.dart';
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
        actions: [
          if (context.read<AppProvider>().isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Koreksi Setoran',
              onPressed: () async {
                final verified = await VerificationGate.show(
                  context: context,
                  expectedSantri: santri,
                );
                if (verified != null && context.mounted) {
                  _showEditSetoranDialog(context);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              tooltip: 'Hapus Setoran',
              onPressed: () async {
                final verified = await VerificationGate.show(
                  context: context,
                  expectedSantri: santri,
                );
                if (verified != null && context.mounted) {
                  _showDeleteSetoranConfirm(context);
                }
              },
            ),
          ],
        ],
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
                  // Prepare state for Review ONLY (No Firestore write)
                  provider.prepareReaderForReview(santri: santri, record: record);
                  
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => const QuranReaderScreen(isReadOnly: true)
                    )
                  );
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
                  '${record.ayahRange}${record.totalLines != null ? " (${record.totalLines} baris)" : ""} • ${record.juzLabel} • ${record.type.label}',
            ),
            const SizedBox(height: 20),
            _sectionTitle('Hasil Simak Ayat'),
            const SizedBox(height: 10),
            _AyahStatusCard(passed: record.passedAyahs, failed: record.failedAyahs),
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

  void _showEditSetoranDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final startCtrl = TextEditingController(text: record.ayahStart.toString());
    final endCtrl = TextEditingController(text: record.ayahEnd.toString());
    final scoreCtrl = TextEditingController(text: record.finalScore.toStringAsFixed(0));
    SetoranType selectedType = record.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Koreksi Data Setoran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SetoranType>(
                  initialValue: selectedType,
                  items: SetoranType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSt(() => selectedType = val);
                  },
                  decoration: const InputDecoration(labelText: 'Jenis Setoran'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ayat Mulai'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ayat Selesai'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nilai Kelancaran (0-100)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final start = int.tryParse(startCtrl.text) ?? record.ayahStart;
                final end = int.tryParse(endCtrl.text) ?? record.ayahEnd;
                final score = double.tryParse(scoreCtrl.text) ?? record.finalScore;

                final surah = provider.surahList.firstWhere(
                  (s) => s.number == record.surahNumber,
                  orElse: () => SurahInfo(number: 1, name: 'Al-Fatihah', englishName: 'Al-Fatihah', numberOfAyahs: 7, revelationType: 'Meccan'),
                );
                final maxAyah = surah.numberOfAyahs;

                if (start < 1 || start > maxAyah) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ayat mulai harus antara 1 sampai $maxAyah')),
                  );
                  return;
                }
                if (end < 1 || end > maxAyah) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ayat selesai harus antara 1 sampai $maxAyah')),
                  );
                  return;
                }
                if (start > end) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ayat mulai tidak boleh lebih besar dari ayat selesai')),
                  );
                  return;
                }
                if (score < 0 || score > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nilai kelancaran harus antara 0 sampai 100')),
                  );
                  return;
                }

                final updated = SetoranRecord(
                  id: record.id,
                  santriId: record.santriId,
                  type: selectedType,
                  surahNumber: record.surahNumber,
                  surahName: record.surahName,
                  surahEnglishName: record.surahEnglishName,
                  ayahStart: start,
                  ayahEnd: end,
                  passedAyahs: record.passedAyahs,
                  failedAyahs: record.failedAyahs,
                  errorMarks: record.errorMarks,
                  fluencyRating: record.fluencyRating,
                  date: record.date,
                  finalScore: score,
                );

                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close detail screen so it refreshes parent

                await provider.updateSetoranRecord(santri.id, updated);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data setoran berhasil dikoreksi.')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSetoranConfirm(BuildContext context) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Setoran?'),
        content: const Text(
          'Tindakan ini akan menghapus riwayat setoran ini secara permanen dari database.\n\n'
          'Statistik akumulasi santri akan dihitung ulang secara otomatis.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close detail screen

              await provider.deleteSetoranRecord(santri.id, record.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Riwayat setoran berhasil dihapus.')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
        title: Text(error.tajwidRuleName != null ? '${type.label} (${error.tajwidRuleName}) • Ayat ${error.ayahNumber}' : '${type.label} • Ayat ${error.ayahNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

class _AyahStatusCard extends StatelessWidget {
  const _AyahStatusCard({required this.passed, required this.failed});
  final List<int> passed;
  final List<int> failed;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Ayat Lulus', passed.length.toString(), Colors.green, passed),
            if (failed.isNotEmpty) ...[
              const Divider(height: 24),
              _row('Ayat Gagal', failed.length.toString(), Colors.red, failed),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String count, Color color, List<int> list) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(label.contains('Lulus') ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(list.isEmpty ? 'Tidak ada' : 'Ayat: ${list.join(", ")}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
