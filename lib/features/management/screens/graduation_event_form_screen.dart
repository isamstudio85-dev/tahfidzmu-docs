import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/graduation_event.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class GraduationEventFormScreen extends StatefulWidget {
  const GraduationEventFormScreen({super.key, this.existing});
  final GraduationEvent? existing;

  @override
  State<GraduationEventFormScreen> createState() => _GraduationEventFormScreenState();
}

class _GraduationEventFormScreenState extends State<GraduationEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _requirementsCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _regFeeCtrl;
  late final TextEditingController _gradFeeCtrl;
  String _method = "Tasmi' Sekali Duduk";
  int _sessions = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _gradDate;
  bool _isPublished = false;
  bool _isCertificatesReleased = false;
  String? _bannerPath;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? 'Haflah Takharruj Angkatan...');
    _yearCtrl = TextEditingController(text: widget.existing?.year ?? DateTime.now().year.toString());
    _requirementsCtrl = TextEditingController(text: widget.existing?.requirements ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _regFeeCtrl = TextEditingController(text: (widget.existing?.registrationFee ?? 0).toInt().toString());
    _gradFeeCtrl = TextEditingController(text: (widget.existing?.graduationFee ?? 0).toInt().toString());
    _method = widget.existing?.method ?? "Tasmi' Sekali Duduk";
    _sessions = widget.existing?.sessionsCount ?? 1;
    _startDate = widget.existing?.examStartDate;
    _endDate = widget.existing?.examEndDate;
    _gradDate = widget.existing?.graduationDate;
    _isPublished = widget.existing?.isPublished ?? false;
    _isCertificatesReleased = widget.existing?.isCertificatesReleased ?? false;
    _bannerPath = widget.existing?.bannerPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Tambah Agenda Wisuda' : 'Edit Agenda')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField('Nama Agenda / Haflah', _titleCtrl, 'Contoh: Wisuda Tahfidz 2024'),
            const SizedBox(height: 16),
            _buildField('Tahun', _yearCtrl, 'Tahun wisuda', isNumber: true),
            const SizedBox(height: 24),
            
            _sectionHeader('WAKTU PELAKSANAAN'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _datePickerTile('Mulai Ujian', _startDate, (d) => setState(() => _startDate = d))),
                const SizedBox(width: 12),
                Expanded(child: _datePickerTile('Selesai Ujian', _endDate, (d) => setState(() => _endDate = d))),
              ],
            ),
            const SizedBox(height: 12),
            _datePickerTile('Tanggal Perayaan Wisuda', _gradDate, (d) => setState(() => _gradDate = d)),
            const SizedBox(height: 24),

            _sectionHeader('METODE & SYARAT'),
            const SizedBox(height: 12),
            _buildBannerPicker(),
            const SizedBox(height: 16),
            _buildDropdown('Metode Ujian', ["Tasmi' Sekali Duduk", "Tasmi' Bertahap", "Sima'an Umum"], _method, (v) {
              setState(() {
                _method = v!;
                if (_method == "Tasmi' Sekali Duduk") _sessions = 1;
              });
            }),
            
            if (_method == "Tasmi' Bertahap") ...[
              const SizedBox(height: 16),
              _buildSessionPicker(),
            ],

            const SizedBox(height: 24),
            _sectionHeader('BIAYA OPERASIONAL'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildField('Biaya Daftar', _regFeeCtrl, '0', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildField('Biaya Wisuda', _gradFeeCtrl, '0', isNumber: true)),
              ],
            ),

            const SizedBox(height: 24),
            _buildField('Syarat Kelulusan', _requirementsCtrl, 'Misal: Minimal 2 Juz Mutqin', maxLines: 2),
            const SizedBox(height: 16),
            _buildField('Pengumuman / Deskripsi', _descCtrl, 'Tuliskan informasi atau instruksi untuk santri...', maxLines: 5),
            
            const SizedBox(height: 24),
            _buildPublishSwitch(),
            const SizedBox(height: 12),
            _buildCertificateSwitch(),

            const SizedBox(height: 40),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _save,
                child: const Text('SIMPAN AGENDA'),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Banner Popup Motivasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickBanner,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              image: _bannerPath != null
                  ? DecorationImage(
                      image: _bannerPath!.startsWith('assets/')
                          ? AssetImage(_bannerPath!) as ImageProvider
                          : FileImage(File(_bannerPath!)),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: _bannerPath == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: Colors.grey, size: 32),
                      Text('Upload Gambar Meriah', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const CircleAvatar(backgroundColor: Colors.white70, radius: 12, child: Icon(Icons.close, size: 16, color: Colors.red)),
                      onPressed: () => setState(() => _bannerPath = null),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _bannerPath = picked.path);
    }
  }

  Widget _buildPublishSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isPublished ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _isPublished ? AppTheme.primaryGreen.withValues(alpha: 0.3) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_rounded, color: _isPublished ? AppTheme.primaryGreen : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Publikasikan di Aplikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Jika ON, santri & orang tua bisa melihat agenda ini.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: _isPublished,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (v) => setState(() => _isPublished = v),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCertificatesReleased ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _isCertificatesReleased ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.card_membership_rounded, color: _isCertificatesReleased ? Colors.blue : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bagikan Sertifikat Digital', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Jika ON, santri bisa mengunduh sertifikat.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: _isCertificatesReleased,
            activeThumbColor: Colors.blue,
            onChanged: (v) => setState(() => _isCertificatesReleased = v),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1.1));
  }

  Widget _datePickerTile(String label, DateTime? date, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              date == null ? 'Pilih Tanggal' : '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          validator: (v) => (v == null || v.isEmpty) ? 'Harus diisi' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: current,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Sesi (Kali Duduk)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [1, 2, 3, 5, 10].map((val) => _sessionChip(val)).toList(),
        ),
      ],
    );
  }

  Widget _sessionChip(int val) {
    final isSelected = _sessions == val;
    return ChoiceChip(
      label: Text('$val Sesi'),
      selected: isSelected,
      onSelected: (v) => setState(() => _sessions = val),
      selectedColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final event = GraduationEvent(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text,
      year: _yearCtrl.text,
      examStartDate: _startDate,
      examEndDate: _endDate,
      graduationDate: _gradDate,
      method: _method,
      sessionsCount: _sessions,
      requirements: _requirementsCtrl.text,
      description: _descCtrl.text,
      status: widget.existing?.status ?? 'upcoming',
      isPublished: _isPublished,
      isCertificatesReleased: _isCertificatesReleased,
      registrationFee: double.tryParse(_regFeeCtrl.text) ?? 0,
      graduationFee: double.tryParse(_gradFeeCtrl.text) ?? 0,
      bannerPath: _bannerPath,
    );

    if (widget.existing == null) {
      provider.addGraduationEvent(event);
    } else {
      provider.updateGraduationEvent(event.id, event);
    }
    Navigator.pop(context);
  }
}
