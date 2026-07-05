import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/models/graduation_event.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.santri, required this.result, required this.event});
  final Santri santri;
  final dynamic result;
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final bool isAdmin = provider.isAdmin;
    final bool isMyResult = provider.isOrangTua && provider.linkedSantriId == santri.id;
    final bool canViewShahadah = (isAdmin || isMyResult) && event.isCertificatesReleased;
    final bool canEditResult = isAdmin || (provider.isMusyrif && result.status == 'tinjau_ulang');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: (result.isPass && canViewShahadah) ? () => showShahadahDialog(context, santri, result, event) : null,
        leading: AppAvatar(name: santri.name, imagePath: santri.photoPath, radius: 18),
        title: Row(
          children: [
            Expanded(child: Text(santri.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            if (canEditResult)
              IconButton(
                icon: Icon(isAdmin ? Icons.edit_note_rounded : Icons.fact_check_rounded, color: Colors.blue, size: 20),
                onPressed: () => _showEditStatusDialog(context, provider),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        subtitle: Text('Lulus Juz ${result.juzNumbers.join(", ")} • Nilai ${result.finalScore.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11)),
        trailing: result.isPass
            ? Icon(Icons.card_membership_rounded,
                color: canViewShahadah
                    ? Colors.blue
                    : (isAdmin || isMyResult ? Colors.orange.withValues(alpha: 0.5) : Colors.grey.shade200),
                size: 20)
            : const Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
      ),
    );
  }

  void _showEditStatusDialog(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Koreksi Hasil Ujian'),
        children: [
          _statusItem(context, p, 'LULUS', 'lulus', Colors.green),
          _statusItem(context, p, 'TINJAU ULANG', 'tinjau_ulang', Colors.orange),
          _statusItem(context, p, 'TIDAK LULUS', 'tidak_lulus', Colors.red),
        ],
      ),
    );
  }

  Widget _statusItem(BuildContext context, AppProvider p, String label, String val, Color color) {
    return SimpleDialogOption(
      onPressed: () {
        p.updateTasmiStatus(santri.id, result.id, val);
        Navigator.pop(context);
      },
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}

void showShahadahDialog(BuildContext context, Santri s, dynamic t, GraduationEvent e) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDE7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.gold, width: 8),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/TahfidzMU-logo-white.png',
                  width: 60,
                  height: 60,
                  color: AppTheme.primaryGreen,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryGreen, size: 60)),
              const SizedBox(height: 16),
              Text('SHAHADAH TAHFIDZ',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.darkGreen, letterSpacing: 1.5)),
              const Text('سند التحفيظ', style: TextStyle(fontSize: 18, color: AppTheme.primaryGreen)),
              const Divider(color: AppTheme.gold, thickness: 2, height: 40),
              const Text('Diberikan kepada:', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              const SizedBox(height: 12),
              Text(s.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
              const SizedBox(height: 12),
              const Text('Telah menyelesaikan pengujian hafalan', textAlign: TextAlign.center),
              Text('JUZ ${t.juzNumbers.join(", ")}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryGreen)),
              const Text('dengan predikat:', textAlign: TextAlign.center),
              Text(ScoringUtils.scoreToGrade(t.finalScore).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _signPlace('Kepala Tahfidz', 'Ust. Ahmad Fauzi'),
                  _signPlace('Tanggal', DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
              const SizedBox(height: 32),
              Text(e.title,
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton.icon(
                  onPressed: () {}, icon: const Icon(Icons.download_rounded), label: const Text('UNDUH SERTIFIKAT')),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _signPlace(String label, String name) {
  return Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      const SizedBox(height: 32),
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      Container(height: 1, width: 100, color: Colors.grey.shade300),
    ],
  );
}
