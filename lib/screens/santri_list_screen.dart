import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/continuation_dialog.dart';
import '../widgets/app_avatar.dart';
import 'santri_detail_screen.dart';
import 'santri_form_screen.dart';

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key});

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppProvider>().isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Santri'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'Tambah Santri',
              onPressed: () => _showAddSantriDialog(context),
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.isMusyrif && provider.linkedMusyrif != null
              ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
              : provider.santriList;

          final filteredList = _filterSantri(list);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _query = value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama, kelas, NIS',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (list.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada santri',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showAddSantriDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Santri'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Tidak ada santri yang cocok dengan pencarian',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filteredList.length,
                    itemBuilder: (_, i) {
                      // Lazy load dengan delayed rendering
                      return AnimatedOpacity(
                        opacity: 1,
                        duration: Duration(milliseconds: 300 + (i * 50)),
                        child: _SantriCard(santri: filteredList[i]),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab_santri_add',
              onPressed: () => _showAddSantriDialog(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Tambah Santri'),
            )
          : null,
    );
  }

  List<Santri> _filterSantri(List<Santri> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((santri) {
      final haystack = [
        santri.name,
        santri.nis,
        santri.kelas,
        santri.halaqahId,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _showAddSantriDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SantriFormScreen()),
    );
  }
}

class _SantriCard extends StatelessWidget {
  const _SantriCard({required this.santri});
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SantriDetailScreen(santriId: santri.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppAvatar(name: santri.name, radius: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      santri.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (santri.kelas != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        santri.kelas!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            santri.estimatedJuz >= 1
                                ? '≈ ${santri.estimatedJuz.toStringAsFixed(1)} Juz'
                                : '< 1 Juz',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${santri.totalSetoranCount} setoran',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.play_circle_filled_rounded,
                  size: 36,
                  color: AppTheme.primaryGreen,
                ),
                tooltip: 'Mulai Setoran',
                onPressed: () => showSetoranOptions(context, santri),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
