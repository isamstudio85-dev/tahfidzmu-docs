import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_form_screen.dart';

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
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('Detail Musyrif'),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. GRADIENT PROFILE HEADER
              _buildMusyrifHeader(musyrif),
              const SizedBox(height: 20),

              // 2. QUICK ACTION CARDS (Halaqah, Santri, QR)
              Row(
                children: [
                  _quickCard('Halaqah', '$halaqahCount', Icons.groups_rounded, AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  _quickCard('Santri', '$santriCount', Icons.people_alt_rounded, const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  _quickActionCard('Kartu QR', Icons.qr_code_scanner_rounded, Colors.orange, () => _showQrDialog(context, musyrif)),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Informasi Personal
              _sectionHeader('Informasi Personal'),
              _infoCard([
                _infoRow(Icons.badge_outlined, 'NIP', musyrif.nip ?? '-'),
                _infoRow(Icons.email_outlined, 'Email', musyrif.email ?? '-'),
                _infoRow(Icons.male_rounded, 'Jenis Kelamin', musyrif.jenisKelamin == 'P' ? 'Perempuan' : 'Laki-laki'),
                _infoRow(Icons.phone_outlined, 'No. HP / WA', musyrif.nomorHp.isNotEmpty ? musyrif.nomorHp : '-'),
                _infoRow(Icons.business_outlined, 'Lembaga', musyrif.lembaga),
                _infoRow(Icons.info_outline, 'Status', musyrif.isAktif ? 'Aktif' : 'Non-aktif',
                    valueColor: musyrif.isAktif ? AppTheme.primaryGreen : Colors.grey),
              ]),
              const SizedBox(height: 24),

              // 4. Catatan
              if (musyrif.catatan?.isNotEmpty ?? false) ...[
                _sectionHeader('Catatan'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(musyrif.catatan!, style: const TextStyle(fontSize: 14, height: 1.5)),
                ),
              ],
              const SizedBox(height: 40),
              // QR Button
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMusyrifHeader(MusyrifData m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1565C0),
            Color(0xFF0D47A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
              image: (m.photoPath?.isNotEmpty ?? false)
                  ? DecorationImage(image: NetworkImage(m.photoPath!), fit: BoxFit.cover)
                  : null,
            ),
            child: (m.photoPath?.isEmpty ?? true)
                ? Center(
                    child: Text(
                      m.nama[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            m.nama,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            m.jabatan,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color)),
              const SizedBox(height: 2),
              const Icon(Icons.touch_app_rounded, size: 10, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, MusyrifData musyrif) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KARTU MUSYRIF DIGITAL',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: context.read<AppProvider>().getLoginQrData(musyrif.id),
                builder: (context, snapshot) {
                  return QrImageView(
                    data: snapshot.data ?? (musyrif.nip ?? musyrif.id),
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade800),
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
}
