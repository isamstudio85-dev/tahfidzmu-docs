import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/tasmi_form_screen.dart';
import 'package:tahfidz_app/models/halaqah_data.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'dashboard_shared_widgets.dart';

class MusyrifDashboard extends StatelessWidget {
  const MusyrifDashboard({super.key, required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final musyrif = provider.linkedMusyrif;
    final myHalaqah = musyrif != null
        ? provider.halaqahList.where((h) => h.musyrifId == musyrif.id).toList()
        : <HalaqahData>[];
    final mySantri =
        musyrif != null ? provider.getSantriByMusyrif(musyrif.id) : provider.santriList;
    final recent = <(Santri, SetoranRecord)>[];
    for (final s in mySantri) {
      for (final r in s.setoranHistory) {
        recent.add((s, r));
      }
    }
    recent.sort((a, b) => b.$2.date.compareTo(a.$2.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Musyrif')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_m_setoran',
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SetoranFormScreen())),
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Input Hafalan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(height: 20),
            _buildGraduationBanner(context, provider),
            const SizedBox(height: 24),
            const SectionTitle('Statistik Saya'),
            const SizedBox(height: 12),
            Row(children: [
              _mStatTile('${myHalaqah.length}', 'Halaqah', Icons.groups_rounded, AppTheme.gold),
              const SizedBox(width: 12),
              _mStatTile('${mySantri.length}', 'Santri', Icons.people_alt_rounded,
                  AppTheme.primaryGreen),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TasmiFormScreen())),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Mulai Ujian Tasmi\''),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple, side: const BorderSide(color: Colors.purple)),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Aktivitas Terkini'),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const EmptyState('Belum ada riwayat hafalan dari santri Anda.')
            else
              ...recent.take(5).map((item) => RecentSetoranTile(santri: item.$1, record: item.$2)),
            const SizedBox(height: 24),
            HafalanMenuSection(provider: provider),
            const SizedBox(height: 80),
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

  Widget _buildBanner() {
    final m = provider.linkedMusyrif;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.darkGreen, AppTheme.primaryGreen]),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          AppAvatar(
              name: m?.nama ?? 'Musyrif',
              radius: 30,
              imagePath: m?.photoPath,
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m?.nama ?? 'Musyrif',
                style:
                    GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(m?.jabatan ?? 'Pembimbing',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
          Opacity(
              opacity: 0.5,
              child: Image.asset('assets/images/TahfidzMU-logo-white.png', width: 40, height: 40)),
        ],
      ),
    );
  }

  Widget _mStatTile(String value, String label, IconData icon, Color color) {
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
}
