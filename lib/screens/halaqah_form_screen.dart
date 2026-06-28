import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/halaqah_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Full-page form for adding or editing a HalaqahData.
class HalaqahFormScreen extends StatefulWidget {
  const HalaqahFormScreen({super.key, this.existing});
  final HalaqahData? existing;

  @override
  State<HalaqahFormScreen> createState() => _HalaqahFormScreenState();
}

class _HalaqahFormScreenState extends State<HalaqahFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaCtrl;
  late final TextEditingController _targetJuzCtrl;
  late final TextEditingController _kapasitasCtrl;
  late final TextEditingController _deskripsiCtrl;
  late final TextEditingController _jadwalCtrl;
  late final TextEditingController _lokasiCtrl;

  String _level = HalaqahData.levelOptions.first;
  String? _musyrifId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _namaCtrl = TextEditingController(text: h?.nama ?? '');
    _targetJuzCtrl = TextEditingController(text: h?.targetJuz ?? '');
    _kapasitasCtrl = TextEditingController(
      text: h?.kapasitas?.toString() ?? '',
    );
    _deskripsiCtrl = TextEditingController(text: h?.deskripsi ?? '');
    _jadwalCtrl = TextEditingController(text: h?.jadwal ?? '');
    _lokasiCtrl = TextEditingController(text: h?.lokasi ?? '');
    _level = h?.level ?? HalaqahData.levelOptions.first;
    _musyrifId = h?.musyrifId;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _targetJuzCtrl.dispose();
    _kapasitasCtrl.dispose();
    _deskripsiCtrl.dispose();
    _jadwalCtrl.dispose();
    _lokasiCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final h = HalaqahData(
      id:
          widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaCtrl.text.trim(),
      musyrifId: _musyrifId,
      level: _level,
      kapasitas: int.tryParse(_kapasitasCtrl.text.trim()),
      targetJuz: _targetJuzCtrl.text.trim().isEmpty
          ? null
          : _targetJuzCtrl.text.trim(),
      deskripsi: _deskripsiCtrl.text.trim().isEmpty
          ? null
          : _deskripsiCtrl.text.trim(),
      jadwal: _jadwalCtrl.text.trim().isEmpty ? null : _jadwalCtrl.text.trim(),
      lokasi: _lokasiCtrl.text.trim().isEmpty ? null : _lokasiCtrl.text.trim(),
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
        child: Consumer<AppProvider>(
          builder: (_, provider, __) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section('Informasi Halaqah'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Halaqah *',
                  hintText: 'cth. Halaqah Al-Ikhlas',
                  prefixIcon: Icon(Icons.groups_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              // Level
              _labelText('Level'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HalaqahData.levelOptions.map((l) {
                  final sel = _level == l;
                  return GestureDetector(
                    onTap: () => setState(() => _level = l),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade300,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        l,
                        style: TextStyle(
                          color: sel
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade600,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _section('Musyrif Pembimbing'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _musyrifId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Musyrif / Musyrifah',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                hint: const Text('-- Pilih Musyrif --'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('-- Belum ditentukan --'),
                  ),
                  ...provider.musyrifList
                      .where((m) => m.isAktif)
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.nama, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ],
                onChanged: (v) => setState(() => _musyrifId = v),
              ),
              const SizedBox(height: 20),
              _section('Detail Halaqah'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _kapasitasCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kapasitas (santri)',
                        prefixIcon: Icon(Icons.people_rounded),
                        hintText: 'cth. 15',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _targetJuzCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Target Juz',
                        prefixIcon: Icon(Icons.auto_stories_rounded),
                        hintText: 'cth. Juz 30',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jadwalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jadwal',
                  hintText: 'cth. Senin & Rabu, 15.30–17.00',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lokasiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lokasi',
                  hintText: 'cth. Aula Utama Lt. 1',
                  prefixIcon: Icon(Icons.location_on_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiCtrl,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(
                    _isEdit ? Icons.save_rounded : Icons.group_add_rounded,
                  ),
                  label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Halaqah'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
}
