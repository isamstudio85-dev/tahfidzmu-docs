import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Full-page screen for admin to manage pesantren identity,
/// logo, and which hafalan modules are active.
class PesantrenScreen extends StatefulWidget {
  const PesantrenScreen({super.key, this.manageModulesOnly = false});

  final bool manageModulesOnly;

  @override
  State<PesantrenScreen> createState() => _PesantrenScreenState();
}

class _PesantrenScreenState extends State<PesantrenScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _telponCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    final info = context.read<AppProvider>().pesantrenInfo;
    _namaCtrl = TextEditingController(text: info.nama);
    _alamatCtrl = TextEditingController(text: info.alamat);
    _telponCtrl = TextEditingController(text: info.noTelp);
    _emailCtrl = TextEditingController(text: info.email);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    _telponCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    provider.updatePesantrenInfo(
      provider.pesantrenInfo.copyWith(
        nama: _namaCtrl.text.trim(),
        alamat: _alamatCtrl.text.trim(),
        noTelp: _telponCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informasi pesantren disimpan'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Logo Pesantren',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 512,
    );
    if (file != null && mounted) {
      context.read<AppProvider>().updatePesantrenInfo(
        context.read<AppProvider>().pesantrenInfo.copyWith(logoPath: file.path),
      );
    }
  }

  void _removeLogo() {
    final provider = context.read<AppProvider>();
    provider.updatePesantrenInfo(provider.pesantrenInfo.copyWith(logoPath: ''));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.manageModulesOnly
        ? 'Kelola Modul Tahfidz'
        : 'Informasi Pesantren';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!widget.manageModulesOnly)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          final info = provider.pesantrenInfo;
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!widget.manageModulesOnly) ...[
                  // ── Logo ─────────────────────────────────────────────────
                  _sectionLabel('Logo Pesantren'),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryGreen.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: info.hasLogo
                                    ? Image.file(
                                        File(info.logoPath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.school_rounded,
                                              size: 44,
                                              color: AppTheme.primaryGreen,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.school_rounded,
                                        size: 44,
                                        color: AppTheme.primaryGreen,
                                      ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (info.hasLogo)
                          TextButton.icon(
                            onPressed: _removeLogo,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Hapus Logo',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          )
                        else
                          Text(
                            'Tap untuk upload logo pesantren',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Identitas ─────────────────────────────────────────────
                  _sectionLabel('Identitas Pesantren'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _namaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pesantren *',
                      prefixIcon: Icon(Icons.school_rounded),
                      hintText: 'cth. Pesantren Darul Quran',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _alamatCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      prefixIcon: Icon(Icons.location_on_rounded),
                      hintText: 'cth. Jl. Raya Pesantren No. 1, Bandung',
                      alignLabelWithHint: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // ── Kontak ────────────────────────────────────────────────
                  _sectionLabel('Kontak'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telponCtrl,
                    decoration: const InputDecoration(
                      labelText: 'No. Telpon / WhatsApp',
                      prefixIcon: Icon(Icons.phone_rounded),
                      hintText: 'cth. 0812-3456-7890',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_rounded),
                      hintText: 'cth. info@pesantren.sch.id',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 28),
                ],

                if (widget.manageModulesOnly) ...[
                  _sectionLabel('Modul Hafalan Aktif'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Al-Quran — always active, cannot be toggled off
                        SwitchListTile(
                          value: true,
                          onChanged: null,
                          title: const Text(
                            'Tahfidz Al-Quran',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Hafalan & setoran Al-Quran'),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 16),
                        // Hadits
                        SwitchListTile(
                          value: provider.isModuleActive('hadits'),
                          onChanged: (_) => provider.toggleModule('hadits'),
                          title: const Text(
                            'Tahfidz Hadits',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Hafalan & setoran hadits'),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.import_contacts_rounded,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const Divider(height: 1, indent: 16),
                        // Kitab Lain
                        SwitchListTile(
                          value: provider.isModuleActive('kitab'),
                          onChanged: (_) => provider.toggleModule('kitab'),
                          title: const Text(
                            'Kitab / Matan Lain',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Hafalan kitab atau matan pilihan',
                          ),
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.library_books_rounded,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Modul yang dinonaktifkan tidak akan muncul di tampilan musyrif dan orang tua.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                if (!widget.manageModulesOnly)
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan Perubahan'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 11,
        color: Colors.grey.shade600,
        letterSpacing: 1.0,
      ),
    );
  }
}
