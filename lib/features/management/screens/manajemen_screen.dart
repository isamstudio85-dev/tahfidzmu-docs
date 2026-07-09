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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _sectionHeader('INFORMASI LEMBAGA'),
              const SizedBox(height: 8),
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

              const SizedBox(height: 20),
              _sectionHeader('PENGATURAN TAHFIDZ'),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
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

              const SizedBox(height: 20),
              _sectionHeader('FITUR LANJUTAN (KHUSUS DEMO)'),
              const SizedBox(height: 8),
              _buildTile(
                icon: Icons.delete_forever_rounded,
                title: 'Reset Data Pesantren',
                subtitle: 'Hapus seluruh data santri, musyrif, dan riwayat',
                color: Colors.red,
                onTap: () => _showResetConfirmation(context, provider),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Seluruh Data?'),
        content: const Text(
          'Tindakan ini akan menghapus permanen seluruh Santri, Musyrif, Halaqah, dan Riwayat Setoran di pesantren ini.\n\nAkun login yang sudah dibuat di Google (Authentication) tidak akan terhapus, namun tidak akan bisa digunakan lagi karena datanya hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoadingDialog(context);
              await provider.resetAllData();
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil di-reset total.')),
                );
              }
            },
            child: const Text('Ya, Reset Total'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menghapus data...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD68F00),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
