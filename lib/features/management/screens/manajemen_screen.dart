import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/halaqah_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/kelas_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/pesantren_screen.dart';
import 'package:tahfidz_app/features/management/screens/graduation_event_list_screen.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class ManajemenScreen extends StatelessWidget {
  const ManajemenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kelola Sistem'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _header('INFORMASI LEMBAGA'),
              _tile(
                icon: Icons.business_rounded,
                title: 'Profil Pesantren',
                subtitle: 'Nama, alamat, dan logo lembaga',
                color: AppTheme.primaryGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PesantrenScreen()),
                ),
              ),

              _header('PENGATURAN TAHFIDZ'),
              _tile(
                icon: Icons.groups_rounded,
                title: 'Kelola Halaqah',
                subtitle: 'Atur kelompok dan pembimbing',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HalaqahListScreen()),
                ),
              ),
              _tile(
                icon: Icons.meeting_room_rounded,
                title: 'Kelola Kelas',
                subtitle: 'Daftar kelas santri (cth: 7A, 8B)',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KelasListScreen()),
                ),
              ),
              _tile(
                icon: Icons.school_rounded,
                title: 'Manajemen Wisuda',
                subtitle: 'Atur agenda Haflah & Ujian',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GraduationEventListScreen()),
                ),
              ),
              _tile(
                icon: Icons.tune_rounded,
                title: 'Modul Hafalan',
                subtitle: 'Aktifkan modul Quran/Hadits',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PesantrenScreen(manageModulesOnly: true)),
                ),
              ),

              _header('FITUR LANJUTAN'),
              _tile(
                icon: Icons.delete_forever_rounded,
                title: 'Reset Data',
                subtitle: 'Hapus seluruh data pesantren',
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

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 72, endIndent: 16, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Seluruh Data?'),
        content: const Text(
          'Tindakan ini akan menghapus permanen seluruh Santri, Musyrif, Halaqah, dan Riwayat Setoran di pesantren ini.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoadingDialog(context);
              await provider.resetAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil dikosongkan.')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }
}
