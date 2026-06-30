import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';

/// Full-page edit screen for musyrif editing their own profile.
/// Fields: Nama, Jabatan, No. HP only (no Lembaga — managed by Admin).
class MusyrifProfilEditScreen extends StatefulWidget {
  const MusyrifProfilEditScreen({super.key});

  @override
  State<MusyrifProfilEditScreen> createState() =>
      _MusyrifProfilEditScreenState();
}

class _MusyrifProfilEditScreenState extends State<MusyrifProfilEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _hpCtrl;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final linked = provider.linkedMusyrif;
    _namaCtrl = TextEditingController(
      text:
          linked?.nama ??
          (provider.musyrif == 'Musyrif' ? '' : provider.musyrif),
    );
    _hpCtrl = TextEditingController(text: linked?.nomorHp ?? provider.nomorHp);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final linked = provider.linkedMusyrif;
    if (linked != null) {
      provider.updateMusyrifData(
        linked.id,
        linked.copyWith(
          nama: _namaCtrl.text.trim(),
          nomorHp: _hpCtrl.text.trim(),
        ),
      );
    } else {
      provider.updateMusyrifInfo(
        _namaCtrl.text.trim(),
        provider.lembaga, // lembaga unchanged — managed by admin
        jabatan: provider.jabatan, // jabatan unchanged — managed by admin
        nomorHp: _hpCtrl.text.trim(),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
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
            // ── Avatar preview ────────────────────────────────────────────
            Consumer<AppProvider>(
              builder: (_, p, __) {
                final linked = p.linkedMusyrif;
                final photo = linked?.photoPath ?? p.musyrifPhoto;
                final currentName = linked?.nama ?? p.musyrif;
                return Center(
                  child: AppAvatar(
                    name: _namaCtrl.text.isEmpty ? currentName : _namaCtrl.text,
                    radius: 40,
                    imagePath: photo.isNotEmpty ? photo : null,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.15,
                    ),
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Identitas ─────────────────────────────────────────────────
            _sectionLabel('Identitas'),
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
            const SizedBox(height: 24),

            // ── Kontak ────────────────────────────────────────────────────
            _sectionLabel('Kontak'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hpCtrl,
              decoration: const InputDecoration(
                labelText: 'No. HP / WhatsApp',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _save,
              child: const Text('Simpan Perubahan'),
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
