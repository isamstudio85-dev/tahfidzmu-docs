import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/verification_gate.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/tasmi_form_screen.dart';
import 'package:tahfidz_app/models/halaqah_data.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tahfidz_app/features/dashboard/widgets/notification_bell.dart';
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
    final mySantri = musyrif != null
        ? provider.getSantriByMusyrif(musyrif.id)
        : provider.santriList;
    final recent = <(Santri, SetoranRecord)>[];
    for (final s in mySantri) {
      for (final r in s.setoranHistory) {
        recent.add((s, r));
      }
    }
    recent.sort((a, b) => b.$2.date.compareTo(a.$2.date));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 14.0, top: 10.0, bottom: 10.0),
          child: Image.asset(
            'assets/images/TahfidzMU-logo-white.png',
            fit: BoxFit.contain,
          ),
        ),
        titleSpacing: 8.0,
        title: const Text('Dashboard'),
        actions: [
          NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 20),
                      if (provider.isModuleActive('graduation') &&
                          provider.graduationEvents.any((e) => e.isPublished)) ...[
                        _buildGraduationBanner(context, provider),
                        const SizedBox(height: 24),
                      ],
                      const SectionTitle('Statistik Saya'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _mStatTile(
                            '${myHalaqah.length}',
                            'Halaqah',
                            Icons.groups_rounded,
                            AppTheme.gold,
                          ),
                          const SizedBox(width: 12),
                          _mStatTile(
                            '${mySantri.length}',
                            'Santri',
                            Icons.people_alt_rounded,
                            AppTheme.primaryGreen,
                          ),
                          if (isTablet) ...[
                            const SizedBox(width: 12),
                            _mStatTile(
                              '${recent.length}',
                              'Total Setoran',
                              Icons.history_edu_rounded,
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _mStatTile(
                              '${mySantri.fold(0, (sum, s) => sum + s.totalZiyadahAyahs)}',
                              'Total Ayat',
                              Icons.menu_book_rounded,
                              Colors.purple,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      HafalanMenuSection(provider: provider),
                      const SizedBox(height: 24),
                      
                      if (isTablet)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  // KARTU MUSYRIF DIGITAL
                                  _buildDigitalCard(context),
                                  const SizedBox(height: 16),
                                  _buildScanButton(context),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionTitle('Aktivitas Terkini'),
                                  const SizedBox(height: 12),
                                  if (recent.isEmpty)
                                    const EmptyState('Belum ada riwayat hafalan.')
                                  else
                                    ...recent.take(5).map((item) => RecentSetoranTile(santri: item.$1, record: item.$2)),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDigitalCard(context),
                            const SizedBox(height: 16),
                            _buildScanButton(context),
                            const SizedBox(height: 20),
                            if (provider.isModuleActive('graduation') && provider.graduationEvents.any((e) => e.isPublished)) ...[
                              _buildTasmiButton(context),
                              const SizedBox(height: 24),
                            ],
                            const SectionTitle('Aktivitas Terkini'),
                            const SizedBox(height: 12),
                            if (recent.isEmpty)
                              const EmptyState('Belum ada riwayat hafalan dari santri Anda.')
                            else
                              ...recent.take(5).map((item) => RecentSetoranTile(santri: item.$1, record: item.$2)),
                          ],
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDigitalCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDigitalCardDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Colors.black87, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KARTU MUSYRIF DIGITAL',
                      style: GoogleFonts.poppins(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text('QR Code untuk akses cepat', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.qr_code_rounded, color: Colors.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () async {
          final verifiedSantri = await VerificationGate.show(context: context);
          if (verifiedSantri != null && context.mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SetoranFormScreen(santri: verifiedSantri)));
          }
        },
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
        label: const Text('SCAN QR SANTRI (MULAI SETORAN)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildTasmiButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasmiFormScreen())),
        icon: const Icon(Icons.school_rounded),
        label: const Text('Mulai Ujian Tasmi\''),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.purple, side: const BorderSide(color: Colors.purple)),
      ),
    );
  }

  void _showDigitalCardDialog(BuildContext context) {
    final m = provider.linkedMusyrif;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('KARTU MUSYRIF DIGITAL', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen, letterSpacing: 0.5)),
              const SizedBox(height: 20),
              QrImageView(data: m?.id ?? '', version: QrVersions.auto, size: 180.0, backgroundColor: Colors.white),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60, height: 60,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: m?.photoPath != null ? Image.network(m!.photoPath!, fit: BoxFit.cover) : Center(child: Text(m?.nama[0] ?? 'M', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m?.nama ?? 'Musyrif', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('NIP/ID: ${m?.nip ?? m?.id ?? "-"}', style: TextStyle(fontFamily: 'monospace', color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraduationBanner(BuildContext context, AppProvider provider) {
    final activeEvents = provider.graduationEvents
        .where((e) => e.isPublished)
        .toList();
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
          ),
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GraduationPortalScreen(event: event),
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.purple,
            size: 24,
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: const Text(
          'Lihat informasi wisuda & hasil ujian',
          style: TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'INFO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
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
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AppAvatar(
            name: m?.nama ?? 'Musyrif',
            radius: 30,
            imagePath: m?.photoPath,
            backgroundColor: Colors.white24,
            foregroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m?.nama ?? 'Musyrif',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  m?.jabatan ?? 'Pembimbing',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
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
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
