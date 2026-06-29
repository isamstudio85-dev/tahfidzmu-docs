import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';

/// Full-page form for adding or editing a Santri.
class SantriFormScreen extends StatefulWidget {
  const SantriFormScreen({super.key, this.existing});
  final Santri? existing;

  @override
  State<SantriFormScreen> createState() => _SantriFormScreenState();
}

class _SantriFormScreenState extends State<SantriFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _nisCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _namaOrangTuaCtrl;
  late final TextEditingController _nomorHpWaliCtrl;

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String? _jenisKelamin;
  String? _halaqahId;
  String? _photoPath;
  String? _targetJuz;
  String _status = 'aktif';
  bool _showAccountInfo = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _namaCtrl = TextEditingController(text: s?.name ?? '');
    _nisCtrl = TextEditingController(text: s?.nis ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _namaOrangTuaCtrl = TextEditingController(text: s?.namaOrangTua ?? s?.namaAyah ?? s?.namaIbu ?? '');
    _nomorHpWaliCtrl = TextEditingController(text: s?.nomorHpWali ?? '');

    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();

    _jenisKelamin = s?.jenisKelamin;
    _halaqahId = s?.halaqahId;
    _photoPath = s?.photoPath;
    _status = s?.status ?? 'aktif';

    if (s?.targetHafalan != null) {
      final raw = s!.targetHafalan!;
      if (RegExp(r'^\d+ Juz$').hasMatch(raw)) {
        _targetJuz = raw;
      } else {
        final match = RegExp(r'(\d+)').firstMatch(raw);
        if (match != null) {
          _targetJuz = '${match.group(1)} Juz';
        }
      }
      if (_targetJuz != null) {
        final numPart = int.tryParse(_targetJuz!.split(' ')[0]) ?? 0;
        if (numPart < 1 || numPart > 30) _targetJuz = null;
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nisCtrl.dispose();
    _emailCtrl.dispose();
    _namaOrangTuaCtrl.dispose();
    _nomorHpWaliCtrl.dispose();
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

  void _showHalaqahPicker() {
    final provider = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Pilih Halaqah', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('-- Belum ditentukan --'),
                    onTap: () { setState(() => _halaqahId = null); Navigator.pop(context); },
                    trailing: _halaqahId == null ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                  ),
                  ...provider.halaqahList.map((h) => ListTile(
                    title: Text(h.nama),
                    onTap: () { setState(() => _halaqahId = h.id); Navigator.pop(context); },
                    trailing: _halaqahId == h.id ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJuzPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Target Hafalan (Juz)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: 31,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _juzChip(null, '--');
                  }
                  final val = '$i Juz';
                  return _juzChip(val, i.toString());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _juzChip(String? value, String label) {
    final isSelected = _targetJuz == value;
    return InkWell(
      onTap: () { setState(() => _targetJuz = value); Navigator.pop(context); },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    if (_isEdit) {
      provider.updateSantriInfo(
        widget.existing!.id,
        name: _namaCtrl.text.trim(),
        nis: _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        jenisKelamin: _jenisKelamin,
        halaqahId: _halaqahId,
        namaOrangTua: _namaOrangTuaCtrl.text.trim().isEmpty ? null : _namaOrangTuaCtrl.text.trim(),
        nomorHpWali: _nomorHpWaliCtrl.text.trim().isEmpty ? null : _nomorHpWaliCtrl.text.trim(),
        targetHafalan: _targetJuz,
        photoPath: _photoPath,
        status: _status,
      );
    } else {
      provider.addSantri(
        _namaCtrl.text.trim(),
        nis: _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        jenisKelamin: _jenisKelamin,
        halaqahId: _halaqahId,
        namaOrangTua: _namaOrangTuaCtrl.text.trim().isEmpty ? null : _namaOrangTuaCtrl.text.trim(),
        nomorHpWali: _nomorHpWaliCtrl.text.trim().isEmpty ? null : _nomorHpWaliCtrl.text.trim(),
        targetHafalan: _targetJuz,
        photoPath: _photoPath,
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Data Santri' : 'Tambah Santri'),
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
                      name: _namaCtrl.text.isEmpty ? (_isEdit ? widget.existing!.name : '?') : _namaCtrl.text,
                      radius: 50,
                      imagePath: _photoPath,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section('Informasi Utama'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap *', prefixIcon: Icon(Icons.person_rounded)),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              onChanged: (_) => setState(() {}),
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
              controller: _nisCtrl,
              decoration: const InputDecoration(labelText: 'NIS (Nomor Induk Santri)', hintText: 'cth. TH-2024-001', prefixIcon: Icon(Icons.badge_rounded)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'santri@example.com', prefixIcon: Icon(Icons.email_rounded)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // Custom Halaqah Picker
            InkWell(
              onTap: _showHalaqahPicker,
              child: IgnorePointer(
                child: Consumer<AppProvider>(
                  builder: (_, provider, __) {
                    final h = provider.getHalaqahById(_halaqahId);
                    return TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Halaqah',
                        prefixIcon: const Icon(Icons.groups_rounded),
                        suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                        hintText: h?.nama ?? '-- Pilih Halaqah --',
                        floatingLabelBehavior: h != null ? FloatingLabelBehavior.always : null,
                      ),
                      controller: TextEditingController(text: h?.nama),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Custom Juz Picker
            InkWell(
              onTap: _showJuzPicker,
              child: IgnorePointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Target Hafalan',
                    prefixIcon: const Icon(Icons.flag_rounded),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                    hintText: _targetJuz ?? '-- Pilih Target (Juz) --',
                    floatingLabelBehavior: _targetJuz != null ? FloatingLabelBehavior.always : null,
                  ),
                  controller: TextEditingController(text: _targetJuz),
                ),
              ),
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _namaOrangTuaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Orang Tua', prefixIcon: Icon(Icons.family_restroom_rounded)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomorHpWaliCtrl,
              decoration: const InputDecoration(labelText: 'No. HP Wali', hintText: 'cth. 081234567890', prefixIcon: Icon(Icons.phone_rounded)),
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 24),
            InkWell(
              onTap: () => setState(() => _showAccountInfo = !_showAccountInfo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text('Info Akun', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Icon(_showAccountInfo ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
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
                  decoration: const InputDecoration(labelText: 'Username Login (Kustom)', prefixIcon: Icon(Icons.person_outline_rounded)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password Login (Kustom)', prefixIcon: Icon(Icons.lock_outline_rounded)),
                ),
                const SizedBox(height: 12),
              ],
              if (_isEdit) ...[
                _labelText('Status Santri'),
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
                onPressed: _save,
                icon: Icon(_isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Santri'),
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
      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.primaryGreen)),
      const Divider(),
    ],
  );

  Widget _labelText(String t) => Text(t, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500));

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _jenisKelamin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jenisKelamin = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppTheme.primaryGreen : Colors.grey.shade500),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: selected ? AppTheme.primaryGreen : Colors.grey.shade600, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String value, String label, Color color) {
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Center(child: Text(label, style: TextStyle(color: selected ? color : Colors.grey.shade600, fontWeight: selected ? FontWeight.w600 : FontWeight.normal))),
        ),
      ),
    );
  }
}
