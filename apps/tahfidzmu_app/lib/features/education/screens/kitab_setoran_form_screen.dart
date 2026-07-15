import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';

class KitabSetoranFormScreen extends StatefulWidget {
  final Santri? santri;
  final Kitab? initialKitab;

  const KitabSetoranFormScreen({
    super.key,
    this.santri,
    this.initialKitab,
  });

  @override
  State<KitabSetoranFormScreen> createState() => _KitabSetoranFormScreenState();
}

class _KitabSetoranFormScreenState extends State<KitabSetoranFormScreen> {
  Santri? _selectedSantri;
  Kitab? _selectedKitab;
  String _type = 'ziyadah'; // 'ziyadah' | 'murojaah'
  int _startUnit = 1;
  int _endUnit = 1;
  double _score = 100.0;
  String _notes = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSantri = widget.santri;
    _selectedKitab = widget.initialKitab;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      
      // Auto-select first student if none provided (for musyrif)
      if (_selectedSantri == null) {
        final list = provider.isMusyrif && provider.linkedMusyrif != null
            ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
            : provider.santriList;
        if (list.isNotEmpty) {
          setState(() => _selectedSantri = list.first);
        }
      }

      // Auto-select first kitab if none provided
      if (_selectedKitab == null && provider.kitabList.isNotEmpty) {
        setState(() {
          _selectedKitab = provider.kitabList.first;
          _updateUnitsForSelectedKitab();
        });
      } else if (_selectedKitab != null) {
        _updateUnitsForSelectedKitab();
      }
    });
  }

  void _updateUnitsForSelectedKitab() {
    if (_selectedKitab == null) return;
    final provider = context.read<AppProvider>();
    final sId = _selectedSantri?.id;
    if (sId != null) {
      final progress = provider.getKitabProgressForSantri(sId)[_selectedKitab!.id];
      setState(() {
        _startUnit = (progress != null) ? (progress.endUnit + 1).clamp(1, _selectedKitab!.totalUnit) : 1;
        _endUnit = _startUnit;
      });
    }
  }

  Future<void> _saveSetoran() async {
    if (_selectedSantri == null || _selectedKitab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih santri dan kitab terlebih dahulu')),
      );
      return;
    }

    if (_startUnit > _endUnit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor mulai tidak boleh lebih besar dari nomor selesai')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();
    final musyrifId = provider.isMusyrif ? (provider.linkedMusyrif?.id ?? 'admin') : 'admin';

    final id = provider.firestore.collection('temp').doc().id;
    final record = KitabSetoranRecord(
      id: id,
      santriId: _selectedSantri!.id,
      kitabId: _selectedKitab!.id,
      namaKitab: _selectedKitab!.nama,
      tipeUnit: _selectedKitab!.tipeUnit,
      startUnit: _startUnit,
      endUnit: _endUnit,
      type: _type,
      score: _score,
      notes: _notes,
      date: DateTime.now(),
      musyrifId: musyrifId,
    );

    try {
      await provider.addKitabSetoran(_selectedSantri!.id, record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran kitab berhasil disimpan')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final studentList = provider.isMusyrif && provider.linkedMusyrif != null
        ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
        : provider.santriList;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('INPUT SETORAN KITAB'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Santri Card Picker
                  if (widget.santri == null && studentList.isNotEmpty) ...[
                    Text(
                      'PILIH SANTRI',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Santri>(
                          value: _selectedSantri,
                          isExpanded: true,
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          items: studentList.map((s) {
                            return DropdownMenuItem<Santri>(
                              value: s,
                              child: Text(s.name, style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSantri = val;
                              _updateUnitsForSelectedKitab();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Selected Santri Info (if provided)
                  if (_selectedSantri != null) ...[
                    Card(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: AppAvatar(
                          name: _selectedSantri!.name,
                          imagePath: _selectedSantri!.photoPath,
                          radius: 20,
                        ),
                        title: Text(
                          _selectedSantri!.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'NIS: ${_selectedSantri!.nis}',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Pilih Kitab
                  Text(
                    'PILIH KITAB',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Kitab>(
                        value: _selectedKitab,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                        items: provider.kitabList.map((k) {
                          return DropdownMenuItem<Kitab>(
                            value: k,
                            child: Text(
                              '${k.nama} (${k.tipeUnit.toUpperCase()})',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedKitab = val;
                            _updateUnitsForSelectedKitab();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_selectedKitab != null) ...[
                    // Tipe Setoran
                    Text(
                      'TIPE SETORAN',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Container(
                              alignment: Alignment.center,
                              child: Text('Ziyadah', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            ),
                            selected: _type == 'ziyadah',
                            onSelected: (val) => setState(() => _type = 'ziyadah'),
                            selectedColor: AppTheme.primaryGreen,
                            labelStyle: TextStyle(color: _type == 'ziyadah' ? Colors.white : (isDark ? Colors.white : Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: Container(
                              alignment: Alignment.center,
                              child: Text("Muroja'ah", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            ),
                            selected: _type == 'murojaah',
                            onSelected: (val) => setState(() => _type = 'murojaah'),
                            selectedColor: Colors.orange[800],
                            labelStyle: TextStyle(color: _type == 'murojaah' ? Colors.white : (isDark ? Colors.white : Colors.black)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Range Input (Dari & Sampai)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DARI NOMOR',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _startUnit,
                                    isExpanded: true,
                                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                    items: List.generate(_selectedKitab!.totalUnit, (index) => index + 1).map((num) {
                                      return DropdownMenuItem<int>(
                                        value: num,
                                        child: Text('$num', style: GoogleFonts.poppins()),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _startUnit = val;
                                          if (_endUnit < _startUnit) _endUnit = _startUnit;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SAMPAI NOMOR',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _endUnit,
                                    isExpanded: true,
                                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                    items: List.generate(_selectedKitab!.totalUnit - _startUnit + 1, (index) => index + _startUnit).map((num) {
                                      return DropdownMenuItem<int>(
                                        value: num,
                                        child: Text('$num', style: GoogleFonts.poppins()),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _endUnit = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nilai / Score
                    Text(
                      'NILAI (0 - 100)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _score,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: _score.round().toString(),
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) => setState(() => _score = val),
                    ),
                    Center(
                      child: Text(
                        _score.round().toString(),
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notes / Catatan
                    Text(
                      'CATATAN TAMBAHAN (OPSIONAL)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (val) => _notes = val,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: 'Tulis evaluasi hafalan di sini...',
                        filled: true,
                        fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveSetoran,
                        child: Text(
                          'SIMPAN SETORAN',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
