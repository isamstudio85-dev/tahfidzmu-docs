import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/santri.dart';
import '../models/halaqah_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/continuation_dialog.dart';
import '../widgets/app_avatar.dart';
import 'santri_detail_screen.dart';
import 'santri_form_screen.dart';

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedHalaqahId;
  bool _showOnlyMine = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canManage = provider.isAdmin || provider.isMusyrif;
    final showAppBar = !widget.hideAppBar && !provider.isAdmin && !provider.isMusyrif;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Daftar Santri')) : null,
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          List<Santri> list;
          if (provider.isMusyrif && _showOnlyMine && provider.linkedMusyrif != null) {
            list = provider.getSantriByMusyrif(provider.linkedMusyrif!.id);
          } else {
            list = provider.santriList;
          }

          final filteredList = _filterSantri(list);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, NIS...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(provider),
                  ],
                ),
              ),

              if (_selectedHalaqahId != null || _selectedHalaqahId == "" || (provider.isMusyrif))
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (provider.isMusyrif)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_showOnlyMine ? 'Santri Saya' : 'Semua Santri', style: const TextStyle(fontSize: 11)),
                            selected: _showOnlyMine,
                            onSelected: (val) => setState(() => _showOnlyMine = val),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            checkmarkColor: AppTheme.primaryGreen,
                            labelStyle: TextStyle(color: _showOnlyMine ? AppTheme.primaryGreen : Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: _showOnlyMine ? AppTheme.primaryGreen : Colors.grey.shade300),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (_selectedHalaqahId != null || _selectedHalaqahId == "")
                        Chip(
                          label: Text(
                            _selectedHalaqahId == ""
                              ? 'Tanpa Halaqah'
                              : 'Halaqah: ${provider.getHalaqahById(_selectedHalaqahId)?.nama ?? ''}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen),
                          ),
                          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          deleteIcon: const Icon(Icons.close, size: 14, color: AppTheme.primaryGreen),
                          onDeleted: () => setState(() => _selectedHalaqahId = null),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),

              if (list.isEmpty)
                _emptyState(canManage, 'Belum ada santri.')
              else if (filteredList.isEmpty)
                Expanded(child: Center(child: Text('Tidak ada santri yang cocok', style: TextStyle(color: Colors.grey.shade500))))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredList.length,
                    itemBuilder: (_, i) => _SantriCard(santri: filteredList[i]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'fab_santri_add',
              onPressed: () => _showAddSantriDialog(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Tambah Santri'),
            )
          : null,
    );
  }

  Widget _buildFilterButton(AppProvider provider) {
    return PopupMenuButton<String?>(
      icon: Icon(Icons.filter_list_rounded, color: _selectedHalaqahId != null || _selectedHalaqahId == "" ? AppTheme.primaryGreen : Colors.grey),
      tooltip: 'Filter Halaqah',
      onSelected: (id) => setState(() => _selectedHalaqahId = id),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: null, child: Text('Semua Halaqah')),
        const PopupMenuItem(value: "", child: Text('Tanpa Halaqah')),
        ...provider.halaqahList.map((h) => PopupMenuItem(value: h.id, child: Text(h.nama))),
      ],
    );
  }

  Widget _emptyState(bool canManage, String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            if (canManage) ...[
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
    );
  }

  List<Santri> _filterSantri(List<Santri> list) {
    return list.where((s) {
      final matchesQuery = s.name.toLowerCase().contains(_query.toLowerCase()) || (s.nis?.contains(_query) ?? false);
      bool matchesHalaqah = true;
      if (_selectedHalaqahId == "") {
        matchesHalaqah = s.halaqahId == null;
      } else if (_selectedHalaqahId != null) {
        matchesHalaqah = s.halaqahId == _selectedHalaqahId;
      }
      return matchesQuery && matchesHalaqah;
    }).toList();
  }

  void _showAddSantriDialog(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SantriFormScreen()));
  }
}

class _SantriCard extends StatelessWidget {
  const _SantriCard({required this.santri});
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final canManage = provider.isAdmin || provider.isMusyrif;
    final halaqah = provider.getHalaqahById(santri.halaqahId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AppAvatar(
                name: santri.name,
                radius: 22,
                imagePath: (santri.photoPath?.isNotEmpty ?? false) ? santri.photoPath : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(santri.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Text(santri.nis ?? '-', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: Colors.grey.shade300, fontSize: 11)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(halaqah?.nama ?? 'Tanpa Halaqah', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri)));
                    if (val == 'delete') _confirmDelete(context, provider, santri);
                    if (val == 'reset') _showResetPasswordDialog(context, provider, santri);
                    if (val == 'setoran') showSetoranOptions(context, santri);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'setoran', child: _MenuAction(Icons.play_circle_fill_rounded, 'Mulai Setoran', AppTheme.primaryGreen)),
                    const PopupMenuItem(value: 'edit', child: _MenuAction(Icons.edit_rounded, 'Edit Profile', Colors.blue)),
                    const PopupMenuItem(value: 'reset', child: _MenuAction(Icons.lock_reset_rounded, 'Reset Sandi', Colors.orange)),
                    const PopupMenuItem(value: 'delete', child: _MenuAction(Icons.delete_outline_rounded, 'Hapus', Colors.red)),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primaryGreen, size: 28),
                  onPressed: () => showSetoranOptions(context, santri),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Santri santri) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Santri?'),
        content: Text('Hapus "${santri.name}" secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () { provider.removeSantri(santri.id); Navigator.pop(ctx); }, child: const Text('Hapus')),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppProvider provider, Santri santri) {
    final passwordCtrl = TextEditingController(text: DbHelper.onlyDigits(santri.nis));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Sandi'),
        content: TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Sandi Baru')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () async {
            await provider.resetPasswordForLinkedId(santri.id, passwordCtrl.text.trim());
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Reset')),
        ],
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 10), Text(label)]);
  }
}
