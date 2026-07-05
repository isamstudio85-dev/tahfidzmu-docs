import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/graduation_event.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/graduation_registration.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'widgets/graduation_widgets.dart';
import 'widgets/graduation_cards.dart';
import 'widgets/graduation_results_widgets.dart';

class GraduationPortalScreen extends StatelessWidget {
  const GraduationPortalScreen({super.key, required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isOrangTua = provider.isOrangTua;
    final mySantri = isOrangTua ? provider.linkedSantri : null;

    dynamic myTasmiResult;
    try {
      myTasmiResult = mySantri?.tasmiHistory.firstWhere(
        (t) => t.year == event.year && t.isPass,
      );
    } catch (_) {
      myTasmiResult = null;
    }

    final registration =
        mySantri != null ? provider.getRegistration(event.id, mySantri.id) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.purple,
            elevation: 0,
            flexibleSpace: GraduationHeader(event: event),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (isOrangTua) ...[
                  if (myTasmiResult != null)
                    _buildPersonalCongrats(context, mySantri!, myTasmiResult, event)
                  else
                    _buildPersonalRegistrationStatus(context, provider, mySantri!, registration, event),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnnouncementSection(event),
                      const SizedBox(height: 32),
                      _buildCandidatesSection(context, provider, event),
                      const SizedBox(height: 32),
                      if (provider.isAdmin) ...[
                        const SectionHeader(
                            title: 'PENGELOLAAN PENDAFTARAN', icon: Icons.admin_panel_settings_rounded),
                        const SizedBox(height: 12),
                        RegistrationManagementCard(event: event),
                        const SizedBox(height: 32),
                      ] else if (provider.isMusyrif) ...[
                        const SectionHeader(
                            title: 'DAFTAR PESERTA TAHFIDZ', icon: Icons.assignment_ind_rounded),
                        const SizedBox(height: 12),
                        MusyrifViewCard(event: event),
                        const SizedBox(height: 32),
                      ],
                      _buildResultsSection(context, provider, event),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCongrats(BuildContext context, Santri s, dynamic result, GraduationEvent event) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.gold, Color(0xFFFFD54F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 54),
          const SizedBox(height: 16),
          Text(
            'BARAKALLAHU FIK!',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat ${s.name}, kamu dinyatakan LULUS Ujian Tasmi Juz ${result.juzNumbers.join(", ")} dan berhak mengikuti Wisuda Tahfidz!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (event.isCertificatesReleased)
            FilledButton.icon(
              onPressed: () => showShahadahDialog(context, s, result, event),
              icon: const Icon(Icons.card_membership_rounded),
              label: const Text('LIHAT SERTIFIKAT DIGITAL', style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(30)),
              child: const Text('Sertifikat Sedang Disiapkan Panitia',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalRegistrationStatus(BuildContext context, AppProvider provider, Santri s,
      GraduationRegistration? reg, GraduationEvent event) {
    if (reg == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue.shade100, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_outlined, color: Colors.blue, size: 48),
            const SizedBox(height: 16),
            const Text('Ayo Daftar Wisuda!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Amankan kuota wisuda kamu sekarang juga.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _showRegistrationDialog(context, provider, s, event),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('DAFTAR SEKARANG'),
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor = Colors.orange;
    String statusText = "Menunggu Verifikasi";
    if (reg.status == RegistrationStatus.diterima) {
      statusColor = AppTheme.primaryGreen;
      statusText = "Pendaftaran Diterima";
    } else if (reg.status == RegistrationStatus.ditolak) {
      statusColor = Colors.red;
      statusText = "Pendaftaran Ditolak";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
              backgroundColor: statusColor,
              child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText,
                    style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 15)),
                Text('Terdaftar pada: ${DateFormat('dd MMM yyyy').format(reg.registrationDate)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          if (reg.registrationPaymentStatus == PaymentStatus.belumBayar && event.registrationFee > 0)
            TextButton(
                onPressed: () {},
                child: const Text('BAYAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
        ],
      ),
    );
  }

  Widget _buildAnnouncementSection(GraduationEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'INFORMASI & PENGUMUMAN', icon: Icons.campaign_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.description.isEmpty ? 'Belum ada deskripsi tambahan.' : event.description,
                  style: const TextStyle(fontSize: 14, height: 1.6)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
              InfoRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Waktu Wisuda',
                  value: DateFormat('dd MMMM yyyy').format(event.graduationDate ?? DateTime.now())),
              InfoRow(icon: Icons.assignment_turned_in_rounded, label: 'Metode Ujian', value: event.method),
              InfoRow(
                  icon: Icons.payments_rounded,
                  label: 'Biaya Daftar',
                  value: event.registrationFee > 0
                      ? NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0)
                          .format(event.registrationFee)
                      : 'Gratis'),
              InfoRow(
                  icon: Icons.school_rounded,
                  label: 'Biaya Wisuda',
                  value: event.graduationFee > 0
                      ? NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0)
                          .format(event.graduationFee)
                      : 'Gratis'),
              InfoRow(icon: Icons.rule_rounded, label: 'Syarat Lulus', value: event.requirements),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidatesSection(BuildContext context, AppProvider provider, GraduationEvent event) {
    final candidates = provider.santriList.where((s) {
      return s.tasmiHistory.any((t) => t.year == event.year && t.isPass);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'CALON WISUDAWAN', icon: Icons.people_alt_rounded),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration:
                  BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${candidates.length} Santri',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (candidates.isEmpty)
          const Text('Belum ada santri yang lulus seleksi.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: candidates.length,
              itemBuilder: (ctx, i) {
                final s = candidates[i];
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      AppAvatar(name: s.name, imagePath: s.photoPath, radius: 32),
                      const SizedBox(height: 8),
                      Text(s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResultsSection(BuildContext context, AppProvider provider, GraduationEvent event) {
    final results = <(Santri, dynamic)>[];
    for (var s in provider.santriList) {
      for (var t in s.tasmiHistory) {
        if (t.year == event.year) results.add((s, t));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'HASIL UJIAN TERBARU', icon: Icons.fact_check_rounded),
        const SizedBox(height: 12),
        if (results.isEmpty)
          const Text('Belum ada hasil ujian terekam.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...results.take(5).map((res) => ResultTile(santri: res.$1, result: res.$2, event: event)),
      ],
    );
  }

  void _showRegistrationDialog(BuildContext context, AppProvider provider, Santri s, GraduationEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Daftar Wisuda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Konfirmasi pendaftaran untuk:',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            Text(event.title,
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (event.registrationFee > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments_rounded, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                        'Biaya: ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(event.registrationFee)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final reg = GraduationRegistration(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                eventId: event.id,
                santriId: s.id,
                registrationDate: DateTime.now(),
                registeredBy: 'parent',
              );
              provider.addGraduationRegistration(reg);
              Navigator.pop(ctx);
              _showSuccessPopup(context);
            },
            child: const Text('DAFTARKAN DIRI'),
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 64),
            const SizedBox(height: 16),
            Text('PENDAFTARAN BERHASIL!',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            const Text('Alhamdulillah, data kamu sudah masuk ke sistem. Silahkan tunggu verifikasi dari Admin.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('MENGERTI'))),
          ],
        ),
      ),
    );
  }
}
