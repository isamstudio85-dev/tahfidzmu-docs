import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class JuzSelectorGrid extends StatefulWidget {
  const JuzSelectorGrid({
    super.key,
    required this.initialJuz,
    required this.onSelectionChanged,
  });

  final List<int> initialJuz;
  final ValueChanged<List<int>> onSelectionChanged;

  @override
  State<JuzSelectorGrid> createState() => _JuzSelectorGridState();
}

class _JuzSelectorGridState extends State<JuzSelectorGrid> {
  late List<int> _selectedJuz;

  @override
  void initState() {
    super.initState();
    _selectedJuz = List.from(widget.initialJuz);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hafalan yang Sudah Ada',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Pilih Juz yang sudah dihafal sepenuhnya sebelum menggunakan aplikasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Divider(),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 30,
              itemBuilder: (context, i) {
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
                      _selectedJuz.sort();
                    });
                    widget.onSelectionChanged(_selectedJuz);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
                      ),
                    ),
                    child: Text(
                      juz.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Selesai'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
