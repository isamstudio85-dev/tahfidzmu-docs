import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tahfidz_app/models/pengawas_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_form_screen.dart';

class PengawasDetailScreen extends StatelessWidget {
  const PengawasDetailScreen({super.key, required this.pengawasId});
  final String pengawasId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final list = provider.pengawasList.where((p) => p.id == pengawasId).toList();
        final pengawas = list.isNotEmpty ? list.first : null;
        if (pengawas == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pengawas')),
            body: const Center(child: Text('Pengawas tidak ditemukan')),
          );
        }

        final isAdmin = provider.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Pengawas'),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profil',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PengawasFormScreen(existing: pengawas)),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. DIGITAL CARD & QR CODE
              _PengawasDigitalCard(pengawas: pengawas),
              const SizedBox(height: 24),

              // 2. Informasi Akun
              _sectionHeader('Informasi Akun'),
              _infoCard([
                _infoRow(Icons.person_pin_rounded, 'Nama Pengawas', pengawas.nama),
                _infoRow(Icons.alternate_email_rounded, 'Username Login', '@${pengawas.username}'),
                _infoRow(Icons.work_outline_rounded, 'Jabatan', pengawas.jabatan),
                _infoRow(Icons.phone_rounded, 'WhatsApp', pengawas.nomorHp.isNotEmpty ? pengawas.nomorHp : '-'),
                _infoRow(Icons.info_outline_rounded, 'Status Keaktifan', pengawas.isAktif ? 'Aktif' : 'Non-aktif',
                    valueColor: pengawas.isAktif ? AppTheme.primaryGreen : Colors.grey),
              ]),
              const SizedBox(height: 24),

              // 3. Catatan
              if (pengawas.catatan?.isNotEmpty ?? false) ...[
                _sectionHeader('Catatan'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Text(
                    pengawas.catatan!,
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                ),
              ],
            ],
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
}

class _PengawasDigitalCard extends StatelessWidget {
  const _PengawasDigitalCard({required this.pengawas});
  final PengawasData pengawas;

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR CODE PENGAWAS',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen),
              ),
              const SizedBox(height: 20),
              FutureBuilder<String>(
                future: context.read<AppProvider>().getLoginQrData(pengawas.id),
                builder: (context, snapshot) {
                  return QrImageView(
                    data: snapshot.data ?? pengawas.username,
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  );
                },
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
                      child: pengawas.photoPath != null
                          ? Image.network(pengawas.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                pengawas.nama[0],
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
                          pengawas.nama,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Username: @${pengawas.username}',
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
                    'KARTU PENGAWAS DIGITAL',
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
                      child: pengawas.photoPath != null
                          ? Image.network(pengawas.photoPath!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                pengawas.nama[0],
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
                          pengawas.nama,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Username: @${pengawas.username}',
                          style: TextStyle(fontFamily: 'monospace', color: Colors.grey.shade600, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FutureBuilder<String>(
                    future: context.read<AppProvider>().getLoginQrData(pengawas.id),
                    builder: (context, snapshot) {
                      return QrImageView(
                        data: snapshot.data ?? pengawas.username,
                        version: QrVersions.auto,
                        size: 60.0,
                        backgroundColor: Colors.white,
                      );
                    },
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
