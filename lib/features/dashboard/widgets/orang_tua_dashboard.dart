import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dashboard_shared_widgets.dart';

class OrangTuaDashboard extends StatelessWidget {
  const OrangTuaDashboard({super.key, required this.child});
  final Santri child;

  @override
  Widget build(BuildContext context) {
    final setorans = child.setoranHistory.toList()..sort((a, b) => b.date.compareTo(a.date));
    final avg = child.averageScore;
    final grade = ScoringUtils.scoreToGrade(avg);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          const SizedBox(height: 20),
          if (context.watch<AppProvider>().isModuleActive('graduation')) ...[
            _buildGraduationBanner(context, context.read<AppProvider>()),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              _oStat(Icons.list_alt_rounded, 'Total Baris', '${setorans.length}',
                  AppTheme.primaryGreen),
              const SizedBox(width: 12),
              _oStat(Icons.star_rounded, 'Rata-rata', avg > 0 ? avg.toStringAsFixed(0) : '-',
                  AppTheme.gold),
              const SizedBox(width: 12),
              _oStat(Icons.emoji_events_rounded, 'Predikat', grade, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          // KARTU SANTRI DIGITAL
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
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
                          QrImageView(
                            data: child.nis ?? child.id,
                            version: QrVersions.auto,
                            size: 180.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.grey.shade300, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                backgroundImage: child.photoPath != null ? NetworkImage(child.photoPath!) : null,
                                child: child.photoPath == null
                                    ? Text(child.name[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen))
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.name,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
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
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Tutup',
                              style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                            'KARTU SANTRI DIGITAL',
                            style: GoogleFonts.poppins(
                              color: Colors.green.shade800,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'QR Code untuk akses cepat',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.qr_code_rounded, color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Riwayat Terbaru'),
          const SizedBox(height: 12),
          if (setorans.isEmpty)
            const EmptyState('Belum ada riwayat setoran.')
          else
            ...setorans.take(5).map((r) => RecentSetoranTile(santri: child, record: r)),
          const SizedBox(height: 24),
          HafalanMenuSection(provider: context.read<AppProvider>()),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: child.id))),
                  icon: const Icon(Icons.person_search_rounded),
                  label: const Text('Lihat Detail Lengkap'))),
        ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          AppAvatar(
              name: child.name,
              radius: 32,
              imagePath: child.photoPath,
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white),
          const SizedBox(width: 16),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(child.name,
                style:
                    GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            if (child.targetHafalan != null)
              Text('Target: ${child.targetHafalan}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/TahfidzMU-logo-white.png', width: 40, height: 40)),
        ],
      ),
    );
  }

  Widget _oStat(IconData icon, String label, String value, Color color) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color))),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1),
      ]),
    ));
  }
}
