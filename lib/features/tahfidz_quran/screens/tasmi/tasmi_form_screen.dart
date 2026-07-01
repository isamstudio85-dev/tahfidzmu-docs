import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/surah_model.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_reader_screen.dart';

class TasmiFormScreen extends StatefulWidget {
  const TasmiFormScreen({super.key, this.santri});
  final Santri? santri;

  @override
  State<TasmiFormScreen> createState() => _TasmiFormScreenState();
}

class _TasmiFormScreenState extends State<TasmiFormScreen> {
  Santri? _selectedSantri;
  final List<int> _selectedJuz = [];
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());

  @override
  void initState() {
    super.initState();
    _selectedSantri = widget.santri;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ujian Tasmi\' / Wisuda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Santri yang diuji', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSantriPicker(provider),
            const SizedBox(height: 24),
            const Text('Juz yang akan diuji', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildJuzGrid(),
            const SizedBox(height: 24),
            const Text('Tahun Wisuda', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _yearCtrl,
              decoration: const InputDecoration(hintText: 'Misal: 2024'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canStart() ? _startExam : null,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('MULAI UJIAN TASMI\''),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSantriPicker(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Santri>(
          isExpanded: true,
          value: _selectedSantri,
          hint: const Text('Pilih Santri'),
          items: provider.santriList.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
          onChanged: (v) => setState(() => _selectedSantri = v),
        ),
      ),
    );
  }

  Widget _buildJuzGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1,
      ),
      itemCount: 30,
      itemBuilder: (ctx, i) {
        final juz = i + 1;
        final isSelected = _selectedJuz.contains(juz);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedJuz.remove(juz);
              } else {
                _selectedJuz.add(juz);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200),
            ),
            alignment: Alignment.center,
            child: Text('$juz', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ),
        );
      },
    );
  }

  bool _canStart() => _selectedSantri != null && _selectedJuz.isNotEmpty && _yearCtrl.text.isNotEmpty;

  void _startExam() {
    final provider = context.read<AppProvider>();
    
    provider.startTasmiSession(
      santri: _selectedSantri!,
      juzNumbers: _selectedJuz,
      year: _yearCtrl.text,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuranReaderScreen()),
    );
  }
}
