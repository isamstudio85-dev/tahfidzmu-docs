import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dashboard_shared_widgets.dart';

class OrangTuaDashboard extends StatelessWidget {
  const OrangTuaDashboard({super.key, required this.child});
  final Santri child;

  @override
  Widget build(BuildContext context) {
    final setorans = child.setoranHistory.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final avg = child.averageScore;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'BERANDA SANTRI',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
  
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBanner(context),
                const SizedBox(height: 20),
              if (context.watch<AppProvider>().isModuleActive('graduation') &&
                  context.watch<AppProvider>().graduationEvents.any(
                    (e) => e.isPublished,
                  )) ...[
                _buildGraduationBanner(context, context.read<AppProvider>()),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  _oStat(
                    Icons.menu_book_rounded,
                    'Hafalan',
                    '${child.estimatedJuz.toStringAsFixed(1)} Juz',
                    Colors.purple,
                  ),
                  const SizedBox(width: 12),
                  _oStat(
                    Icons.qr_code_2_rounded,
                    'Kartu QR',
                    'Buka',
                    AppTheme.primaryGreen,
                    onTap: () => _showDigitalCardDialog(context),
                  ),
                  const SizedBox(width: 12),
                  _oStat(
                    Icons.star_rounded,
                    'Rata-rata',
                    avg > 0 ? avg.toStringAsFixed(0) : '-',
                    AppTheme.gold,
                  ),
                  if (isTablet) ...[
                    const SizedBox(width: 12),
                    _oStat(
                      Icons.history_edu_rounded,
                      'Total Ayat',
                      '${child.totalZiyadahAyahs}',
                      Colors.blue,
                    ),
                  ],
                ],
              ),
              if (context.watch<AppProvider>().isModuleActive('gamification')) ...[
                Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
                const SizedBox(height: 16),
                GamificationCard(santri: child),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
                const SizedBox(height: 16),
                const PusatHafalanPortalCard(),
                const SizedBox(height: 32),
              ],

              if (isTablet)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildTodayPresenceCard(
                            context,
                            context.watch<AppProvider>().getTodaySantriStatus(
                              child.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('Riwayat Terbaru'),
                          const SizedBox(height: 12),
                          if (setorans.isEmpty)
                            const EmptyState('Belum ada riwayat setoran.')
                          else
                            ...setorans
                                .take(5)
                                .map(
                                  (r) => RecentSetoranTile(
                                    santri: child,
                                    record: r,
                                  ),
                                ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SantriDetailScreen(santriId: child.id),
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                              icon: const Icon(Icons.person_search_rounded),
                              label: const Text('LIHAT DETAIL LENGKAP'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayPresenceCard(
                      context,
                      context.watch<AppProvider>().getTodaySantriStatus(
                        child.id,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('Riwayat Terbaru'),
                    const SizedBox(height: 12),
                    if (setorans.isEmpty)
                      const EmptyState('Belum ada riwayat setoran.')
                    else
                      ...setorans
                          .take(5)
                          .map(
                            (r) => RecentSetoranTile(santri: child, record: r),
                          ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SantriDetailScreen(santriId: child.id),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                        icon: const Icon(Icons.person_search_rounded),
                        label: const Text('LIHAT DETAIL LENGKAP'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    ),
    );
  }



  void _showDigitalCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KARTU SANTRI DIGITAL',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: context.read<AppProvider>().getLoginQrData(child.id),
                builder: (context, snapshot) {
                  return QrImageView(
                    data: snapshot.data ?? (child.nis ?? child.id),
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300, height: 1),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: child.photoPath != null
                          ? Image.network(child.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                child.name[0],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIS/ID: ${child.nis ?? child.id}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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

  Widget _buildBanner(BuildContext context) {
    final activeTheme = child.activeTheme;
    String? bannerImagePath;
    if (activeTheme == 'theme_ramadan') {
      bannerImagePath = 'assets/images/banner_store_ramadan.jpg';
    } else if (activeTheme == 'theme_desert') {
      bannerImagePath = 'assets/images/banner_store_desert.jpg';
    } else if (activeTheme == 'theme_sakinah') {
      bannerImagePath = 'assets/images/banner_store_sakinah.jpg';
    }

    final hasFrame = child.activeFrame != null;
    final Color glowColor = child.activeFrame == 'frame_gold' 
        ? AppTheme.gold 
        : (child.activeFrame == 'frame_emerald' 
            ? const Color(0xFF50C878) 
            : (child.activeFrame == 'frame_neon' 
                ? Colors.cyan 
                : (child.activeFrame == 'frame_pink' 
                    ? const Color(0xFFFFB6C1) 
                    : (child.activeFrame == 'frame_orchid' 
                        ? const Color(0xFFBA55D3) 
                        : Colors.transparent))));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: bannerImagePath == null
            ? const LinearGradient(
                colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: bannerImagePath != null
            ? DecorationImage(
                image: AssetImage(bannerImagePath),
                fit: BoxFit.cover,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(hasFrame ? 3.0 : 0.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: hasFrame ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : null,
              border: hasFrame ? Border.all(color: glowColor, width: 2) : null,
            ),
            child: AppAvatar(
              name: child.name,
              radius: 32,
              imagePath: child.photoPath,
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              activeFrame: child.activeFrame,
              streakDays: child.streakDays,
              jenisKelamin: child.jenisKelamin,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (child.targetHafalan != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target: ${child.targetHafalan}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${((child.estimatedJuz / (double.tryParse(child.targetHafalan?.replaceAll(RegExp(r'[^\d.]'), '') ?? '30') ?? 30)) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          (child.estimatedJuz /
                                  (double.tryParse(
                                        child.targetHafalan?.replaceAll(
                                              RegExp(r'[^\d.]'),
                                              '',
                                            ) ??
                                            '30',
                                      ) ??
                                      30))
                              .clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _oStat(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      Widget content = Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.2 : 0.1)),
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
                  fontSize: 16,
                  color: isDark ? Colors.white : color,
                ),
              ),
            ),
            const SizedBox(height: 2),
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
      );

      if (onTap != null) {
        content = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: content,
          ),
        );
      }

      return Expanded(child: content);
    });
  }

  Widget _buildTodayPresenceCard(BuildContext context, String? status) {
    Color color;
    String title;
    String subtitle;
    IconData icon;

    if (status == null) {
      color = Colors.grey;
      title = 'Belum Ada Sesi / Belum Absen';
      subtitle = 'Musyrif belum memulai sesi atau belum mengisi kehadiran.';
      icon = Icons.hourglass_empty_rounded;
    } else {
      switch (status) {
        case 'setoran':
          color = Colors.green;
          title = 'Hadir & Setoran';
          subtitle =
              'Alhamdulillah, anak Anda hadir dan telah menyetorkan hafalannya hari ini.';
          icon = Icons.check_circle_rounded;
          break;
        case 'ditunda':
          color = Colors.grey.shade600;
          title = 'Ditunda (Bukan Sesi)';
          subtitle =
              'Halaqah aktif, namun anak Anda belum kebagian giliran setoran hari ini.';
          icon = Icons.schedule_rounded;
          break;
        case 'sakit':
          color = Colors.orange;
          title = 'Sakit';
          subtitle =
              'Anak Anda dilaporkan sakit hari ini. Semoga lekas sembuh.';
          icon = Icons.local_hospital_rounded;
          break;
        case 'izin':
          color = Colors.blue;
          title = 'Izin';
          subtitle = 'Anak Anda izin tidak menghadiri halaqah hari ini.';
          icon = Icons.assignment_ind_rounded;
          break;
        case 'alfa':
          color = Colors.red;
          title = 'Alfa (Tanpa Keterangan)';
          subtitle =
              'Anak Anda tidak menghadiri halaqah tanpa keterangan hari ini.';
          icon = Icons.cancel_rounded;
          break;
        default:
          color = Colors.grey;
          title = 'Belum Ada Sesi / Belum Absen';
          subtitle = 'Musyrif belum memulai sesi atau belum mengisi kehadiran.';
          icon = Icons.hourglass_empty_rounded;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : color.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KEHADIRAN HALAQAH HARI INI',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
