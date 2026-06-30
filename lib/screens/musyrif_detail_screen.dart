import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'musyrif_form_screen.dart';

class MusyrifDetailScreen extends StatelessWidget {
  const MusyrifDetailScreen({super.key, required this.musyrifId});
  final String musyrifId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final musyrif = provider.getMusyrifById(musyrifId);
        if (musyrif == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Musyrif')),
            body: const Center(child: Text('Musyrif tidak ditemukan')),
          );
        }

        final isAdmin = provider.isAdmin;
        final halaqahCount = provider.halaqahList.where((h) => h.musyrifId == musyrif.id).length;
        final santriCount = provider.getSantriByMusyrif(musyrif.id).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Musyrif'),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profil',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MusyrifFormScreen(existing: musyrif)),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Unified Profile Header
                _ProfileHeader(
                  name: musyrif.nama,
                  subtitle: musyrif.jabatan,
                  photoPath: musyrif.photoPath,
                ),
                const SizedBox(height: 20),

                // 2. Unified Stats Row
                Row(
                  children: [
                    _statItem('Halaqah', '$halaqahCount', Icons.groups_rounded, AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    _statItem('Santri', '$santriCount', Icons.people_alt_rounded, const Color(0xFF1565C0)),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Unified Info Section
                _sectionHeader('Informasi Personal'),
                _infoCard([
                  _infoRow(Icons.badge_outlined, 'NIP', musyrif.nip ?? '-'),
                  _infoRow(Icons.male_rounded, 'Jenis Kelamin', musyrif.jenisKelamin == 'P' ? 'Perempuan' : 'Laki-laki'),
                  _infoRow(Icons.phone_outlined, 'No. HP / WA', musyrif.nomorHp.isNotEmpty ? musyrif.nomorHp : '-'),
                  _infoRow(Icons.business_outlined, 'Lembaga', musyrif.lembaga),
                  _infoRow(Icons.info_outline, 'Status', musyrif.isAktif ? 'Aktif' : 'Non-aktif',
                      valueColor: musyrif.isAktif ? AppTheme.primaryGreen : Colors.grey),
                ]),

                if (musyrif.catatan?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  _sectionHeader('Catatan'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text(musyrif.catatan!, style: const TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: valueColor ?? Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.subtitle, this.photoPath});
  final String name;
  final String subtitle;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          AppAvatar(
            name: name,
            radius: 48,
            imagePath: photoPath,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            foregroundColor: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
