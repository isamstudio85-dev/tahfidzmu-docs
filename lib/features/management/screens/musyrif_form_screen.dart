import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
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
  bool _isKoordinator = false;
  List<String> _managedHalaqahIds = [];

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
    _isKoordinator = m?.isKoordinator ?? false;
    _managedHalaqahIds = List.from(m?.managedHalaqahIds ?? []);
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

  Map<String, String> _parseSmartRawText(String text) {
    String name = '';
    String id = '';
    String email = '';
    
    final ignoreSet = {
      'kartu', 'santri', 'musyrif', 'pesantren', 'halaqah', 'tahfidz', 'app', 'digital', 'pondok', 'wisuda', 'ujian',
      'id', 'nis', 'nip', 'nama', 'name', 'email', 'kelas', 'class', 'school', 'card', 'member'
    };

    bool isHeaderOrLabel(String word) {
      final w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      return ignoreSet.contains(w);
    }

    String cleanValue(String val) {
      var s = val.trim();
      s = s.replaceFirst(RegExp(r'^[:\-\s|]+'), '');
      return s.trim();
    }

    final lines = text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    if (lines.length > 1) {
      for (var line in lines) {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          final label = line.substring(0, colonIndex).trim().toLowerCase();
          final value = cleanValue(line.substring(colonIndex + 1));
          
          if (label.contains('nama') || label.contains('name')) {
            name = value;
            continue;
          } else if (label.contains('nip') || label.contains('id') || label.contains('nis') || label.contains('number')) {
            id = value;
            continue;
          } else if (label.contains('email')) {
            email = value;
            continue;
          }
        }
        
        final cleanLine = line.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
        final words = cleanLine.split(RegExp(r'\s+'));
        
        if (words.every((w) => isHeaderOrLabel(w))) {
          continue;
        }

        final digits = line.replaceAll(RegExp(r'[^0-9]'), '');
        final letters = line.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        
        if (digits.length > letters.length && digits.length >= 3) {
          id = cleanValue(line);
        } else if (letters.length > digits.length && letters.length >= 3) {
          if (!isHeaderOrLabel(words.first)) {
            name = cleanValue(line);
          }
        }
      }
    } else {
      final parts = text.split(RegExp(r'[\-|/|,]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        for (var part in parts) {
          final cleanPart = part.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
          final words = cleanPart.split(RegExp(r'\s+'));
          if (words.every((w) => isHeaderOrLabel(w))) continue;

          final digits = part.replaceAll(RegExp(r'[^0-9]'), '');
          final letters = part.replaceAll(RegExp(r'[^a-zA-Z]'), '');

          if (digits.length > letters.length && digits.length >= 3) {
            id = cleanValue(part);
          } else {
            name = cleanValue(part);
          }
        }
      } else {
        final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
        final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (digits.length > letters.length) {
          id = text;
        } else {
          name = text;
        }
      }
    }

    return {
      'name': name.trim(),
      'id': id.trim(),
      'email': email.trim(),
    };
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
        isKoordinator: _isKoordinator,
        managedHalaqahIds: _managedHalaqahIds,
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
    _processScannedRaw(rawString);
  }

  Future<void> _processScannedRaw(String rawString) async {
    final trimmed = rawString.trim();

    String parsedNama = '';
    String parsedId = trimmed; // fallback is raw string
    String parsedEmail = '';
    String parsedHp = '';
    String parsedJabatan = '';
    String parsedJk = 'L';

    // 1. Coba parse sebagai JSON
    try {
      final data = jsonDecode(trimmed);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('nama')) parsedNama = data['nama'].toString();
        if (data.containsKey('name')) parsedNama = data['name'].toString();
        
        if (data.containsKey('nip')) parsedId = data['nip'].toString();
        if (data.containsKey('id')) parsedId = data['id'].toString();
        
        if (data.containsKey('email')) parsedEmail = data['email'].toString();
        
        if (data.containsKey('nomorHp')) parsedHp = data['nomorHp'].toString();
        if (data.containsKey('hp')) parsedHp = data['hp'].toString();
        
        if (data.containsKey('jabatan')) parsedJabatan = data['jabatan'].toString();
        
        if (data.containsKey('jenisKelamin')) {
          final gk = data['jenisKelamin'].toString().toUpperCase();
          if (gk == 'L' || gk == 'P') parsedJk = gk;
        }
      }
    } catch (_) {
      // 2. Coba parse sebagai URL dengan query parameters
      bool parsedAsUrl = false;
      try {
        final uri = Uri.parse(trimmed);
        if (uri.hasQuery) {
          final params = uri.queryParameters;
          if (params.containsKey('nama')) parsedNama = params['nama']!;
          if (params.containsKey('name')) parsedNama = params['name']!;
          
          if (params.containsKey('nip')) parsedId = params['nip']!;
          if (params.containsKey('id')) parsedId = params['id']!;
          
          if (params.containsKey('email')) parsedEmail = params['email']!;
          
          if (params.containsKey('nomorHp')) parsedHp = params['nomorHp']!;
          if (params.containsKey('hp')) parsedHp = params['hp']!;
          
          if (params.containsKey('jabatan')) parsedJabatan = params['jabatan']!;
          
          if (params.containsKey('jenisKelamin')) {
            final gk = params['jenisKelamin']!.toUpperCase();
            if (gk == 'L' || gk == 'P') parsedJk = gk;
          }
          parsedAsUrl = true;
        }
      } catch (_) {}

      // 3. Fallback: Smart Regex/Word parser if not URL
      if (!parsedAsUrl) {
        final smartData = _parseSmartRawText(trimmed);
        parsedNama = smartData['name'] ?? '';
        parsedId = smartData['id'] ?? trimmed;
        parsedEmail = smartData['email'] ?? '';
      }
    }

    if (!mounted) return;

    // Tampilkan Dialog Pratinjau
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScanPreviewDialog(
        initialId: parsedId,
        name: parsedNama,
        email: parsedEmail,
        kelas: '',
        hp: parsedHp,
        tanggalLahir: '',
        jabatan: parsedJabatan,
        isSantri: false,
      ),
    );

    if (result == null) return;

    if (result['action'] == 'rescan') {
      _scanExistingCard();
    } else if (result['action'] == 'confirm') {
      setState(() {
        _nipCtrl.text = result['id'].toString();
        if (parsedNama.isNotEmpty) _namaCtrl.text = parsedNama;
        if (parsedEmail.isNotEmpty) _emailCtrl.text = parsedEmail;
        if (parsedHp.isNotEmpty) _hpCtrl.text = parsedHp;
        if (parsedJabatan.isNotEmpty) _jabatanCtrl.text = parsedJabatan;
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
    final provider = context.watch<AppProvider>();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Box A: QR Code otomatis bawaan aplikasi
                Expanded(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: Center(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nipCtrl,
                        builder: (context, val, _) {
                          final currentId = val.text.trim();
                          return currentId.isNotEmpty
                              ? QrImageView(
                                  data: currentId,
                                  version: QrVersions.auto,
                                  size: 90.0,
                                  backgroundColor: Colors.white,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.qr_code_2_rounded, color: Colors.grey, size: 40),
                                    const SizedBox(height: 4),
                                    Text('QR Otomatis', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                  ],
                                );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Box B: Upload Foto profil identik size
                Expanded(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _photoPath != null
                            ? (_photoPath!.startsWith('http')
                                ? Image.network(_photoPath!, fit: BoxFit.cover)
                                : Image.file(File(_photoPath!), fit: BoxFit.cover))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryGreen.withValues(alpha: 0.6), size: 32),
                                  const SizedBox(height: 4),
                                  Text('Unggah Foto', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
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
            _section('Hak Akses (Peran)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isKoordinator ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isKoordinator ? AppTheme.primaryGreen.withValues(alpha: 0.2) : Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: _isKoordinator,
                activeThumbColor: AppTheme.primaryGreen,
                title: const Text('Angkat Sebagai Administrator (Koordinator)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Koordinator dapat menginput santri baru dan mengelola beberapa halaqah sekaligus.', style: TextStyle(fontSize: 10)),
                onChanged: (v) => setState(() => _isKoordinator = v),
                contentPadding: EdgeInsets.zero,
              ),
            ),

            if (_isKoordinator) ...[
              const SizedBox(height: 16),
              _labelText('Tanggung Jawab Halaqah'),
              const SizedBox(height: 8),
              _buildManagedHalaqahSelector(provider),
            ],

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

  Widget _buildManagedHalaqahSelector(AppProvider provider) {
    if (provider.halaqahList.isEmpty) {
      return const Text('Belum ada data halaqah', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.halaqahList.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, index) {
          final h = provider.halaqahList[index];
          final isChecked = _managedHalaqahIds.contains(h.id);
          return CheckboxListTile(
            value: isChecked,
            activeColor: AppTheme.primaryGreen,
            title: Text(h.nama, style: const TextStyle(fontSize: 13)),
            subtitle: Text(provider.getMusyrifById(h.musyrifId)?.nama ?? 'Tanpa Pembimbing', style: const TextStyle(fontSize: 10)),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _managedHalaqahIds.add(h.id);
                } else {
                  _managedHalaqahIds.remove(h.id);
                }
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        },
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
            const SizedBox(height: 8),
            Text(
              'Catatan: Edit nama/data lainnya di form utama setelah disimpan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            
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
