import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/models/tasmi_record.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/continuation_dialog.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/santri_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';

class SantriDetailScreen extends StatefulWidget {
  const SantriDetailScreen({super.key, required this.santriId});
  final String santriId;

  @override
  State<SantriDetailScreen> createState() => _SantriDetailScreenState();
}

class _SantriDetailScreenState extends State<SantriDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().listenToActiveSantriHistory(widget.santriId);
      }
    });
  }

  @override
  void dispose() {
    context.read<AppProvider>().stopListeningToActiveSantriHistory(widget.santriId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final santri = provider.getSantriById(widget.santriId);
        if (santri == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Santri')),
            body: const Center(child: Text('Santri tidak ditemukan')),
          );
        }

        final avg = santri.averageScore;
        final stars = santri.overallStarCount;
        final grade = ScoringUtils.scoreToGrade(avg);
        final halaqah = provider.getHalaqahById(santri.halaqahId);
        final isAdmin = provider.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Santri'),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profil',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri)),
                  ),
                ),
            ],
          ),
          floatingActionButton: provider.isMusyrif
              ? FloatingActionButton.extended(
                  heroTag: 'fab_detail_setoran',
                  onPressed: () => showSetoranOptions(context, santri),
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Mulai Setoran'),
                )
              : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Unified Profile Header
                _ProfileHeader(
                  name: santri.name,
                  subtitle: '${santri.kelas ?? 'Tanpa Kelas'} • ${halaqah?.nama ?? 'Tanpa Halaqah'}',
                  photoPath: santri.photoPath,
                  extra: Column(
                    children: [
                      const SizedBox(height: 8),
                      StarRatingWidget(rating: stars, size: 20),
                      const SizedBox(height: 6),
                      GradeBadgeWidget(gradeName: grade, stars: stars),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Unified Stats Row
                Row(
                  children: [
                    _statItem('Rata-rata', avg.toStringAsFixed(0), Icons.bar_chart_rounded, AppTheme.gold),
                    const SizedBox(width: 12),
                    _statItem('Hafalan', '${santri.estimatedJuz.toStringAsFixed(1)} Juz', Icons.menu_book_rounded, Colors.purple),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statItem('Ayat Lulus', '${santri.totalZiyadahAyahs + santri.totalMurojaahAyahs}', Icons.check_circle_outline_rounded, Colors.green),
                    const SizedBox(width: 12),
                    _statItem('Ayat Gagal', '${santri.totalFailedAyahs}', Icons.cancel_outlined, Colors.red),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Unified Info Section
                _sectionHeader('Informasi Personal'),
                _infoCard([
                  _infoRow(Icons.meeting_room_rounded, 'Kelas', santri.kelas ?? '-'),
                  _infoRow(Icons.badge_outlined, 'NIS', santri.nis ?? '-'),
                  _infoRow(Icons.male_rounded, 'Jenis Kelamin', santri.jenisKelamin == 'P' ? 'Perempuan' : 'Laki-laki'),
                  _infoRow(Icons.history_edu_rounded, 'Hafalan Awal', santri.initialMemorizedJuz.isEmpty ? 'Mulai dari Nol' : 'Sudah hafal Juz: ${santri.initialMemorizedJuz.join(', ')}'),
                  _infoRow(Icons.email_outlined, 'Email', santri.email ?? '-'),
                  _infoRow(Icons.family_restroom_outlined, 'Orang Tua', santri.namaOrangTua ?? '-'),
                  _infoRow(Icons.phone_outlined, 'No. HP Wali', santri.nomorHpWali ?? '-'),
                  _infoRow(Icons.flag_outlined, 'Target Hafalan', santri.targetHafalan ?? '-'),
                  _infoRow(Icons.info_outline, 'Status', santri.isAktif ? 'Aktif' : 'Non-aktif',
                      valueColor: santri.isAktif ? AppTheme.primaryGreen : Colors.grey),
                ]),

                const SizedBox(height: 24),
                _sectionHeader('Ujian Tasmi\' / Wisuda'),
                if (santri.tasmiHistory.isEmpty)
                  _emptyHistory('Belum ada riwayat ujian Tasmi\'')
                else
                  ...santri.tasmiHistory.reversed.map(
                    (t) => _TasmiHistoryTile(record: t),
                  ),

                const SizedBox(height: 24),
                _sectionHeader('Riwayat Setoran'),
                if (santri.setoranHistory.isEmpty)
                  _emptyHistory('Belum ada riwayat setoran')
                else
                  ...santri.setoranHistory.reversed.map(
                    (r) => _SetoranHistoryTile(record: r, santri: santri),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: valueColor ?? Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _emptyHistory(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(msg, style: TextStyle(color: Colors.grey.shade400)),
      ),
    );
  }
}

class _TasmiHistoryTile extends StatelessWidget {
  const _TasmiHistoryTile({required this.record});
  final TasmiRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: record.isPass ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            record.isPass ? Icons.verified_rounded : Icons.cancel_rounded,
            color: record.isPass ? Colors.blue : Colors.red,
            size: 20,
          ),
        ),
        title: Text('Ujian Juz ${record.juzNumbers.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Tahun ${record.year} • Skor: ${record.finalScore.toStringAsFixed(0)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: record.isPass ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            record.isPass ? 'LULUS' : 'GAGAL',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.subtitle, this.photoPath, this.extra});
  final String name;
  final String subtitle;
  final String? photoPath;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          AppAvatar(
            name: name,
            radius: 48,
            imagePath: photoPath,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            foregroundColor: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (extra != null) extra!,
        ],
      ),
    );
  }
}

class _SetoranHistoryTile extends StatelessWidget {
  const _SetoranHistoryTile({required this.record, required this.santri});
  final SetoranRecord record;
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SetoranDetailScreen(record: record, santri: santri)),
        ),
        title: Text('${record.surahEnglishName} (${record.surahName})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ayat ${record.ayahStart}-${record.ayahEnd} • ${record.type.label}', style: const TextStyle(fontSize: 11)),
            Row(
              children: [
                Text('Lulus: ${record.passedAyahs.length}', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('Gagal: ${record.failedAyahs.length}', style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(record.finalScore.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen)),
            StarRatingWidget(rating: record.starCount, size: 12),
          ],
        ),
      ),
    );
  }
}
