import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tahfidz_app/models/pengawas_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_form_screen.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';

class PengawasDetailScreen extends StatelessWidget {
  const PengawasDetailScreen({super.key, required this.pengawasId});
  final String pengawasId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final list = provider.pengawasList.where((p) => p.id == pengawasId).toList();
        final pengawas = list.isNotEmpty ? list.first : null;
        if (pengawas == null) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            appBar: AppBar(title: const Text('Detail Pengawas')),
            body: const Center(child: Text('Pengawas tidak ditemukan')),
          );
        }

        final isAdmin = provider.isAdmin;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          appBar: AppBar(
            title: Text(
              'DETAIL PENGAWAS',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  tooltip: 'Edit Profil',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PengawasFormScreen(existing: pengawas)),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              // 1. PROFESSIONAL HEADER
              _buildPengawasHeader(pengawas, isDark),
              const SizedBox(height: 24),

              // 2. SYSTEM METRICS / AUTHORITY
              _buildAuthorityHUD(isDark),
              const SizedBox(height: 24),

              // 3. Informasi Akun
              InfoSectionCard(
                title: 'ACCOUNT CREDENTIALS', 
                children: [
                  InfoSectionRow(icon: Icons.person_rounded, label: 'FULL NAME', value: pengawas.nama),
                  InfoSectionRow(icon: Icons.alternate_email_rounded, label: 'SYSTEM USERNAME', value: '@${pengawas.username}'),
                  InfoSectionRow(icon: Icons.work_rounded, label: 'DESIGNATION', value: pengawas.jabatan),
                  InfoSectionRow(icon: Icons.phone_rounded, label: 'WHATSAPP COMMAND', value: pengawas.nomorHp.isNotEmpty ? pengawas.nomorHp : '-'),
                  InfoSectionRow(icon: Icons.verified_user_rounded, label: 'CLEARANCE STATUS', value: pengawas.isAktif ? 'AUTHORIZED' : 'DEACTIVATED',
                      valueColor: pengawas.isAktif ? Colors.green : Colors.red),
                ]
              ),
              const SizedBox(height: 24),

              // 4. Catatan
              if (pengawas.catatan?.isNotEmpty ?? false) ...[
                _sectionTitle('OVERSEER NOTES'),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                  ),
                  child: Text(
                    pengawas.catatan!,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              // DIGITAL PASS
              _qrActionCard(context, pengawas, isDark),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPengawasHeader(PengawasData p, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          AppAvatar(name: p.nama, radius: 36, imagePath: p.photoPath),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama.toUpperCase(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'GREAT OVERSEER',
                  style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorityHUD(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _hudItem(Icons.visibility_rounded, 'TOTAL', 'OVERSIGHT', Colors.blue, isDark),
          _hudItem(Icons.verified_user_rounded, 'HIGH', 'CLEARANCE', Colors.green, isDark),
          _hudItem(Icons.gavel_rounded, 'ADMIN', 'AUTHORITY', Colors.purple, isDark),
        ],
      ),
    );
  }

  Widget _hudItem(IconData icon, String val, String label, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(val, style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _qrActionCard(BuildContext context, PengawasData p, bool isDark) {
    return InkWell(
      onTap: () => _showQrDialog(context, p),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 24),
            SizedBox(width: 12),
            Text('ACCESS PASS QR', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title.toUpperCase(), 
        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.5)
      ),
    );
  }

  void _showQrDialog(BuildContext context, PengawasData p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('OVERSEER ACCESS PASS', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 20),
            QrImageView(data: p.username, size: 200),
            const SizedBox(height: 16),
            Text(p.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(p.jabatan, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
