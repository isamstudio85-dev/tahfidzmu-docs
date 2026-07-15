import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/santri_list_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'dashboard_shared_widgets.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/halaqah_list_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_ranking_list.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/laporan_screen.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/features/dashboard/widgets/notification_bell.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          provider.isPengawas ? 'BERANDA PENGAWAS' : 'BERANDA ADMIN',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          if (!provider.isPengawas)
            _buildQuickVoucherAction(context),
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
          
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(context),
                const SizedBox(height: 20),
                if (provider.isModuleActive('graduation') &&
                    provider.graduationEvents.any((e) => e.isPublished)) ...[
                  _buildGraduationBanner(context, provider),
                  const SizedBox(height: 24),
                ],
                _buildAdminStats(context, isTablet),
                _buildSubscriptionWarning(context),
                const SizedBox(height: 24),

                if (provider.isModuleActive('gamification')) ...[
                  const PusatHafalanPortalCard(),
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
                            const SectionTitle('Aktivitas Halaqah Saat Ini (LIVE)'),
                            const SizedBox(height: 12),
                            _buildLiveMonitor(context),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Status Presensi Hari Ini'),
                            const SizedBox(height: 12),
                            _buildTodayPresensiMonitor(context),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Aktivitas Halaqah Saat Ini (LIVE)'),
                      const SizedBox(height: 12),
                      _buildLiveMonitor(context),
                      const SizedBox(height: 24),
                      const SectionTitle('Status Presensi Halaqah Hari Ini'),
                      const SizedBox(height: 12),
                      _buildTodayPresensiMonitor(context),
                    ],
                  ),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGraduationBanner(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeEvents = provider.graduationEvents
        .where((e) => e.isPublished)
        .toList();
    if (activeEvents.isEmpty) return const SizedBox.shrink();

    final event = activeEvents.first;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
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

  Widget _buildBanner(BuildContext context) {
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
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/TahfidzMU-logo-white.png',
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.auto_stories_rounded,
              size: 40,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TahfidzMU',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  provider.pesantrenName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
        final icon = isExpired
            ? Icons.block_rounded
            : Icons.warning_amber_rounded;
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
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminStats(BuildContext context, bool isTablet) {
    return Row(
      children: [
        _statTile(
          context,
          '${provider.santriList.length}',
          'Santri',
          Icons.people_alt_rounded,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SantriListScreen()),
          ),
        ),
        const SizedBox(width: 12),
        _statTile(
          context,
          '${provider.musyrifList.length}',
          'Musyrif',
          Icons.person_pin_rounded,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MusyrifListScreen()),
          ),
        ),
        const SizedBox(width: 12),
        _statTile(
          context,
          '${provider.halaqahList.length}',
          'Halaqah',
          Icons.groups_rounded,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HalaqahListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMonitor(BuildContext context) {
    final Query query = provider.getCollection('active_sessions');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nights_stay_rounded, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Belum ada aktivitas saat ini',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final musyrifName = data['musyrifName'] ?? 'Musyrif';
            final santriName = data['santriName'] ?? 'Santri';
            final detail = data['detail'] ?? '-';

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade100, width: 1.5),
              ),
              color: isDark ? Colors.green.withValues(alpha: 0.05) : Colors.green.shade50.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  musyrifName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildLiveBadge(),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sedang menyimak: $santriName',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Detail: $detail',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.green.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LiveDot(),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: isDark ? 0.2 : 0.1)),
        ),
        color: color.withValues(alpha: isDark ? 0.1 : 0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
                      color: isDark ? Colors.white : color,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayPresensiMonitor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final halaqahs = provider.halaqahList;
    if (halaqahs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Belum ada data halaqah',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    final now = DateTime.now();

    return Column(
      children: halaqahs.map((h) {
        final musyrif = provider.getMusyrifById(h.musyrifId);

        final list = provider.presensiList
            .where(
              (p) =>
                  p.halaqahId == h.id &&
                  p.tanggal.year == now.year &&
                  p.tanggal.month == now.month &&
                  p.tanggal.day == now.day,
            )
            .toList();
        final presensi = list.isNotEmpty ? list.first : null;

        final isSubmitted = presensi != null;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSubmitted ? Colors.green.withValues(alpha: isDark ? 0.4 : 0.2) : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: 1.5,
            ),
          ),
          color: isSubmitted
              ? Colors.green.withValues(alpha: isDark ? 0.05 : 0.02)
              : (isDark ? AppTheme.darkSurface : Colors.grey.shade50.withValues(alpha: 0.5)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? Colors.green.withValues(alpha: 0.1)
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black87),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSubmitted
                        ? Icons.check_circle_rounded
                        : Icons.groups_rounded,
                    color: isSubmitted
                        ? Colors.green.shade700
                        : (isDark ? Colors.white54 : Colors.white),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.nama,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSubmitted ? (isDark ? Colors.white : Colors.black87) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Musyrif: ${musyrif?.nama ?? 'Tanpa Musyrif'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${presensi.waktuSubmit.hour.toString().padLeft(2, '0')}:${presensi.waktuSubmit.minute.toString().padLeft(2, '0')} WIB',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickVoucherAction(BuildContext context) {
    final pendingCount = provider.voucherList.where((v) => v.status == VoucherStatus.pending).length;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.confirmation_number_rounded, color: AppTheme.gold),
          tooltip: 'Cairkan Tiket Voucher',
          onPressed: () => _quickVoucherRedeem(context),
        ),
        if (pendingCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _quickVoucherRedeem(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen(returnRaw: true)),
    );

    if (result != null) {
      final voucher = provider.voucherList.where((v) => v.id == result).firstOrNull;
      if (voucher != null) {
        if (voucher.status == VoucherStatus.redeemed) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voucher ini sudah dicairkan!'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
            );
          }
        } else {
          if (context.mounted) {
            _showQuickConfirmRedeem(context, voucher);
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voucher tidak ditemukan.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  void _showQuickConfirmRedeem(BuildContext context, VoucherTicket voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cairkan Voucher?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Santri: ${voucher.santriName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Hadiah: ${voucher.rewardName}'),
            const SizedBox(height: 16),
            const Text('Berikan hadiah fisik kepada santri sekarang.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await provider.redeemVoucher(voucher.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voucher berhasil dicairkan! 🎉'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mencairkan: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: const Text('CAIRKAN'),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class RankingScreen extends StatelessWidget {
  const RankingScreen({
    super.key,
    required this.title,
    required this.initialIndex,
  });
  final String title;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text(title)),
      body: QuranRankingList(initialIndex: initialIndex),
    );
  }
}

class AdminLaporanScreen extends StatelessWidget {
  const AdminLaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Laporan Statistik Pesantren')),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final displayList = provider.santriList;
          final setorans = displayList.expand((s) => s.setoranHistory).toList();
          if (setorans.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada data setoran di pesantren ini.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return LaporanScreenBody(setorans: setorans, provider: provider);
        },
      ),
    );
  }
}
