import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';

/// Full-page form for adding or editing a Santri.
/// Push this screen with Navigator.push / Navigator.pushReplacement.
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
  late final TextEditingController _kelasCtrl;
  late final TextEditingController _namaAyahCtrl;
  late final TextEditingController _namaIbuCtrl;
  late final TextEditingController _nomorHpWaliCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String? _jenisKelamin;
  String? _halaqahId;
  String _status = 'aktif';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _namaCtrl = TextEditingController(text: s?.name ?? '');
    _nisCtrl = TextEditingController(text: s?.nis ?? '');
    _kelasCtrl = TextEditingController(text: s?.kelas ?? '');
    _namaAyahCtrl = TextEditingController(text: s?.namaAyah ?? '');
    _namaIbuCtrl = TextEditingController(text: s?.namaIbu ?? '');
    _nomorHpWaliCtrl = TextEditingController(text: s?.nomorHpWali ?? '');
    _targetCtrl = TextEditingController(text: s?.targetHafalan ?? '');
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _jenisKelamin = s?.jenisKelamin;
    _halaqahId = s?.halaqahId;
    _status = s?.status ?? 'aktif';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nisCtrl.dispose();
    _kelasCtrl.dispose();
    _namaAyahCtrl.dispose();
    _namaIbuCtrl.dispose();
    _nomorHpWaliCtrl.dispose();
    _targetCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    if (_isEdit) {
      provider.updateSantriInfo(
        widget.existing!.id,
        name: _namaCtrl.text.trim(),
        nis: _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim(),
        jenisKelamin: _jenisKelamin,
        kelas: _kelasCtrl.text.trim().isEmpty ? null : _kelasCtrl.text.trim(),
        halaqahId: _halaqahId,
        namaAyah: _namaAyahCtrl.text.trim().isEmpty
            ? null
            : _namaAyahCtrl.text.trim(),
        namaIbu: _namaIbuCtrl.text.trim().isEmpty
            ? null
            : _namaIbuCtrl.text.trim(),
        nomorHpWali: _nomorHpWaliCtrl.text.trim().isEmpty
            ? null
            : _nomorHpWaliCtrl.text.trim(),
        targetHafalan: _targetCtrl.text.trim().isEmpty
            ? null
            : _targetCtrl.text.trim(),
        status: _status,
      );
    } else {
      provider.addSantri(
        _namaCtrl.text.trim(),
        _kelasCtrl.text.trim().isEmpty ? null : _kelasCtrl.text.trim(),
        nis: _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim(),
        jenisKelamin: _jenisKelamin,
        halaqahId: _halaqahId,
        namaAyah: _namaAyahCtrl.text.trim().isEmpty
            ? null
            : _namaAyahCtrl.text.trim(),
        namaIbu: _namaIbuCtrl.text.trim().isEmpty
            ? null
            : _namaIbuCtrl.text.trim(),
        nomorHpWali: _nomorHpWaliCtrl.text.trim().isEmpty
            ? null
            : _nomorHpWaliCtrl.text.trim(),
        targetHafalan: _targetCtrl.text.trim().isEmpty
            ? null
            : _targetCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty
            ? null
            : _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim().isEmpty
            ? null
            : _passwordCtrl.text.trim(),
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
          TextButton(
            onPressed: _save,
            child: Text(
              _isEdit ? 'Simpan' : 'Tambah',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isEdit)
              Center(
                child: AppAvatar(
                  name: _namaCtrl.text.isEmpty
                      ? widget.existing?.name ?? ''
                      : _namaCtrl.text,
                  radius: 40,
                  imagePath: (widget.existing?.photoPath?.isNotEmpty ?? false)
                      ? widget.existing!.photoPath
                      : null,
                  backgroundColor: AppTheme.primaryGreen.withValues(
                    alpha: 0.15,
                  ),
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            if (_isEdit) const SizedBox(height: 24),
            _section('Identitas Santri'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap *',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nisCtrl,
              decoration: const InputDecoration(
                labelText: 'NIS (Nomor Induk Santri)',
                hintText: 'cth. TH-2024-001',
                prefixIcon: Icon(Icons.badge_rounded),
                helperText: 'Digunakan sebagai identitas login santri',
              ),
            ),
            const SizedBox(height: 12),
            // Jenis Kelamin
            _labelText('Jenis Kelamin'),
            const SizedBox(height: 8),
            Row(
              children: [
                _genderChip('L', 'Laki-laki', Icons.male_rounded),
                const SizedBox(width: 12),
                _genderChip('P', 'Perempuan', Icons.female_rounded),
              ],
            ),
            const SizedBox(height: 20),
            _section('Kelas & Halaqah'),
            const SizedBox(height: 12),
            Consumer<AppProvider>(
              builder: (_, provider, __) => Column(
                children: [
                  // Kelas dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _kelasCtrl.text.isEmpty
                        ? null
                        : _kelasCtrl.text,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kelas',
                      prefixIcon: Icon(Icons.class_rounded),
                    ),
                    hint: const Text('-- Pilih Kelas --'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('-- Belum ditentukan --'),
                      ),
                      ...provider.kelasList.map(
                        (k) => DropdownMenuItem(
                          value: k.nama,
                          child: Text(k.nama),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _kelasCtrl.text = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  // Halaqah dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _halaqahId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Halaqah',
                      prefixIcon: Icon(Icons.groups_rounded),
                    ),
                    hint: const Text('-- Pilih Halaqah --'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('-- Belum ditentukan --'),
                      ),
                      ...provider.halaqahList.map(
                        (h) => DropdownMenuItem(
                          value: h.id,
                          child: Text(h.nama, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _halaqahId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _targetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Target Hafalan',
                      hintText: 'cth. Juz 30 / 5 Juz / 10 Juz',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section('Akun Orang Tua / Wali'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username Login Orang Tua',
                hintText: 'cth. wali-001',
                prefixIcon: Icon(Icons.person_outline_rounded),
                helperText: 'Kosongkan untuk memakai NIS otomatis',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Login Orang Tua',
                hintText: 'minimal 4 karakter',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                helperText: 'Kosongkan untuk memakai NIS otomatis',
              ),
            ),
            const SizedBox(height: 20),
            _section('Data Orang Tua / Wali'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaAyahCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Ayah',
                prefixIcon: Icon(Icons.man_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaIbuCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Ibu',
                prefixIcon: Icon(Icons.woman_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomorHpWaliCtrl,
              decoration: const InputDecoration(
                labelText: 'No. HP Wali',
                hintText: 'cth. 081234567890',
                prefixIcon: Icon(Icons.phone_rounded),
                helperText: 'Digunakan untuk login sebagai orang tua',
              ),
              keyboardType: TextInputType.phone,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 20),
              _section('Status'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statusChip('aktif', 'Aktif', AppTheme.primaryGreen),
                  const SizedBox(width: 12),
                  _statusChip('nonaktif', 'Non-aktif', Colors.grey.shade600),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(
                  _isEdit ? Icons.save_rounded : Icons.person_add_rounded,
                ),
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
    final selected = _jenisKelamin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jenisKelamin = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.primaryGreen : Colors.grey.shade500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade600,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
