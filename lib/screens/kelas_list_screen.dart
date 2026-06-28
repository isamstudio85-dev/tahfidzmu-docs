import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/kelas_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class KelasListScreen extends StatelessWidget {
  const KelasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KelasFormScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (_, provider, __) {
          final list = provider.kelasList;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.class_rounded,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kelas',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KelasFormScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kelas'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final k = list[i];
              final santriCount = provider.santriList
                  .where((s) => s.kelas == k.nama)
                  .length;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  title: Text(
                    k.nama,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (k.tingkat != null)
                        Text(
                          'Tingkat: ${k.tingkat}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (k.waliKelas != null)
                        Text(
                          'Wali Kelas: ${k.waliKelas}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      Text(
                        '$santriCount santri',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        color: AppTheme.primaryGreen,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KelasFormScreen(existing: k),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                        ),
                        color: Colors.red,
                        onPressed: () => _confirmDelete(context, provider, k),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_kelas_add',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KelasFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kelas'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, KelasData k) {
    final count = provider.santriList.where((s) => s.kelas == k.nama).length;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${k.nama}" masih memiliki $count santri. Pindahkan santri terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kelas?'),
        content: Text('Kelas "${k.nama}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.removeKelas(k.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Kelas Form Screen ──────────────────────────────────────────────────────────

class KelasFormScreen extends StatefulWidget {
  const KelasFormScreen({super.key, this.existing});
  final KelasData? existing;

  @override
  State<KelasFormScreen> createState() => _KelasFormScreenState();
}

class _KelasFormScreenState extends State<KelasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _waliCtrl;
  String? _tingkat;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final k = widget.existing;
    _namaCtrl = TextEditingController(text: k?.nama ?? '');
    _waliCtrl = TextEditingController(text: k?.waliKelas ?? '');
    _tingkat = k?.tingkat;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _waliCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final k = KelasData(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaCtrl.text.trim(),
      tingkat: _tingkat,
      waliKelas: _waliCtrl.text.trim().isEmpty ? null : _waliCtrl.text.trim(),
    );
    final provider = context.read<AppProvider>();
    _isEdit ? provider.updateKelas(k.id, k) : provider.addKelas(k);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kelas' : 'Tambah Kelas'),
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
            Text(
              'Informasi Kelas',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.primaryGreen,
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas *',
                hintText: 'cth. Kelas 1A, Kelas VII, Tahfidz Intensif',
                prefixIcon: Icon(Icons.class_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _tingkat,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tingkat',
                prefixIcon: Icon(Icons.stairs_rounded),
              ),
              hint: const Text('-- Pilih Tingkat --'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('-- Tidak ditentukan --'),
                ),
                ...KelasData.tingkatOptions.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                ),
              ],
              onChanged: (v) => setState(() => _tingkat = v),
            ),
            const SizedBox(height: 12),
            Consumer<AppProvider>(
              builder: (_, provider, __) => DropdownButtonFormField<String>(
                initialValue: _waliCtrl.text.isEmpty ? null : _waliCtrl.text,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Wali Kelas',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                hint: const Text('-- Pilih Wali Kelas --'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('-- Belum ditentukan --'),
                  ),
                  ...provider.musyrifList
                      .where((m) => m.isAktif)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.nama,
                          child: Text(m.nama, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: (v) => setState(() => _waliCtrl.text = v ?? ''),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded),
                label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Kelas'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
