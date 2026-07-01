import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/halaqah_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/kelas_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/pesantren_screen.dart';
import 'package:tahfidz_app/features/management/screens/graduation_event_list_screen.dart';

class ManajemenScreen extends StatelessWidget {
  const ManajemenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sistem'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionHeader('PENGATURAN TAHFIDZ'),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.school_rounded,
                title: 'Manajemen Wisuda',
                subtitle: 'Atur agenda Haflah Takharruj & Ujian',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GraduationEventListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.groups_rounded,
                title: 'Kelola Halaqah',
                subtitle: 'Atur kelompok dan pembimbing (musyrif)',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HalaqahListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.meeting_room_rounded,
                title: 'Kelola Kelas',
                subtitle: 'Daftar kelas santri (cth: 7A, 8B, dsb)',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelasListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.tune_rounded,
                title: 'Modul Hafalan',
                subtitle: 'Aktifkan atau matikan modul Quran/Hadits',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PesantrenScreen(manageModulesOnly: true)),
                ),
              ),

              const SizedBox(height: 32),
              _sectionHeader('INFORMASI LEMBAGA'),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.business_rounded,
                title: 'Profil Pesantren',
                subtitle: 'Nama, alamat, dan logo lembaga',
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PesantrenScreen()),
                ),
              ),

              const SizedBox(height: 32),
              _sectionHeader('KEAMANAN & DATA'),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.cloud_upload_rounded,
                title: 'Backup & Restore',
                subtitle: 'Amankan data atau pindah perangkat',
                color: Colors.blue,
                badge: 'Segera',
                onTap: () => _showComingSoon(context, 'Backup & Restore'),
              ),
              const SizedBox(height: 12),
              _buildTile(
                icon: Icons.delete_sweep_rounded,
                title: 'Reset Data',
                subtitle: 'Hapus permanen seluruh data aplikasi',
                color: Colors.red,
                onTap: () => _showResetConfirm(context, provider),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

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
        title: const Text('Reset Data?'),
        content: const Text('Seluruh data santri, musyrif, dan riwayat hafalan akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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
