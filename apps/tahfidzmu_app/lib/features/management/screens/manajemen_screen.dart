import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/halaqah_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/kelas_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/pesantren_screen.dart';
import 'package:tahfidz_app/features/management/screens/graduation_event_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/diagnostic_screen.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class ManajemenScreen extends StatelessWidget {
  const ManajemenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().themeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kelola Sistem'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final isKoordinator = provider.linkedMusyrif?.isKoordinator ?? false;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if (!isKoordinator) ...[
                _header('INFORMASI LEMBAGA', isDark),
                _tile(
                  context,
                  icon: Icons.business_rounded,
                  title: 'Profil Pesantren',
                  subtitle: 'Nama, alamat, dan logo lembaga',
                  color: AppTheme.primaryGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PesantrenScreen()),
                  ),
                ),
              ],

              _header('PENGATURAN TAHFIDZ', isDark),
              _tile(
                context,
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
                context,
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
                context,
                icon: Icons.school_rounded,
                title: 'Manajemen Wisuda',
                subtitle: 'Atur agenda Haflah & Ujian',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GraduationEventListScreen()),
                ),
              ),
              if (!isKoordinator) ...[
                _tile(
                  context,
                  icon: Icons.tune_rounded,
                  title: 'Modul Hafalan',
                  subtitle: 'Aktifkan modul Quran/Hadits',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PesantrenScreen(manageModulesOnly: true)),
                  ),
                ),
                
                _header('PENGATURAN APLIKASI', isDark),
                _buildSecurityToggle(context, provider),

                _header('FITUR LANJUTAN', isDark),
                _tile(
                  context,
                  icon: Icons.cleaning_services_rounded,
                  title: 'Bersihkan Data Residual',
                  subtitle: 'Hapus sisa field percobaan (subjectId)',
                  color: Colors.blueGrey,
                  onTap: () => _showSanitizeConfirmation(context, provider),
                ),
                _tile(
                  context,
                  icon: Icons.bug_report_outlined,
                  title: 'Diagnostik Sistem',
                  subtitle: 'Cek koneksi database & path',
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
                  ),
                ),
                _tile(
                  context,
                  icon: Icons.delete_forever_rounded,
                  title: 'Reset Data',
                  subtitle: 'Hapus seluruh data pesantren',
                  color: Colors.red,
                  onTap: () => _showResetConfirmation(context, provider),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _header(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = context.read<AppProvider>().themeMode == ThemeMode.dark;
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, indent: 72, endIndent: 16, color: isDark ? Colors.white10 : const Color(0xFFEEEEEE)),
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

  void _showSanitizeConfirmation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sinkronisasi Metadata?'),
        content: const Text(
          'Aplikasi akan memperbaiki metadata riwayat setoran dan menghapus sisa data percobaan sebelumnya di database. Ini penting untuk kestabilan laporan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoadingDialog(context);
              await provider.sanitizeFirestoreData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Metadata berhasil disinkronkan.')),
                );
              }
            },
            child: const Text('Sinkronkan'),
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

  Widget _buildSecurityToggle(BuildContext context, AppProvider provider) {
    final bool isEnabled = provider.pesantrenInfo.qrSecurityEnabled;
    final isDark = provider.themeMode == ThemeMode.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isEnabled ? (isDark ? Colors.green.withValues(alpha: 0.3) : Colors.green.shade100) : (isDark ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.shade100), width: 1.5),
        ),
        child: SwitchListTile(
          value: isEnabled,
          title: Text(
            'Wajib Scan QR Code',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, 
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            isEnabled 
              ? 'Keamanan aktif: Setoran & Koreksi wajib scan kartu.' 
              : 'Mode Uji Coba: Scan QR dinonaktifkan (bebas masuk).',
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black54),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isEnabled ? AppTheme.primaryGreen : Colors.orange).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEnabled ? Icons.qr_code_scanner_rounded : Icons.qr_code_2_rounded,
              color: isEnabled ? AppTheme.primaryGreen : Colors.orange,
              size: 20,
            ),
          ),
          onChanged: (val) async {
            final updated = provider.pesantrenInfo.copyWith(qrSecurityEnabled: val);
            await provider.updatePesantrenInfo(updated);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Keamanan QR diaktifkan.' : 'Mode Bebas Scan diaktifkan (Uji Coba).'),
                  backgroundColor: val ? Colors.green : Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
