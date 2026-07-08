import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

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
  late final TextEditingController _npsnCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _pimpinanCtrl;

  @override
  void initState() {
    super.initState();
    final info = context.read<AppProvider>().pesantrenInfo;
    _namaCtrl = TextEditingController(text: info.nama);
    _alamatCtrl = TextEditingController(text: info.alamat);
    _telponCtrl = TextEditingController(text: info.noTelp);
    _emailCtrl = TextEditingController(text: info.email);
    _npsnCtrl = TextEditingController(text: info.npsn);
    _websiteCtrl = TextEditingController(text: info.website);
    _pimpinanCtrl = TextEditingController(text: info.pimpinan);
  }

  @override
  void dispose() {
    _namaCtrl.dispose(); 
    _alamatCtrl.dispose(); 
    _telponCtrl.dispose(); 
    _emailCtrl.dispose();
    _npsnCtrl.dispose();
    _websiteCtrl.dispose();
    _pimpinanCtrl.dispose();
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
        npsn: _npsnCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        pimpinan: _pimpinanCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Galeri'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Kamera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ],
        ),
      ),
    );

    if (source != null) {
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null && mounted) {
        context.read<AppProvider>().updatePesantrenInfo(
          context.read<AppProvider>().pesantrenInfo.copyWith(logoPath: file.path),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.manageModulesOnly ? 'Kelola Modul' : 'Profil Pesantren';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!widget.manageModulesOnly)
            IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded, color: Colors.white)),
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
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: info.hasLogo
                                ? (info.logoPath.startsWith('http') 
                                    ? Image.network(info.logoPath, fit: BoxFit.cover)
                                    : Image.file(File(info.logoPath), fit: BoxFit.cover))
                                : Image.asset('assets/images/logoAlf.png', fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.school_rounded, size: 40, color: AppTheme.primaryGreen)),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section('Informasi Utama'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _namaCtrl, decoration: const InputDecoration(labelText: 'Nama Pesantren *', prefixIcon: Icon(Icons.school_outlined)), textCapitalization: TextCapitalization.words, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: _npsnCtrl, decoration: const InputDecoration(labelText: 'NPSN (Nomor Induk Nasional)', prefixIcon: Icon(Icons.fingerprint_rounded)), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextFormField(controller: _pimpinanCtrl, decoration: const InputDecoration(labelText: 'Kiai / Pimpinan Pondok', prefixIcon: Icon(Icons.person_outline_rounded)), textCapitalization: TextCapitalization.words),
                  const SizedBox(height: 12),
                  TextFormField(controller: _alamatCtrl, decoration: const InputDecoration(labelText: 'Alamat Lengkap', prefixIcon: Icon(Icons.location_on_outlined)), maxLines: 2),
                  const SizedBox(height: 24),
                  _section('Kontak & Media'),
                  const SizedBox(height: 12),
                  TextFormField(controller: _telponCtrl, decoration: const InputDecoration(labelText: 'No. Telpon / WA', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Resmi', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  TextFormField(controller: _websiteCtrl, decoration: const InputDecoration(labelText: 'Website Pesantren', prefixIcon: Icon(Icons.language_rounded)), keyboardType: TextInputType.url),
                ],
                if (widget.manageModulesOnly) ...[
                  _section('Modul Hafalan & Pengetahuan'),
                  const SizedBox(height: 12),
                  _moduleSwitch(provider, 'Quran', 'Hafalan & Setoran Al-Quran', Icons.menu_book_rounded, true),
                  _moduleSwitch(provider, 'Hadits', 'Hafalan hadits-hadits pilihan', Icons.import_contacts_rounded, provider.isModuleActive('hadits'), onTap: () => provider.toggleModule('hadits')),
                  _moduleSwitch(provider, 'Tajwid', 'Panduan hukum bacaan Al-Quran', Icons.auto_stories_rounded, provider.isModuleActive('tajwid'), onTap: () => provider.toggleModule('tajwid')),
                  _moduleSwitch(provider, 'Tahsin', 'Panduan fasih & makharijul huruf', Icons.record_voice_over_rounded, provider.isModuleActive('tahsin'), onTap: () => provider.toggleModule('tahsin')),
                  _moduleSwitch(provider, 'Pengetahuan Pondok', 'Materi pengetahuan pondok yang harus dihafal', Icons.lightbulb_outline_rounded, provider.isModuleActive('pondok_info'), onTap: () => provider.toggleModule('pondok_info')),
                  _moduleSwitch(provider, 'Wisuda & Ujian Tasmi\'', 'Pendaftaran ujian tasmi\' dan kelulusan wisuda', Icons.school_rounded, provider.isModuleActive('graduation'), onTap: () => provider.toggleModule('graduation')),
                ],
                const SizedBox(height: 32),
                if (!widget.manageModulesOnly)
                  SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_rounded), label: const Text('Simpan Perubahan'))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)), const Divider()]);

  Widget _moduleSwitch(AppProvider p, String title, String sub, IconData icon, bool val, {VoidCallback? onTap}) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: SwitchListTile(
        value: val, onChanged: onTap != null ? (_) => onTap() : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: AppTheme.primaryGreen),
      ),
    );
  }
}
