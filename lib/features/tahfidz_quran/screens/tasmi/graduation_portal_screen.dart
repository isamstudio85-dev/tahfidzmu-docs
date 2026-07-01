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
import 'package:tahfidz_app/core/utils/scoring_utils.dart';

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

    final registration = mySantri != null ? provider.getRegistration(event.id, mySantri.id) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: CustomScrollView(
        slivers: [
          // 1. Festive Hero Header
          _buildSliverAppBar(context, event),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // 2. Personal Status (For Parent/Santri)
                if (isOrangTua) ...[
                  if (myTasmiResult != null) 
                    _buildPersonalCongrats(context, mySantri!, myTasmiResult, event)
                  else
                    _buildPersonalRegistrationStatus(context, provider, mySantri!, registration, event),
                ],

                // 3. Main Content Sections
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Announcement Card
                      _buildAnnouncementSection(event),
                      const SizedBox(height: 32),

                      // Candidates Section (The "Hall of Fame")
                      _buildCandidatesSection(context, provider, event),
                      const SizedBox(height: 32),

                      // Management for Admin/Musyrif
                      if (provider.isAdmin) ...[
                        _sectionHeader('PENGELOLAAN PENDAFTARAN', Icons.admin_panel_settings_rounded),
                        const SizedBox(height: 12),
                        _RegistrationManagementCard(event: event),
                        const SizedBox(height: 32),
                      ] else if (provider.isMusyrif) ...[
                         _sectionHeader('DAFTAR PESERTA TAHFIDZ', Icons.assignment_ind_rounded),
                         const SizedBox(height: 12),
                         _MusyrifViewCard(event: event),
                         const SizedBox(height: 32),
                      ],

                      // Results Summary
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

  Widget _buildSliverAppBar(BuildContext context, GraduationEvent event) {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.purple,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            event.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.black45, blurRadius: 10)],
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Festive Icons background
            Positioned(
              right: -20, top: 40,
              child: Opacity(opacity: 0.1, child: const Icon(Icons.school_rounded, size: 180, color: Colors.white)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.gold, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text('WISUDA TAHFIDZ', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
                  Text(event.year, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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
        boxShadow: [BoxShadow(color: AppTheme.gold.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 54),
          const SizedBox(height: 16),
          Text(
            'BARAKALLAHU FIK!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, letterSpacing: 2),
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
               style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
             )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(30)),
              child: const Text('Sertifikat Sedang Disiapkan Panitia', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalRegistrationStatus(BuildContext context, AppProvider provider, Santri s, GraduationRegistration? reg, GraduationEvent event) {
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
            const Text('Amankan kuota wisuda kamu sekarang juga.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
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
          CircleAvatar(backgroundColor: statusColor, child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statusText == "Menunggu Verifikasi" 
                  ? Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 15))
                  : Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 15)),
                Text('Terdaftar pada: ${DateFormat('dd MMM yyyy').format(reg.registrationDate)}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          if (reg.registrationPaymentStatus == PaymentStatus.belum_bayar && event.registrationFee > 0)
            TextButton(
              onPressed: () {}, 
              child: const Text('BAYAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))
            ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementSection(GraduationEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('INFORMASI & PENGUMUMAN', Icons.campaign_rounded),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.description.isEmpty ? 'Belum ada deskripsi tambahan.' : event.description, style: const TextStyle(fontSize: 14, height: 1.6)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
              _infoRow(Icons.calendar_month_rounded, 'Waktu Wisuda', _formatDate(event.graduationDate)),
              _infoRow(Icons.assignment_turned_in_rounded, 'Metode Ujian', event.method),
              _infoRow(Icons.payments_rounded, 'Biaya Daftar', event.registrationFee > 0 ? formatCurrency(event.registrationFee) : 'Gratis'),
              _infoRow(Icons.school_rounded, 'Biaya Wisuda', event.graduationFee > 0 ? formatCurrency(event.graduationFee) : 'Gratis'),
              _infoRow(Icons.rule_rounded, 'Syarat Lulus', event.requirements),
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
            _sectionHeader('CALON WISUDAWAN', Icons.people_alt_rounded),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${candidates.length} Santri', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (candidates.isEmpty)
          const Text('Belum ada santri yang lulus seleksi.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
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
                      Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
        _sectionHeader('HASIL UJIAN TERBARU', Icons.fact_check_rounded),
        const SizedBox(height: 12),
        if (results.isEmpty)
          const Text('Belum ada hasil ujian terekam.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
        else
          ...results.take(5).map((res) => _ResultTile(santri: res.$1, result: res.$2, event: event)),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.withValues(alpha: 0.3), size: 18),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          ])),
        ],
      ),
    );
  }

  String _formatDate(DateTime? d) => d == null ? '-' : DateFormat('dd MMMM yyyy').format(d);
  String formatCurrency(double val) => NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(val);

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
            Text('Konfirmasi pendaftaran untuk:', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            Text(event.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    Text('Biaya: ${formatCurrency(event.registrationFee)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
            Text('PENDAFTARAN BERHASIL!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen)),
            const SizedBox(height: 8),
            const Text('Alhamdulillah, data kamu sudah masuk ke sistem. Silahkan tunggu verifikasi dari Admin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('MENGERTI'))),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.santri, required this.result, required this.event});
  final Santri santri; final dynamic result; final GraduationEvent event;

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
        subtitle: Text('Lulus Juz ${result.juzNumbers.join(", ")} • Nilai ${result.finalScore.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11)),
        trailing: result.isPass 
          ? Icon(
              Icons.card_membership_rounded, 
              color: canViewShahadah ? Colors.blue : (isAdmin || isMyResult ? Colors.orange.withValues(alpha: 0.5) : Colors.grey.shade200),
              size: 20
            )
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

class _MusyrifViewCard extends StatelessWidget {
  const _MusyrifViewCard({required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final regs = provider.graduationRegistrations.where((r) => r.eventId == event.id).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _musyrifRow(Icons.how_to_reg_rounded, 'Pendaftar Wisuda', '${regs.length} Santri'),
          const Divider(height: 32),
          _musyrifRow(Icons.fact_check_rounded, 'Lulus Ujian (Calon)', '${provider.santriList.where((s) => s.tasmiHistory.any((t) => t.year == event.year && t.isPass)).length} Santri'),
        ],
      ),
    );
  }

  Widget _musyrifRow(IconData icon, String title, String count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ],
    );
  }
}

class _RegistrationManagementCard extends StatelessWidget {
  const _RegistrationManagementCard({required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final regs = provider.graduationRegistrations.where((r) => r.eventId == event.id).toList();

    if (regs.isEmpty) return Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text('Belum ada pendaftar.', style: TextStyle(color: Colors.grey))));

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: regs.map((r) {
          final s = provider.getSantriById(r.santriId);
          if (s == null) return const SizedBox.shrink();
          return ExpansionTile(
            leading: AppAvatar(name: s.name, imagePath: s.photoPath, radius: 18),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('Status: ${r.status.name.toUpperCase()}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _regActionRow(context, 'Status Peserta', r.status.name.toUpperCase(), () => _changeStatus(context, provider, r)),
                    const SizedBox(height: 12),
                    _regActionRow(context, 'Pembayaran Daftar', r.registrationPaymentStatus.name.replaceAll('_', ' ').toUpperCase(), () => _changePayment(context, provider, r, true)),
                    const SizedBox(height: 12),
                    _regActionRow(context, 'Pembayaran Wisuda', r.graduationPaymentStatus.name.replaceAll('_', ' ').toUpperCase(), () => _changePayment(context, provider, r, false)),
                  ],
                ),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _regActionRow(BuildContext context, String label, String value, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        ),
      ],
    );
  }

  void _changeStatus(BuildContext context, AppProvider p, GraduationRegistration r) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ubah Status'),
        children: RegistrationStatus.values.map((s) => SimpleDialogOption(
          onPressed: () {
            p.updateGraduationRegistration(r.id, r.copyWith(status: s));
            Navigator.pop(ctx);
          },
          child: Text(s.name.toUpperCase()),
        )).toList(),
      ),
    );
  }

  void _changePayment(BuildContext context, AppProvider p, GraduationRegistration r, bool isRegistration) {
     showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Status Pembayaran'),
        children: PaymentStatus.values.map((s) => SimpleDialogOption(
          onPressed: () {
            if (isRegistration) {
              p.updateGraduationRegistration(r.id, r.copyWith(registrationPaymentStatus: s));
            } else {
              p.updateGraduationRegistration(r.id, r.copyWith(graduationPaymentStatus: s));
            }
            Navigator.pop(ctx);
          },
          child: Text(s.name.replaceAll('_', ' ').toUpperCase()),
        )).toList(),
      ),
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
              // Certificate Header
              Image.asset('assets/images/TahfidzMU-logo-white.png', width: 60, height: 60, color: AppTheme.primaryGreen, errorBuilder: (_,__,___) => const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryGreen, size: 60)),
              const SizedBox(height: 16),
              Text('SHAHADAH TAHFIDZ', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 24, color: AppTheme.darkGreen, letterSpacing: 1.5)),
              const Text('سند التحفيظ', style: TextStyle(fontSize: 18, color: AppTheme.primaryGreen)),
              const Divider(color: AppTheme.gold, thickness: 2, height: 40),
              
              const Text('Diberikan kepada:', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              const SizedBox(height: 12),
              Text(s.name.toUpperCase(), textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
              const SizedBox(height: 12),
              
              const Text('Telah menyelesaikan pengujian hafalan', textAlign: TextAlign.center),
              Text('JUZ ${t.juzNumbers.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryGreen)),
              const Text('dengan predikat:', textAlign: TextAlign.center),
              Text(ScoringUtils.scoreToGrade(t.finalScore).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple)),
              
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _signPlace('Kepala Tahfidz', 'Ust. Ahmad Fauzi'),
                  _signPlace('Tanggal', DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
              const SizedBox(height: 32),
              
              Text(e.title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.download_rounded), label: const Text('UNDUH SERTIFIKAT')),
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
