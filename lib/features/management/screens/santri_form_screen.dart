import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/widgets/juz_selector_grid.dart';
import 'package:tahfidz_app/features/management/widgets/santri_photo_selector.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';

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
  late final TextEditingController _kelasCtrl;
  late final TextEditingController _namaOrangTuaCtrl;
  late final TextEditingController _nomorHpWaliCtrl;
  late final TextEditingController _tanggalLahirCtrl;

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String? _jenisKelamin;
  String? _halaqahId;
  String? _photoPath;
  String? _targetJuz;
  String _status = 'aktif';
  List<int> _initialJuz = [];
  bool _showAccountInfo = false;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _namaCtrl = TextEditingController(text: s?.name ?? '');
    _nisCtrl = TextEditingController(text: s?.nis ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _kelasCtrl = TextEditingController(text: s?.kelas ?? '');
    _namaOrangTuaCtrl = TextEditingController(text: s?.namaOrangTua ?? s?.namaAyah ?? s?.namaIbu ?? '');
    _nomorHpWaliCtrl = TextEditingController(text: s?.nomorHpWali ?? '');
    _tanggalLahirCtrl = TextEditingController(text: s?.tanggalLahir ?? '');

    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();

    _jenisKelamin = s?.jenisKelamin;
    _halaqahId = s?.halaqahId;
    _photoPath = s?.photoPath;
    _status = s?.status ?? 'aktif';
    _initialJuz = s?.initialMemorizedJuz != null ? List.from(s!.initialMemorizedJuz) : [];

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
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nisCtrl.dispose();
    _emailCtrl.dispose();
    _kelasCtrl.dispose();
    _namaOrangTuaCtrl.dispose();
    _nomorHpWaliCtrl.dispose();
    _tanggalLahirCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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

  void _showKelasPicker() {
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
            Text('Pilih Kelas', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('-- Belum ditentukan --'),
                    onTap: () { setState(() => _kelasCtrl.text = ''); Navigator.pop(context); },
                    trailing: _kelasCtrl.text.isEmpty ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                  ),
                  ...provider.kelasList.map((k) => ListTile(
                    title: Text(k.nama),
                    onTap: () { setState(() => _kelasCtrl.text = k.nama); Navigator.pop(context); },
                    trailing: _kelasCtrl.text == k.nama ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetJuzPicker() {
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
                    return _juzChip(null, '--', isSelected: _targetJuz == null, onTap: () { setState(() => _targetJuz = null); Navigator.pop(context); });
                  }
                  final val = '$i Juz';
                  return _juzChip(val, i.toString(), isSelected: _targetJuz == val, onTap: () { setState(() => _targetJuz = val); Navigator.pop(context); });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInitialHafalanPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JuzSelectorGrid(
        initialJuz: _initialJuz,
        onSelectionChanged: (selectedList) {
          setState(() {
            _initialJuz = selectedList;
          });
        },
      ),
    );
  }

  Widget _juzChip(String? value, String label, {required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true); // Need to add this state
    final provider = context.read<AppProvider>();
    
    try {
      if (_isEdit) {
        await provider.updateSantriInfo(
          widget.existing!.id,
          name: _namaCtrl.text.trim(),
          nis: _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          jenisKelamin: _jenisKelamin,
          halaqahId: _halaqahId,
          kelas: _kelasCtrl.text.trim().isEmpty ? null : _kelasCtrl.text.trim(),
          namaOrangTua: _namaOrangTuaCtrl.text.trim().isEmpty ? null : _namaOrangTuaCtrl.text.trim(),
          nomorHpWali: _nomorHpWaliCtrl.text.trim().isEmpty ? null : _nomorHpWaliCtrl.text.trim(),
          targetHafalan: _targetJuz,
          photoPath: _photoPath,
          tanggalLahir: _tanggalLahirCtrl.text.trim().isEmpty ? null : _tanggalLahirCtrl.text.trim(),
          status: _status,
          initialMemorizedJuz: _initialJuz,
        );
      } else {
        await provider.addSantri(
          _namaCtrl.text.trim(),
          nis: _nisCtrl.text.trim().isEmpty ? null : _nisCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          jenisKelamin: _jenisKelamin,
          halaqahId: _halaqahId,
          kelas: _kelasCtrl.text.trim().isEmpty ? null : _kelasCtrl.text.trim(),
          namaOrangTua: _namaOrangTuaCtrl.text.trim().isEmpty ? null : _namaOrangTuaCtrl.text.trim(),
          nomorHpWali: _nomorHpWaliCtrl.text.trim().isEmpty ? null : _nomorHpWaliCtrl.text.trim(),
          targetHafalan: _targetJuz,
          photoPath: _photoPath,
          tanggalLahir: _tanggalLahirCtrl.text.trim().isEmpty ? null : _tanggalLahirCtrl.text.trim(),
          initialMemorizedJuz: _initialJuz,
          username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
          password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
        );
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
    _processScannedRaw(rawString);
  }

  Future<void> _processScannedRaw(String rawString) async {
    final trimmed = rawString.trim();

    String parsedName = '';
    String parsedId = trimmed; // fallback is raw string
    String parsedEmail = '';
    String parsedKelas = '';
    String parsedOrtu = '';
    String parsedHp = '';
    String parsedDob = '';
    String parsedJk = 'L';

    // 1. Coba parse sebagai JSON
    try {
      final data = jsonDecode(trimmed);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('nama')) parsedName = data['nama'].toString();
        if (data.containsKey('name')) parsedName = data['name'].toString();
        
        if (data.containsKey('nis')) parsedId = data['nis'].toString();
        if (data.containsKey('id')) parsedId = data['id'].toString();
        
        if (data.containsKey('email')) parsedEmail = data['email'].toString();
        if (data.containsKey('kelas')) parsedKelas = data['kelas'].toString();
        
        if (data.containsKey('namaOrangTua')) parsedOrtu = data['namaOrangTua'].toString();
        if (data.containsKey('ortu')) parsedOrtu = data['ortu'].toString();
        
        if (data.containsKey('nomorHpWali')) parsedHp = data['nomorHpWali'].toString();
        if (data.containsKey('nomorHp')) parsedHp = data['nomorHp'].toString();
        if (data.containsKey('hp')) parsedHp = data['hp'].toString();
        
        if (data.containsKey('tanggalLahir')) parsedDob = data['tanggalLahir'].toString();
        if (data.containsKey('tglLahir')) parsedDob = data['tglLahir'].toString();
        if (data.containsKey('dob')) parsedDob = data['dob'].toString();
        
        if (data.containsKey('jenisKelamin')) {
          final gk = data['jenisKelamin'].toString().toUpperCase();
          if (gk == 'L' || gk == 'P') parsedJk = gk;
        }
      }
    } catch (_) {
      // 2. Coba parse sebagai URL dengan query parameters
      try {
        final uri = Uri.parse(trimmed);
        if (uri.hasQuery) {
          final params = uri.queryParameters;
          if (params.containsKey('nama')) parsedName = params['nama']!;
          if (params.containsKey('name')) parsedName = params['name']!;
          
          if (params.containsKey('nis')) parsedId = params['nis']!;
          if (params.containsKey('id')) parsedId = params['id']!;
          
          if (params.containsKey('email')) parsedEmail = params['email']!;
          if (params.containsKey('kelas')) parsedKelas = params['kelas']!;
          
          if (params.containsKey('namaOrangTua')) parsedOrtu = params['namaOrangTua']!;
          if (params.containsKey('ortu')) parsedOrtu = params['ortu']!;
          
          if (params.containsKey('nomorHpWali')) parsedHp = params['nomorHpWali']!;
          if (params.containsKey('nomorHp')) parsedHp = params['nomorHp']!;
          if (params.containsKey('hp')) parsedHp = params['hp']!;
          
          if (params.containsKey('tanggalLahir')) parsedDob = params['tanggalLahir']!;
          if (params.containsKey('tglLahir')) parsedDob = params['tglLahir']!;
          if (params.containsKey('dob')) parsedDob = params['dob']!;
          
          if (params.containsKey('jenisKelamin')) {
            final gk = params['jenisKelamin']!.toUpperCase();
            if (gk == 'L' || gk == 'P') parsedJk = gk;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    // Tampilkan Dialog Pratinjau
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScanPreviewDialog(
        initialId: parsedId,
        name: parsedName,
        email: parsedEmail,
        kelas: parsedKelas,
        hp: parsedHp,
        tanggalLahir: parsedDob,
        jabatan: '',
        isSantri: true,
      ),
    );

    if (result == null) return;

    if (result['action'] == 'rescan') {
      _scanExistingCard();
    } else if (result['action'] == 'confirm') {
      setState(() {
        _nisCtrl.text = result['id'].toString();
        if (parsedName.isNotEmpty) _namaCtrl.text = parsedName;
        if (parsedEmail.isNotEmpty) _emailCtrl.text = parsedEmail;
        if (parsedKelas.isNotEmpty) _kelasCtrl.text = parsedKelas;
        if (parsedOrtu.isNotEmpty) _namaOrangTuaCtrl.text = parsedOrtu;
        if (parsedHp.isNotEmpty) _nomorHpWaliCtrl.text = parsedHp;
        if (parsedDob.isNotEmpty) _tanggalLahirCtrl.text = parsedDob;
        _jenisKelamin = parsedJk;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data kartu berhasil disalin ke form!'), backgroundColor: Colors.green),
        );
      }
    }
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
            SantriPhotoSelector(
              photoPath: _photoPath,
              name: _namaCtrl.text.isEmpty ? (_isEdit ? widget.existing!.name : '?') : _namaCtrl.text,
              onPhotoSelected: (path) => setState(() => _photoPath = path),
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
                label: const Text('Scan & Salin Kartu Digital Santri', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showKelasPicker,
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _kelasCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kelas',
                          prefixIcon: Icon(Icons.meeting_room_rounded),
                          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
                          hintText: '-- Pilih Kelas --',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      _genderChip('L', 'L', Icons.male_rounded),
                      const SizedBox(width: 8),
                      _genderChip('P', 'P', Icons.female_rounded),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nisCtrl,
              decoration: const InputDecoration(labelText: 'NIS (Nomor Induk Santri)', hintText: 'cth. TH-2024-001', prefixIcon: Icon(Icons.badge_rounded)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tanggalLahirCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Tanggal Lahir',
                hintText: 'Pilih tanggal lahir santri',
                prefixIcon: Icon(Icons.cake_rounded),
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _tanggalLahirCtrl.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                  });
                }
              },
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
            const SizedBox(height: 24),

            _section('Progress Hafalan'),
            const SizedBox(height: 12),
            // Initial Hafalan (Juz selection)
            InkWell(
              onTap: _showInitialHafalanPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.history_edu_rounded, color: _initialJuz.isEmpty ? Colors.grey : AppTheme.primaryGreen),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hafalan yang Sudah Ada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            _initialJuz.isEmpty ? 'Belum ada hafalan tercatat' : 'Sudah hafal ${_initialJuz.length} Juz (${_initialJuz.join(', ')})',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Custom Target Juz Picker
            InkWell(
              onTap: _showTargetJuzPicker,
              child: IgnorePointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Target Hafalan Akhir',
                    prefixIcon: const Icon(Icons.flag_rounded),
                    suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                    hintText: _targetJuz ?? '-- Pilih Target (Juz) --',
                    floatingLabelBehavior: _targetJuz != null ? FloatingLabelBehavior.always : null,
                  ),
                  controller: TextEditingController(text: _targetJuz),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _section('Kontak & Orang Tua'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaOrangTuaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Orang Tua / Wali', prefixIcon: Icon(Icons.family_restroom_rounded)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomorHpWaliCtrl,
              decoration: const InputDecoration(labelText: 'No. HP Wali', hintText: 'cth. 081234567890', prefixIcon: Icon(Icons.phone_rounded)),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'santri@example.com', prefixIcon: Icon(Icons.email_rounded)),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 24),
            InkWell(
              onTap: () => setState(() => _showAccountInfo = !_showAccountInfo),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text('Pengaturan Akun', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
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
                onPressed: _isSaving ? null : _save,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                label: Text(_isSaving ? 'Menyimpan...' : (_isEdit ? 'Simpan Perubahan' : 'Tambah Santri')),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryGreen, letterSpacing: 0.5)),
      const Divider(),
    ],
  );

  Widget _labelText(String t) => Text(t, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500));

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _jenisKelamin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _jenisKelamin = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppTheme.primaryGreen : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppTheme.primaryGreen : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? AppTheme.primaryGreen : Colors.grey.shade600, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 12)),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Center(child: Text(label, style: TextStyle(color: selected ? color : Colors.grey.shade600, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontSize: 13))),
        ),
      ),
    );
  }
}

class _ScanPreviewDialog extends StatefulWidget {
  final String initialId;
  final String name;
  final String email;
  final String kelas;
  final String hp;
  final String tanggalLahir;
  final String jabatan;
  final bool isSantri;

  const _ScanPreviewDialog({
    required this.initialId,
    required this.name,
    required this.email,
    required this.kelas,
    required this.hp,
    required this.tanggalLahir,
    required this.jabatan,
    required this.isSantri,
  });

  @override
  State<_ScanPreviewDialog> createState() => _ScanPreviewDialogState();
}

class _ScanPreviewDialogState extends State<_ScanPreviewDialog> {
  late final TextEditingController _idCtrl;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.initialId);
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pratinjau Hasil Pindai',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryGreen),
            ),
            const SizedBox(height: 16),
            
            // Realtime QR code generator based on editable ID
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _idCtrl,
              builder: (context, val, _) {
                final currentId = val.text.trim();
                return currentId.isNotEmpty
                    ? QrImageView(
                        data: currentId,
                        version: QrVersions.auto,
                        size: 140.0,
                        backgroundColor: Colors.white,
                      )
                    : Container(
                        height: 140,
                        width: 140,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.grey),
                      );
              },
            ),
            const SizedBox(height: 16),
            
            // Editable ID Field
            TextFormField(
              controller: _idCtrl,
              decoration: InputDecoration(
                labelText: widget.isSantri ? 'ID Kartu (NIS) *' : 'ID Kartu (NIP) *',
                hintText: 'Edit jika ID tidak sesuai',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            // Scanned details list
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoRow('Nama', widget.name),
                  if (widget.email.isNotEmpty) _infoRow('Email', widget.email),
                  if (widget.isSantri && widget.kelas.isNotEmpty) _infoRow('Kelas', widget.kelas),
                  if (!widget.isSantri && widget.jabatan.isNotEmpty) _infoRow('Jabatan', widget.jabatan),
                  if (widget.hp.isNotEmpty) _infoRow('No. HP', widget.hp),
                  if (widget.tanggalLahir.isNotEmpty) _infoRow('Tgl Lahir', widget.tanggalLahir),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context, {'action': 'rescan'}),
                    icon: const Icon(Icons.replay_rounded, size: 18, color: Colors.orange),
                    label: const Text('Pindai Ulang', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'action': 'confirm',
                        'id': _idCtrl.text.trim(),
                      });
                    },
                    child: const Text('Simpan ke Form', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
