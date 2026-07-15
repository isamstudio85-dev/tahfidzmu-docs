import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'kitab_setoran_form_screen.dart';

class KitabListScreen extends StatefulWidget {
  const KitabListScreen({super.key});

  @override
  State<KitabListScreen> createState() => _KitabListScreenState();
}

class _KitabListScreenState extends State<KitabListScreen> {
  Santri? _selectedSantri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      if (provider.isOrangTua) {
        setState(() => _selectedSantri = provider.linkedSantri);
      } else {
        setState(() => _selectedSantri = provider.activeSetoranSantri);
      }

      // If still null and it's a Musyrif, select the first student from their list
      if (_selectedSantri == null && provider.isMusyrif) {
        final studentList = provider.linkedMusyrif != null
            ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
            : provider.santriList;
        if (studentList.isNotEmpty) {
          setState(() {
            _selectedSantri = studentList.first;
            provider.startListeningToSingleSantri(_selectedSantri!.id);
          });
        }
      }
    });
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
        title: const Text('HAFALAN KITAB & HADITS'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Selector (for Musyrif/Admin)
          if (!provider.isOrangTua && studentList.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILIH SANTRI UNTUK PROGRESS HAFALAN',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Santri>(
                        value: _selectedSantri,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                        items: studentList.map((s) {
                          return DropdownMenuItem<Santri>(
                            value: s,
                            child: Text(s.name, style: GoogleFonts.poppins(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSantri = val);
                            provider.startListeningToSingleSantri(val.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Kitab List
          Expanded(
            child: provider.kitabList.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada kitab yang ditambahkan oleh admin.',
                      style: GoogleFonts.poppins(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.kitabList.length,
                    itemBuilder: (context, index) {
                      final kitab = provider.kitabList[index];
                      final progress = _selectedSantri != null
                          ? provider.getKitabProgressForSantri(_selectedSantri!.id)[kitab.id]
                          : null;

                      final double percentage = progress != null && kitab.totalUnit > 0
                          ? (progress.endUnit / kitab.totalUnit).clamp(0.0, 1.0)
                          : 0.0;

                      final String unitName = kitab.tipeUnit == 'bait'
                          ? 'Bait'
                          : kitab.tipeUnit == 'hadits'
                              ? 'Hadits'
                              : kitab.tipeUnit == 'halaman'
                                  ? 'Halaman'
                                  : 'Nomor';

                      return Card(
                        color: isDark ? AppTheme.darkSurface : Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KitabDetailScreen(
                                  kitab: kitab,
                                  santri: _selectedSantri,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.book_rounded,
                                      color: Colors.orange[800],
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            kitab.nama,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            kitab.deskripsi.isEmpty ? 'Matan & Hafalan Pilihan' : kitab.deskripsi,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        unitName.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Progress bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress: ${progress?.endUnit ?? 0} / ${kitab.totalUnit} $unitName',
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${(percentage * 100).round()}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (provider.isMusyrif || provider.isAdmin)
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryGreen,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KitabSetoranFormScreen(
                      santri: _selectedSantri,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: Text('SETOR HAFALAN', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

class KitabDetailScreen extends StatelessWidget {
  final Kitab kitab;
  final Santri? santri;

  const KitabDetailScreen({
    super.key,
    required this.kitab,
    this.santri,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String unitName = kitab.tipeUnit == 'bait'
        ? 'Bait'
        : kitab.tipeUnit == 'hadits'
            ? 'Hadits'
            : kitab.tipeUnit == 'halaman'
                ? 'Halaman'
                : 'Nomor';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(kitab.nama.toUpperCase()),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: provider.getCollection('kitab').doc(kitab.id).collection('content').orderBy('index').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Teks Kitab Belum Tersedia',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin belum mengunggah konten teks untuk kitab ini. Anda dapat mencatat hafalan secara langsung menggunakan Mode Cepat.',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (provider.isMusyrif || provider.isAdmin)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KitabSetoranFormScreen(
                                santri: santri,
                                initialKitab: kitab,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_task_rounded),
                        label: Text(
                          'Input Setoran (Mode Cepat)',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final idx = data['index'] ?? (index + 1);
              final text = data['text'] ?? '';
              final translation = data['translation'] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$unitName $idx',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (text.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        text,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          height: 1.8,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (translation.isNotEmpty)
                    Text(
                      translation,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: (provider.isMusyrif || provider.isAdmin)
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryGreen,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KitabSetoranFormScreen(
                      santri: santri,
                      initialKitab: kitab,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: Text('SETOR HAFALAN', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
