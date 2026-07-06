import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
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

        return DefaultTabController(
          length: 2,
          child: Scaffold(
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
            body: Column(
              children: [
                // 1. Unified Profile Header (Compact & Centered to prevent right overflow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _ProfileHeader(
                    name: musyrif.nama,
                    subtitle: musyrif.jabatan,
                    photoPath: musyrif.photoPath,
                  ),
                ),

                // 2. TabBar (Shorter text tabs to prevent overflow)
                TabBar(
                  tabs: const [
                    Tab(text: 'Statistik'),
                    Tab(text: 'Profil & QR'),
                  ],
                  labelColor: AppTheme.primaryGreen,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: AppTheme.primaryGreen,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                ),

                // 3. TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: STATISTIK & CATATAN
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Unified Stats Row
                          Row(
                            children: [
                              _statItem('Halaqah', '$halaqahCount', Icons.groups_rounded, AppTheme.primaryGreen),
                              const SizedBox(width: 12),
                              _statItem('Santri', '$santriCount', Icons.people_alt_rounded, const Color(0xFF1565C0)),
                            ],
                          ),
                          const SizedBox(height: 20),

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
                        ],
                      ),

                      // TAB 2: PROFIL & KARTU QR
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // MINI DIGITAL CARD with QR code
                          _MiniMusyrifDigitalCard(musyrif: musyrif),
                          const SizedBox(height: 20),

                          // Informasi Personal
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
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(
            name: name,
            radius: 36,
            imagePath: photoPath,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            foregroundColor: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniMusyrifDigitalCard extends StatelessWidget {
  final MusyrifData musyrif;
  const _MiniMusyrifDigitalCard({required this.musyrif});

  void _showQrDialog(BuildContext context) {
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
                'KARTU MUSYRIF DIGITAL',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.primaryGreen,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: musyrif.nip ?? musyrif.id,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: musyrif.photoPath != null
                          ? Image.network(musyrif.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                musyrif.nama[0],
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
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
                          musyrif.nama,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NIP/ID: ${musyrif.nip ?? musyrif.id}',
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showQrDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KARTU MUSYRIF DIGITAL',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGreen, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                      child: musyrif.photoPath != null
                          ? Image.network(musyrif.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                musyrif.nama[0],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen),
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
                          musyrif.nama,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIP/ID: ${musyrif.nip ?? musyrif.id}',
                          style: TextStyle(fontFamily: 'monospace', color: Colors.grey.shade600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  QrImageView(
                    data: musyrif.nip ?? musyrif.id,
                    version: QrVersions.auto,
                    size: 60.0,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Ketuk kartu untuk memperbesar QR Code',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
