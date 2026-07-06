import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class VerificationGate {
  static Future<Santri?> show({
    required BuildContext context,
    Santri? expectedSantri,
  }) async {
    return await showModalBottomSheet<Santri?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _VerificationBottomSheet(expectedSantri: expectedSantri),
    );
  }
}

class _VerificationBottomSheet extends StatefulWidget {
  final Santri? expectedSantri;
  const _VerificationBottomSheet({this.expectedSantri});

  @override
  State<_VerificationBottomSheet> createState() => _VerificationBottomSheetState();
}

class _VerificationBottomSheetState extends State<_VerificationBottomSheet> {
  bool _isLoading = false;
  String _loadingMessage = '';

  Future<void> _handleQrVerification() async {
    final verified = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(expectedSantri: widget.expectedSantri),
      ),
    );

    if (verified != null && mounted) {
      Navigator.pop(context, verified is Santri ? verified : widget.expectedSantri);
    }
  }

  Future<void> _handlePhotoVerification() async {
    final provider = context.read<AppProvider>();
    Santri? targetSantri = widget.expectedSantri;

    if (targetSantri == null) {
      // Jika belum ada santri terpilih, minta pilih dulu dari list
      final selected = await _showSantriSelector(provider);
      if (selected == null) return;
      targetSantri = selected;
    }

    // Buka Kamera untuk ambil foto wajah
    final ImagePicker picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70, // Kompresi agar hemat bandwith
      );
    } catch (e) {
      _showSnackBar('Gagal mengakses kamera: $e', Colors.red);
      return;
    }

    if (image == null) return; // Batal ambil foto

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Mengunggah bukti foto wajah...';
    });

    try {
      final pid = provider.pesantrenId;
      if (pid != null) {
        // Upload dengan folder khusus verifikasi dan nama file berupa ID Santri
        // Firebase Storage otomatis meng-overwrite file yang sama, menjaga storage tetap hemat (max 1 file per santri)
        await provider.firebase.uploadPhoto(
          localPath: image.path,
          folder: 'pesantren/$pid/verifications',
          fileName: targetSantri.id,
        );

        // Simpan timestamp verifikasi foto terakhir ke Firestore
        await provider.getCollection('santri').doc(targetSantri.id).update({
          'lastPhotoVerifiedAt': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        _showSnackBar('Verifikasi Wajah Santri Berhasil!', Colors.green);
        Navigator.pop(context, targetSantri);
      }
    } catch (e) {
      _showSnackBar('Gagal mengunggah foto verifikasi: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Santri?> _showSantriSelector(AppProvider provider) async {
    final list = provider.isMusyrif && provider.linkedMusyrif != null
        ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
        : provider.santriList;

    return await showModalBottomSheet<Santri>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Pilih Santri Terlebih Dahulu', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (ctx, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: Text(list[i].name[0], style: const TextStyle(color: AppTheme.primaryGreen)),
                  ),
                  title: Text(list[i].name),
                  onTap: () => Navigator.pop(ctx, list[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String text, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), backgroundColor: color, duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryGreen),
            const SizedBox(height: 20),
            Text(
              _loadingMessage,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Foto baru akan menimpa foto lama untuk menghemat penyimpanan.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.expectedSantri != null ? 'Verifikasi Kehadiran' : 'Input Hafalan Baru',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            widget.expectedSantri != null
                ? 'Verifikasi kehadiran fisik ${widget.expectedSantri!.name} sebelum memulai simak hafalan.'
                : 'Musyrif wajib memverifikasi kehadiran fisik santri secara langsung.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _OptionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Pindai Kartu',
                  subtitle: 'Scan QR Code',
                  color: AppTheme.primaryGreen,
                  onTap: _handleQrVerification,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Ambil Foto',
                  subtitle: 'Lupa kartu santri',
                  color: Colors.blue.shade700,
                  onTap: _handlePhotoVerification,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
