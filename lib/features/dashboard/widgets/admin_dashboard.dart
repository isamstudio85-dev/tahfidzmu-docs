import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/santri_list_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/tasmi_form_screen.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'dashboard_shared_widgets.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          if (provider.firebase.currentUser?.email == 'dasamsamsudin87@gmail.com')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => provider.switchBackToSuperAdmin(),
                icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.green),
                label: const Text('Super Admin', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(context),
            const SizedBox(height: 20),
            if (provider.isModuleActive('graduation')) ...[
              _buildGraduationBanner(context, provider),
              const SizedBox(height: 24),
            ],
            _buildAdminStats(context),
            _buildSubscriptionWarning(context),
            const SizedBox(height: 24),
            const SectionTitle('Aksi Cepat'),
            const SizedBox(height: 12),
            _buildAdminQuickActions(context),
            const SizedBox(height: 24),
            const SectionTitle('Ringkasan Halaqah'),
            const SizedBox(height: 12),
            _buildHalaqahList(context),
            const SizedBox(height: 24),
            HafalanMenuSection(provider: provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGraduationBanner(BuildContext context, AppProvider provider) {
    final activeEvents = provider.graduationEvents.where((e) => e.isPublished).toList();
    if (activeEvents.isEmpty) return const SizedBox.shrink();

    final event = activeEvents.first;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GraduationPortalScreen(event: event)),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.school_rounded, color: Colors.purple, size: 24),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Lihat informasi wisuda & hasil ujian', style: TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
          child: const Text('INFO',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/TahfidzMU-logo-white.png',
              width: 60,
              height: 60,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.auto_stories_rounded, size: 40, color: Colors.white70)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TahfidzMU',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(provider.pesantrenName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionWarning(BuildContext context) {
    final pid = provider.pesantrenId;
    if (pid == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: provider.firestore.collection('pesantren').doc(pid).get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final data = snap.data!.data()!;
        final activeUntilRaw = data['activeUntil'];
        if (activeUntilRaw == null) return const SizedBox.shrink();
        final activeUntil = (activeUntilRaw as Timestamp).toDate();
        final daysLeft = activeUntil.difference(DateTime.now()).inDays;
        if (daysLeft > 7) return const SizedBox.shrink();

        final isExpired = daysLeft < 0;
        final color = isExpired ? Colors.red : Colors.orange;
        final icon = isExpired ? Icons.block_rounded : Icons.warning_amber_rounded;
        final title = isExpired
            ? 'Masa Aktif Habis'
            : 'Langganan Hampir Berakhir';
        final subtitle = isExpired
            ? 'Akses Anda telah berakhir. Hubungi Super Admin untuk perpanjang.'
            : 'Sisa $daysLeft hari. Segera hubungi Super Admin untuk perpanjang.';

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminStats(BuildContext context) {
    return Row(
      children: [
        _statTile('${provider.santriList.length}', 'Santri', Icons.people_alt_rounded, Colors.blue),
        const SizedBox(width: 12),
        _statTile('${provider.musyrifList.length}', 'Musyrif', Icons.person_pin_rounded, Colors.green),
        const SizedBox(width: 12),
        _statTile('${provider.halaqahList.length}', 'Halaqah', Icons.groups_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildHalaqahList(BuildContext context) {
    final halaqahs = provider.halaqahList;
    if (halaqahs.isEmpty) return const EmptyState('Belum ada data halaqah.');
    return Column(
      children: halaqahs.take(5).map((h) {
        final count = provider.getSantriByHalaqah(h.id).length;
        final m = provider.getMusyrifById(h.musyrifId);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: h.photoPath != null
                  ? Image.file(File(h.photoPath!), fit: BoxFit.cover)
                  : const Icon(Icons.groups_rounded, color: AppTheme.primaryGreen),
            ),
            title: Text(h.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(m?.nama ?? 'Tanpa Pembimbing',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration:
                  BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('$count Santri',
                  style: const TextStyle(
                      color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _actionCard(w,
              icon: Icons.people_alt_rounded,
              label: 'Kelola Santri',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SantriListScreen()))),
          if (provider.isModuleActive('graduation'))
            _actionCard(w,
                icon: Icons.school_rounded,
                label: 'Ujian Tasmi\'',
                color: Colors.purple,
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const TasmiFormScreen()))),
        ],
      );
    });
  }

  Widget _statTile(String value, String label, IconData icon, Color color) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: color))),
        Text(label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600))
      ]),
    ));
  }

  Widget _actionCard(double w,
      {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
        width: w,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Column(children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))
              ]),
            )));
  }
}
