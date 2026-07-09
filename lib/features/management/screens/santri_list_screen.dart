import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/continuation_dialog.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_form_screen.dart';

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key, this.hideAppBar = false, this.showOnlyMine});
  final bool hideAppBar;
  final bool? showOnlyMine;

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedHalaqahId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canManage = provider.isAdmin;
    final showAppBar = !widget.hideAppBar;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Match Laporan background
      appBar: showAppBar ? AppBar(title: const Text('Daftar Santri')) : null,
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          List<Santri> list;
          bool effectiveOnlyMine = widget.showOnlyMine ?? false;

          if (provider.isMusyrif && effectiveOnlyMine && provider.linkedMusyrif != null) {
            list = provider.getSantriByMusyrif(provider.linkedMusyrif!.id);
          } else {
            list = provider.santriList;
          }

          final filteredList = _filterSantri(list);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Cari nama, NIS, kelas...',
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

              // Active Halaqah Filter Chip
              if (_selectedHalaqahId != null || _selectedHalaqahId == "")
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        _emptyState(canManage, 'Belum ada santri.'),
                      ],
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(child: Text('Tidak ada santri yang cocok', style: TextStyle(color: Colors.grey.shade500))),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
                      itemBuilder: (_, i) => _SantriListItem(santri: filteredList[i]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'fab_santri_add_${widget.showOnlyMine}',
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
      final matchesQuery = s.name.toLowerCase().contains(_query.toLowerCase()) || 
                           (s.nis?.contains(_query) ?? false) ||
                           (s.kelas?.toLowerCase().contains(_query.toLowerCase()) ?? false);
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

class _SantriListItem extends StatelessWidget {
  const _SantriListItem({required this.santri});
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canManage = provider.isAdmin;
    final halaqah = provider.getHalaqahById(santri.halaqahId);
    final todayStatus = provider.getTodaySantriStatus(santri.id);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // More compact
        child: Row(
          children: [
            // SQUIRCLE AVATAR
            Container(
              width: 36, // Slightly smaller
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8), 
                image: (santri.photoPath?.isNotEmpty ?? false)
                    ? DecorationImage(image: NetworkImage(santri.photoPath!), fit: BoxFit.cover)
                    : null,
              ),
              child: (santri.photoPath?.isEmpty ?? true)
                  ? Center(
                      child: Text(
                        santri.name[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 12),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    santri.name, 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 1), // Tighter
                  Row(
                    children: [
                      if (santri.nis != null && santri.nis!.isNotEmpty) ...[
                        Text(santri.nis!, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontFamily: 'monospace')),
                        const SizedBox(width: 6),
                        Text('•', style: TextStyle(color: Colors.grey.shade300, fontSize: 10)),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          halaqah?.nama ?? 'Tanpa Halaqah', 
                          style: TextStyle(color: AppTheme.primaryGreen.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w500), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (todayStatus != null) ...[
              _buildMiniStatusBadge(todayStatus),
              const SizedBox(width: 8),
            ],
            if (canManage)
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune_rounded, size: 18, color: Colors.grey), // Changed from three dots
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
                icon: const Icon(Icons.play_circle_outline_rounded, color: AppTheme.primaryGreen, size: 24),
                onPressed: () => showSetoranOptions(context, santri),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
          ],
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
    final passwordCtrl = TextEditingController(text: santri.nis?.replaceAll(RegExp(r'\D+'), '') ?? '');
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

  Widget _buildMiniStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'setoran': color = Colors.green; break;
      case 'ditunda': color = Colors.grey; break;
      case 'sakit': color = Colors.orange; break;
      case 'izin': color = Colors.blue; break;
      case 'alfa': color = Colors.red; break;
      default: return const SizedBox.shrink();
    }

    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
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
