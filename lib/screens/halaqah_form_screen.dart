import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/halaqah_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class HalaqahFormScreen extends StatefulWidget {
  const HalaqahFormScreen({super.key, this.existing});
  final HalaqahData? existing;

  @override
  State<HalaqahFormScreen> createState() => _HalaqahFormScreenState();
}

class _HalaqahFormScreenState extends State<HalaqahFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  String? _musyrifId;
  String? _photoPath;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _namaCtrl = TextEditingController(text: h?.nama ?? '');
    _musyrifId = h?.musyrifId;
    _photoPath = h?.photoPath;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
      final file = await picker.pickImage(source: source, imageQuality: 80);
      if (file != null) setState(() => _photoPath = file.path);
    }
  }

  void _showMusyrifPicker() {
    final provider = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Pilih Musyrif Pembimbing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('-- Belum ditentukan --'),
                    onTap: () { setState(() => _musyrifId = null); Navigator.pop(context); },
                    trailing: _musyrifId == null ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                  ),
                  ...provider.musyrifList.where((m) => m.isAktif).map((m) => ListTile(
                    title: Text(m.nama),
                    subtitle: Text(m.jabatan),
                    onTap: () { setState(() => _musyrifId = m.id); Navigator.pop(context); },
                    trailing: _musyrifId == m.id ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final h = HalaqahData(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaCtrl.text.trim(),
      musyrifId: _musyrifId,
      photoPath: _photoPath,
    );
    final provider = context.read<AppProvider>();
    _isEdit ? provider.updateHalaqah(h.id, h) : provider.addHalaqah(h);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Halaqah' : 'Tambah Halaqah'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded, color: Colors.white), tooltip: 'Simpan'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _photoPath != null
                      ? Image.file(File(_photoPath!), fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Upload Foto Halaqah / Kelompok', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _section('Informasi Utama'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Halaqah *', hintText: 'cth. Halaqah Al-Ikhlas', prefixIcon: Icon(Icons.groups_rounded)),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _showMusyrifPicker,
              child: IgnorePointer(
                child: Consumer<AppProvider>(
                  builder: (_, provider, __) {
                    final m = provider.getMusyrifById(_musyrifId);
                    return TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Musyrif Pembimbing',
                        prefixIcon: const Icon(Icons.person_rounded),
                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                        hintText: m?.nama ?? '-- Pilih Musyrif --',
                        floatingLabelBehavior: m != null ? FloatingLabelBehavior.always : null,
                      ),
                      controller: TextEditingController(text: m?.nama),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(onPressed: _save, icon: Icon(_isEdit ? Icons.save_rounded : Icons.group_add_rounded), label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Halaqah')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.primaryGreen)), const Divider()]);
}
