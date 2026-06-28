import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'halaqah_list_screen.dart';
import 'kelas_list_screen.dart';
import 'musyrif_list_screen.dart';
import 'santri_list_screen.dart';
import 'laporan_screen.dart';
import 'pesantren_screen.dart';

class ManajemenScreen extends StatelessWidget {
  const ManajemenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final allSetorans = provider.santriList
              .expand((s) => s.setoranHistory)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Overview stats ─────────────────────────────────────────
                _sectionTitle('Ringkasan Sistem'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.people_alt_rounded,
                      label: 'Total Santri',
                      value: '${provider.santriList.length}',
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.assignment_turned_in_rounded,
                      label: 'Total Setoran',
                      value: '${allSetorans.length}',
                      color: AppTheme.gold,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Musyrif',
                      value: '${provider.musyrifList.length}',
                      color: const Color(0xFF1565C0),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Management actions ─────────────────────────────────────
                _sectionTitle('Kelola Data'),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.people_alt_rounded,
                  title: 'Kelola Santri',
                  subtitle: '${provider.santriList.length} santri terdaftar',
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SantriListScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Kelola Musyrif',
                  subtitle: '${provider.musyrifList.length} musyrif terdaftar',
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MusyrifListScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.tune_rounded,
                  title: 'Kelola Modul Tahfidz',
                  subtitle: 'Atur modul hafalan aktif',
                  color: const Color(0xFF009688),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PesantrenScreen(manageModulesOnly: true),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.class_rounded,
                  title: 'Kelola Halaqah',
                  subtitle: '${provider.halaqahList.length} halaqah terdaftar',
                  color: const Color(0xFFF57F17),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HalaqahListScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.class_outlined,
                  title: 'Kelola Kelas',
                  subtitle: '${provider.kelasList.length} kelas terdaftar',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const KelasListScreen()),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Laporan ────────────────────────────────────────────────
                _sectionTitle('Laporan'),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.bar_chart_rounded,
                  title: 'Laporan Global',
                  subtitle: 'Statistik & peringkat seluruh santri',
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LaporanScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.picture_as_pdf_rounded,
                  title: 'Export Laporan PDF',
                  subtitle: 'Cetak rekap setoran per periode',
                  color: Colors.red.shade700,
                  badge: 'Segera',
                  onTap: () => _showComingSoon(context, 'Export PDF'),
                ),
                const SizedBox(height: 24),

                // ── System ─────────────────────────────────────────────────
                _sectionTitle('Sistem'),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.backup_rounded,
                  title: 'Backup & Restore',
                  subtitle: 'Export & import data JSON',
                  color: const Color(0xFF00838F),
                  badge: 'Segera',
                  onTap: () => _showComingSoon(context, 'Backup & Restore'),
                ),
                const SizedBox(height: 10),
                _ManageTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Reset Semua Data',
                  subtitle: 'Hapus seluruh data santri & setoran',
                  color: Colors.red,
                  onTap: () => _showResetConfirm(context, provider),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 13,
      color: Colors.grey.shade600,
      letterSpacing: 0.3,
    ),
  );

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera tersedia'),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showResetConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Semua Data?'),
        content: const Text(
          'Seluruh data santri dan riwayat setoran akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.resetAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
