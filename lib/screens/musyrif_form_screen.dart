import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/musyrif_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';

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
  late final TextEditingController _jabatanCtrl;
  late final TextEditingController _hpCtrl;
  late final TextEditingController _catatanCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String _jenisKelamin = 'L';
  String _status = 'aktif';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _namaCtrl = TextEditingController(text: m?.nama ?? '');
    _nipCtrl = TextEditingController(text: m?.nip ?? '');
    _jabatanCtrl = TextEditingController(text: m?.jabatan ?? '');
    _hpCtrl = TextEditingController(text: m?.nomorHp ?? '');
    _catatanCtrl = TextEditingController(text: m?.catatan ?? '');
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _jenisKelamin = m?.jenisKelamin ?? 'L';
    _status = m?.status ?? 'aktif';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nipCtrl.dispose();
    _jabatanCtrl.dispose();
    _hpCtrl.dispose();
    _catatanCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final pesantrenName = provider.pesantrenName.isNotEmpty
        ? provider.pesantrenName
        : 'Halaqah Tahfidz';
    final m = MusyrifData(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaCtrl.text.trim(),
      nip: _nipCtrl.text.trim().isEmpty ? null : _nipCtrl.text.trim(),
      jenisKelamin: _jenisKelamin,
      jabatan: _jabatanCtrl.text.trim().isEmpty
          ? (_jenisKelamin == 'P' ? 'Musyrifah' : 'Musyrif')
          : _jabatanCtrl.text.trim(),
      lembaga: pesantrenName,
      nomorHp: _hpCtrl.text.trim(),
      status: _status,
      catatan: _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim(),
      photoPath: widget.existing?.photoPath,
    );
    _isEdit
        ? provider.updateMusyrifData(m.id, m)
        : provider.addMusyrif(
            m,
            username: _usernameCtrl.text.trim().isEmpty
                ? null
                : _usernameCtrl.text.trim(),
            password: _passwordCtrl.text.trim().isEmpty
                ? null
                : _passwordCtrl.text.trim(),
          );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Musyrif' : 'Tambah Musyrif'),
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
            // Avatar preview
            Center(
              child: AppAvatar(
                name: _namaCtrl.text.isEmpty ? '?' : _namaCtrl.text,
                radius: 40,
                imagePath: widget.existing?.photoPath,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                foregroundColor: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            _section('Identitas Musyrif'),
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
            TextFormField(
              controller: _nipCtrl,
              decoration: const InputDecoration(
                labelText: 'NIP (Nomor Induk Pegawai)',
                hintText: 'cth. NIP-001',
                prefixIcon: Icon(Icons.badge_rounded),
                helperText: 'Digunakan sebagai identitas login musyrif',
              ),
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
            const SizedBox(height: 20),
            _section('Jabatan'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jabatanCtrl,
              decoration: InputDecoration(
                labelText: 'Jabatan',
                hintText: _jenisKelamin == 'P'
                    ? 'cth. Musyrifah, Koordinator Tahfidz...'
                    : 'cth. Musyrif, Kepala Tahfidz, Mudir...',
                prefixIcon: const Icon(Icons.work_rounded),
                helperText: 'Jabatan bebas, tulis sesuai kebutuhan',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),
            _section('Akun Login'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username Login Musyrif',
                hintText: 'cth. musyrif-01',
                prefixIcon: Icon(Icons.person_outline_rounded),
                helperText: 'Kosongkan untuk memakai NIP otomatis',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Login Musyrif',
                hintText: 'minimal 4 karakter',
                prefixIcon: Icon(Icons.lock_outline_rounded),
                helperText: 'Kosongkan untuk memakai NIP otomatis',
              ),
            ),
            const SizedBox(height: 20),
            _section('Kontak'),
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
              controller: _catatanCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
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
                label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Musyrif'),
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
