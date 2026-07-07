import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/models/pengawas_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class PengawasFormScreen extends StatefulWidget {
  const PengawasFormScreen({super.key, this.existing});
  final PengawasData? existing;

  @override
  State<PengawasFormScreen> createState() => _PengawasFormScreenState();
}

class _PengawasFormScreenState extends State<PengawasFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _hpCtrl;
  late final TextEditingController _jabatanCtrl;
  late final TextEditingController _catatanCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String _status = 'aktif';
  String? _photoPath;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _namaCtrl = TextEditingController(text: p?.nama ?? '');
    _hpCtrl = TextEditingController(text: p?.nomorHp ?? '');
    _jabatanCtrl = TextEditingController(text: p?.jabatan ?? 'Pengawas');
    _catatanCtrl = TextEditingController(text: p?.catatan ?? '');
    _usernameCtrl = TextEditingController(text: p?.username ?? '');
    _passwordCtrl = TextEditingController();
    _status = p?.status ?? 'aktif';
    _photoPath = p?.photoPath;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hpCtrl.dispose();
    _jabatanCtrl.dispose();
    _catatanCtrl.dispose();
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
        maxWidth: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _photoPath = pickedFile.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Pengawas' : 'Tambah Pengawas'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. Photo Upload Card
                    _buildPhotoCard(),
                    const SizedBox(height: 20),

                    // 2. Personal Information Card
                    _buildPersonalCard(),
                    const SizedBox(height: 20),

                    // 3. Login Account Settings Card (Only for creation)
                    if (!_isEdit) _buildLoginCard(),
                    if (!_isEdit) const SizedBox(height: 20),

                    // 4. Status and Notes Card
                    _buildStatusNotesCard(),
                    const SizedBox(height: 32),

                    // 5. Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH PENGAWAS',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              backgroundImage: _photoPath != null && !_photoPath!.startsWith('http')
                  ? FileImage(File(_photoPath!))
                  : (_photoPath != null ? NetworkImage(_photoPath!) as ImageProvider : null),
              child: _photoPath == null
                  ? const Icon(Icons.person_outline, size: 40, color: AppTheme.primaryGreen)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Foto Profil', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Ambil foto langsung atau unggah dari galeri.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                    label: const Text('Pilih Foto', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Diri', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaCtrl,
              decoration: _inputDecoration('Nama Lengkap *', Icons.person_outline_rounded),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hpCtrl,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('No. HP / WhatsApp', Icons.phone_rounded),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: ['Pimpinan', 'Pengawas'].contains(_jabatanCtrl.text) ? _jabatanCtrl.text : 'Pengawas',
              decoration: _inputDecoration('Jabatan *', Icons.work_outline_rounded),
              items: const [
                DropdownMenuItem(value: 'Pimpinan', child: Text('Pimpinan')),
                DropdownMenuItem(value: 'Pengawas', child: Text('Pengawas')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _jabatanCtrl.text = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kredensial Akun Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameCtrl,
              decoration: _inputDecoration('Username Login *', Icons.alternate_email_rounded),
              textCapitalization: TextCapitalization.none,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Username harus diisi';
                if (v.contains(' ')) return 'Username tidak boleh mengandung spasi';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: _inputDecoration('Kata Sandi *', Icons.lock_outline_rounded),
              validator: (v) => v == null || v.trim().length < 6 ? 'Sandi minimal 6 karakter' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusNotesCard() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status & Catatan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              items: const [
                DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'nonaktif', child: Text('Non-aktif')),
              ],
              onChanged: (val) => setState(() => _status = val ?? 'aktif'),
              decoration: _inputDecoration('Status Akun', Icons.info_outline_rounded),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catatanCtrl,
              maxLines: 3,
              decoration: _inputDecoration('Catatan Tambahan', Icons.notes_rounded),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();

    try {
      final name = _namaCtrl.text.trim();
      final hp = _hpCtrl.text.trim();
      final jab = _jabatanCtrl.text.trim();
      final cat = _catatanCtrl.text.trim();
      final username = _usernameCtrl.text.trim().toLowerCase();
      final pwd = _passwordCtrl.text.trim();

      if (_isEdit) {
        final existing = widget.existing!;
        final updated = existing.copyWith(
          nama: name,
          nomorHp: hp,
          jabatan: jab,
          status: _status,
          photoPath: _photoPath,
          catatan: cat.isEmpty ? null : cat,
        );
        await provider.updatePengawasData(existing.id, updated);
      } else {
        final newId = provider.generateId('pengawas');
        final newPengawas = PengawasData(
          id: newId,
          nama: name,
          username: username,
          nomorHp: hp,
          jabatan: jab,
          status: _status,
          photoPath: _photoPath,
          catatan: cat.isEmpty ? null : cat,
        );
        await provider.addPengawas(newPengawas, username: username, password: pwd);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Profil Pengawas diperbarui' : 'Pengawas berhasil ditambahkan'),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
