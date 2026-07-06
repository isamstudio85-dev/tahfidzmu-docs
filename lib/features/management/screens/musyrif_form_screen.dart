import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';

/// Full-page form for adding or editing a MusyrifData.
class MusyrifFormScreen extends StatefulWidget {
  const MusyrifFormScreen({super.key, this.existing});
  final MusyrifData? existing;

  @override
  State<MusyrifFormScreen> createState() => _MusyrifFormScreenState();
}

class _MusyrifFormScreenState extends State<MusyrifFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _nipCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _jabatanCtrl;
  late final TextEditingController _hpCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String _jenisKelamin = 'L';
  String _status = 'aktif';
  String? _photoPath;
  bool _showAccountInfo = false;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _namaCtrl = TextEditingController(text: m?.nama ?? '');
    _nipCtrl = TextEditingController(text: m?.nip ?? '');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _jabatanCtrl = TextEditingController(text: m?.jabatan ?? '');
    _hpCtrl = TextEditingController(text: m?.nomorHp ?? '');
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _jenisKelamin = m?.jenisKelamin ?? 'L';
    _status = m?.status ?? 'aktif';
    _photoPath = m?.photoPath;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nipCtrl.dispose();
    _emailCtrl.dispose();
    _jabatanCtrl.dispose();
    _hpCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _photoPath = pickedFile.path);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();
    final pesantrenName = provider.pesantrenName.isNotEmpty
        ? provider.pesantrenName
        : 'Halaqah Tahfidz';

    try {
      final m = MusyrifData(
        id: widget.existing?.id ?? provider.generateId('musyrif'),
        nama: _namaCtrl.text.trim(),
        nip: _nipCtrl.text.trim().isEmpty ? null : _nipCtrl.text.trim(),
        jenisKelamin: _jenisKelamin,
        jabatan: _jabatanCtrl.text.trim().isEmpty
            ? (_jenisKelamin == 'P' ? 'Musyrifah' : 'Musyrif')
            : _jabatanCtrl.text.trim(),
        lembaga: pesantrenName,
        nomorHp: _hpCtrl.text.trim(),
        status: _status,
        photoPath: _photoPath,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      );

      if (_isEdit) {
        // If photo changed, we need to upload it. But here _photoPath might be 
        // a local path or a cloud URL. updateMusyrifData just updates Firestore.
        // Let's handle photo update properly if it's a new local path.
        if (_photoPath != null && !_photoPath!.startsWith('http')) {
           await provider.updateMusyrifPhoto(_photoPath!);
           // Re-fetch the photo URL if needed, or rely on updateMusyrifPhoto's firestore update
        }
        await provider.updateMusyrifData(m.id, m);
      } else {
        await provider.addMusyrif(
          m,
          username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
        );
        // Note: addMusyrif doesn't handle photo upload yet, similar to addSantri
        // I should update addMusyrif to handle photo upload too.
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  Future<void> _scanExistingCard() async {
    final rawString = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(returnRaw: true),
      ),
    );

    if (rawString == null || rawString is! String || rawString.trim().isEmpty) return;
    final trimmed = rawString.trim();

    // 1. Coba parse sebagai JSON
    try {
      final data = jsonDecode(trimmed);
      if (data is Map<String, dynamic>) {
        setState(() {
          if (data.containsKey('nama')) _namaCtrl.text = data['nama'].toString();
          if (data.containsKey('name')) _namaCtrl.text = data['name'].toString();
          
          if (data.containsKey('nip')) _nipCtrl.text = data['nip'].toString();
          if (data.containsKey('id')) _nipCtrl.text = data['id'].toString();
          
          if (data.containsKey('email')) _emailCtrl.text = data['email'].toString();
          
          if (data.containsKey('nomorHp')) _hpCtrl.text = data['nomorHp'].toString();
          if (data.containsKey('hp')) _hpCtrl.text = data['hp'].toString();
          
          if (data.containsKey('jabatan')) _jabatanCtrl.text = data['jabatan'].toString();
          
          if (data.containsKey('jenisKelamin')) {
            final gk = data['jenisKelamin'].toString().toUpperCase();
            if (gk == 'L' || gk == 'P') _jenisKelamin = gk;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data kartu berhasil disalin ke form!'), backgroundColor: Colors.green),
          );
        }
        return;
      }
    } catch (_) {}

    // 2. Coba parse sebagai URL dengan query parameters
    try {
      final uri = Uri.parse(trimmed);
      if (uri.hasQuery) {
        setState(() {
          final params = uri.queryParameters;
          if (params.containsKey('nama')) _namaCtrl.text = params['nama']!;
          if (params.containsKey('name')) _namaCtrl.text = params['name']!;
          
          if (params.containsKey('nip')) _nipCtrl.text = params['nip']!;
          if (params.containsKey('id')) _nipCtrl.text = params['id']!;
          
          if (params.containsKey('email')) _emailCtrl.text = params['email']!;
          
          if (params.containsKey('nomorHp')) _hpCtrl.text = params['nomorHp']!;
          if (params.containsKey('hp')) _hpCtrl.text = params['hp']!;
          
          if (params.containsKey('jabatan')) _jabatanCtrl.text = params['jabatan']!;
          
          if (params.containsKey('jenisKelamin')) {
            final gk = params['jenisKelamin']!.toUpperCase();
            if (gk == 'L' || gk == 'P') _jenisKelamin = gk;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data link kartu berhasil disalin ke form!'), backgroundColor: Colors.green),
          );
        }
        return;
      }
    } catch (_) {}

    // 3. Fallback: Anggap sebagai raw string NIP
    setState(() {
      _nipCtrl.text = trimmed;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode QR disalin ke kolom NIP: $trimmed'), backgroundColor: Colors.blue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Musyrif' : 'Tambah Musyrif'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            tooltip: _isEdit ? 'Simpan' : 'Tambah',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: AppAvatar(
                      name: _namaCtrl.text.isEmpty ? '?' : _namaCtrl.text,
                      radius: 50,
                      imagePath: _photoPath,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _scanExistingCard,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan & Salin Kartu Digital Musyrif', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            _section('Informasi Utama'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap *',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _labelText('Jenis Kelamin'),
            const SizedBox(height: 8),
            Row(
              children: [
                _genderChip('L', 'Laki-laki', Icons.male_rounded),
                const SizedBox(width: 12),
                _genderChip('P', 'Perempuan', Icons.female_rounded),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nipCtrl,
              decoration: const InputDecoration(
                labelText: 'NIP (Nomor Induk Pegawai)',
                hintText: 'cth. NIP-001',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'musyrif@example.com',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hpCtrl,
              decoration: const InputDecoration(
                labelText: 'No. HP / WhatsApp',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jabatanCtrl,
              decoration: InputDecoration(
                labelText: 'Jabatan',
                hintText: _jenisKelamin == 'P'
                    ? 'cth. Musyrifah, Koordinator Tahfidz...'
                    : 'cth. Musyrif, Kepala Tahfidz...',
                prefixIcon: const Icon(Icons.work_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),
            InkWell(
              onTap: () => setState(() => _showAccountInfo = !_showAccountInfo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Info Akun',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showAccountInfo
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),

            if (_showAccountInfo) ...[
              const SizedBox(height: 12),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username Login (Kustom)',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Login (Kustom)',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ],
              if (_isEdit) ...[
                _labelText('Status Musyrif'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusChip('aktif', 'Aktif', AppTheme.primaryGreen),
                    const SizedBox(width: 12),
                    _statusChip('nonaktif', 'Non-aktif', Colors.grey.shade600),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                label: Text(_isSaving ? 'Menyimpan...' : (_isEdit ? 'Simpan Perubahan' : 'Tambah Musyrif')),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.primaryGreen,
        ),
      ),
      const Divider(),
    ],
  );

  Widget _labelText(String t) => Text(
    t,
    style: TextStyle(
      color: Colors.grey.shade700,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _genderChip(String value, String label, IconData icon) {
    final sel = _jenisKelamin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jenisKelamin = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? AppTheme.primaryGreen : Colors.grey.shade300,
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: sel ? AppTheme.primaryGreen : Colors.grey.shade500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: sel ? AppTheme.primaryGreen : Colors.grey.shade600,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, Color color) {
    final sel = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? color : Colors.grey.shade300,
              width: sel ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: sel ? color : Colors.grey.shade600,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
