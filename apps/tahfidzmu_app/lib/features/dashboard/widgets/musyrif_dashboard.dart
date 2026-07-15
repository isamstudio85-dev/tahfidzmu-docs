import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/verification_gate.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/tasmi_form_screen.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tahfidz_app/features/management/screens/redemption_center_screen.dart';
import 'package:tahfidz_app/features/dashboard/widgets/notification_bell.dart';
import 'dashboard_shared_widgets.dart';

class MusyrifDashboard extends StatelessWidget {
  const MusyrifDashboard({super.key, required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final musyrif = provider.linkedMusyrif;
    final myHalaqah = musyrif != null
        ? provider.halaqahList.where((h) => h.musyrifId == musyrif.id || (musyrif.isKoordinator && musyrif.managedHalaqahIds.contains(h.id))).toList()
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Image.asset(
            'assets/images/TahfidzMU-logo-white.png',
            fit: BoxFit.contain,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'BERANDA MUSYRIF',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          const NotificationBell(),
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
                        const SizedBox(height: 20),
                      ],
                      
                      // --- COMPACT STATS HUD ---
                      _buildCompactStats(myHalaqah.length, mySantri.length, recent.length, isDark),
                      const SizedBox(height: 16),

                      // --- ACTION HUD (MY ID & SCAN) ---
                      _buildActionHUD(context, isDark),
                      const SizedBox(height: 24),

                      if (provider.isModuleActive('gamification')) ...[
                        const PusatHafalanPortalCard(),
                        const SizedBox(height: 32),
                      ],

                      // --- HALAQAH STATUS ---
                      if (myHalaqah.isNotEmpty) ...[
                        const SectionTitle('STATUS HALAQAH'),
                        const SizedBox(height: 12),
                        _buildHalaqahStatus(provider, myHalaqah, isDark),
                        const SizedBox(height: 32),
                      ],
                      
                      if (isTablet)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            if (provider.isModuleActive('graduation') && provider.graduationEvents.any((e) => e.isPublished)) ...[
                              _buildTasmiButton(context),
                              const SizedBox(height: 24),
                            ],
                            const SectionTitle('Aktivitas Terkini'),
                            const SizedBox(height: 12),
                            if (recent.isEmpty)
                              const EmptyState('Belum ada riwayat hafalan dari santri Anda.')
                            else
                              ...recent.take(10).map((item) => RecentSetoranTile(santri: item.$1, record: item.$2)),
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

  Widget _buildBanner() {
    final m = provider.linkedMusyrif;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  Widget _buildCompactStats(int halaqahCount, int santriCount, int setoranCount, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.groups_rounded, '$halaqahCount', 'HALAQAH', AppTheme.gold, isDark),
          _statItem(Icons.people_alt_rounded, '$santriCount', 'SANTRI', AppTheme.primaryGreen, isDark),
          _statItem(Icons.history_edu_rounded, '$setoranCount', 'SETORAN', Colors.blueAccent, isDark),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String val, String label, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionHUD(BuildContext context, bool isDark) {
    final pendingVouchers = provider.voucherList.where((v) => v.status == VoucherStatus.pending).length;

    return Row(
      children: [
        // MY IDENTITY BUTTON
        Expanded(
          flex: 2,
          child: _actionTile(
            onTap: () => _showDigitalCardDialog(context),
            icon: Icons.badge_rounded,
            label: 'KARTU SAYA',
            color: isDark ? Colors.white70 : Colors.black87,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        // SCAN HERO BUTTON (PRIMARY)
        Expanded(
          flex: 3,
          child: _actionTile(
            onTap: () async {
              final verifiedSantri = await VerificationGate.show(context: context);
              if (verifiedSantri != null && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SetoranFormScreen(santri: verifiedSantri)));
              }
            },
            icon: Icons.qr_code_scanner_rounded,
            label: 'SCAN QR',
            color: AppTheme.primaryGreen,
            isPrimary: true,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        // REDEMPTION BUTTON
        Expanded(
          flex: 2,
          child: _actionTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RedemptionCenterScreen())),
            icon: Icons.card_giftcard_rounded,
            label: 'PENUKARAN',
            color: Colors.orange,
            isDark: isDark,
            badge: pendingVouchers > 0 ? '$pendingVouchers' : null,
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
    required bool isDark,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isPrimary ? color : (isDark ? AppTheme.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary ? color : (isDark ? Colors.white10 : Colors.grey.shade200),
                width: 1.5,
              ),
              boxShadow: isPrimary ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isPrimary ? Colors.white : (isDark ? Colors.white : color), size: 20),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : (isDark ? Colors.white70 : color),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHalaqahStatus(AppProvider provider, List<HalaqahData> myHalaqah, bool isDark) {
    // Reuse leaderboard logic to find current rank
    final Map<String, int> halaqahXpMap = {};
    for (var s in provider.santriList) {
      if (s.halaqahId == null) continue;
      halaqahXpMap[s.halaqahId!] = (halaqahXpMap[s.halaqahId] ?? 0) + s.totalXP;
    }
    
    final allHalaqahs = provider.halaqahList.map((h) => (id: h.id, xp: halaqahXpMap[h.id] ?? 0)).toList();
    allHalaqahs.sort((a, b) => b.xp.compareTo(a.xp));

    // Show status for the first halaqah managed
    final h = myHalaqah.first;
    final int rank = allHalaqahs.indexWhere((g) => g.id == h.id) + 1;
    final int totalXP = halaqahXpMap[h.id] ?? 0;
    
    // Find MVP in this halaqah
    final mySantriListInHalaqah = provider.santriList.where((s) => s.halaqahId == h.id).toList();
    mySantriListInHalaqah.sort((a, b) => b.totalXP.compareTo(a.totalXP));
    final mvp = mySantriListInHalaqah.isNotEmpty ? mySantriListInHalaqah.first : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Halaqah Icon
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: AppTheme.primaryGreen, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.nama.toUpperCase(), style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1, color: isDark ? Colors.white : Colors.black87)),
                    Text('LEVEL HALAQAH: ${(totalXP / 1000).floor() + 1}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
              // Rank Medal
              Column(
                children: [
                  const Text('RANK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text('#$rank', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryGreen)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _halaqahStat('TOTAL XP', '$totalXP', Colors.blueAccent),
              if (mvp != null)
                _halaqahStat('SANTRI TERBAIK', mvp.name.split(' ')[0].toUpperCase(), AppTheme.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _halaqahStat(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
      ],
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        subtitle: const Text(
          'Lihat informasi wisuda & hasil ujian',
          style: TextStyle(fontSize: 11, color: Colors.black54),
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

  Widget _buildTasmiButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasmiFormScreen())),
        icon: const Icon(Icons.school_rounded),
        label: const Text('MULAI UJIAN TASMI\''),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.purple, side: const BorderSide(color: Colors.purple)),
      ),
    );
  }
}
