import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/app_provider.dart';

class RegisterPesantrenScreen extends StatefulWidget {
  final AppProvider provider;
  const RegisterPesantrenScreen({super.key, required this.provider});

  @override
  State<RegisterPesantrenScreen> createState() => _RegisterPesantrenScreenState();
}

class _RegisterPesantrenScreenState extends State<RegisterPesantrenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _kodeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  File? _logoFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kodeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _logoFile = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.provider.registerNewPesantren(
        _namaCtrl.text.trim(),
        _kodeCtrl.text.trim().toLowerCase(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        logoPath: _logoFile?.path,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesantren berhasil terdaftar!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendaftarkan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(
          'Daftar Pesantren Baru',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Selector
                GestureDetector(
                  onTap: _isSaving ? null : _pickLogo,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                       Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green.shade200, width: 2),
                          image: _logoFile != null
                              ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _logoFile == null
                            ? const Icon(Icons.business_rounded, size: 50, color: Colors.green)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Logo Pesantren',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),

                // Form fields
                TextFormField(
                  controller: _namaCtrl,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pesantren',
                    hintText: 'cth: Pondok Modern Gontor',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Nama harus diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _kodeCtrl,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Kode Pondok',
                    hintText: 'cth: gontor (digunakan untuk login)',
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Kode harus diisi';
                    if (RegExp(r'\s+').hasMatch(value)) return 'Tidak boleh mengandung spasi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Admin Pesantren',
                    hintText: 'cth: admin@gontor.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email harus diisi';
                    if (!value.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  enabled: !_isSaving,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password Admin',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password harus diisi';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Text(
                            'DAFTARKAN PESANTREN',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
