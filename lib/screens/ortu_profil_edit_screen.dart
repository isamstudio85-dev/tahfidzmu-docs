import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Full-page edit screen for OrangTua editing their own wali info.
/// Fields: Nama Ayah, Nama Ibu, No. HP Wali.
/// NOT editable: Nama Santri, Kelas, Halaqah, NIS — managed by admin.
class OrangTuaProfilEditScreen extends StatefulWidget {
  const OrangTuaProfilEditScreen({super.key});

  @override
  State<OrangTuaProfilEditScreen> createState() =>
      _OrangTuaProfilEditScreenState();
}

class _OrangTuaProfilEditScreenState extends State<OrangTuaProfilEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ayahCtrl;
  late final TextEditingController _ibuCtrl;
  late final TextEditingController _hpCtrl;

  @override
  void initState() {
    super.initState();
    final santri = context.read<AppProvider>().linkedSantri;
    _ayahCtrl = TextEditingController(text: santri?.namaAyah ?? '');
    _ibuCtrl = TextEditingController(text: santri?.namaIbu ?? '');
    _hpCtrl = TextEditingController(text: santri?.nomorHpWali ?? '');
  }

  @override
  void dispose() {
    _ayahCtrl.dispose();
    _ibuCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final santri = provider.linkedSantri;
    if (santri == null) return;
    provider.updateSantriInfo(
      santri.id,
      namaAyah: _ayahCtrl.text.trim().isEmpty ? null : _ayahCtrl.text.trim(),
      namaIbu: _ibuCtrl.text.trim().isEmpty ? null : _ibuCtrl.text.trim(),
      nomorHpWali: _hpCtrl.text.trim().isEmpty ? null : _hpCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Informasi Wali'),
        actions: [
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Informasi wali dapat diedit di sini. Data santri seperti '
                      'nama dan halaqah dikelola oleh admin.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _sectionLabel('Informasi Wali'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ayahCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Ayah',
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'cth. Ahmad Fauzi',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _ibuCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Ibu',
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'cth. Siti Rahayu',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),

            _sectionLabel('Kontak'),
            const SizedBox(height: 12),

            TextFormField(
              controller: _hpCtrl,
              decoration: const InputDecoration(
                labelText: 'No. HP / WhatsApp Wali',
                prefixIcon: Icon(Icons.phone_rounded),
                hintText: 'cth. 0812-3456-7890',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

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
