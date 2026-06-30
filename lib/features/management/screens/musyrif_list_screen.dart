import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/database/db_helper.dart';
import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_form_screen.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_detail_screen.dart';

class MusyrifListScreen extends StatefulWidget {
  const MusyrifListScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  State<MusyrifListScreen> createState() => _MusyrifListScreenState();
}

class _MusyrifListScreenState extends State<MusyrifListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isAdmin = provider.isAdmin;
    final showAppBar = !widget.hideAppBar && !isAdmin && !provider.isMusyrif;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Daftar Musyrif')) : null,
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.musyrifList;
          final filteredList = _filterMusyrif(list);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, NIP, jabatan...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              if (list.isEmpty)
                _emptyState(isAdmin, 'Belum ada musyrif.')
              else if (filteredList.isEmpty)
                Expanded(child: Center(child: Text('Tidak ada musyrif yang cocok', style: TextStyle(color: Colors.grey.shade500))))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredList.length,
                    itemBuilder: (_, i) => _MusyrifCard(
                      musyrif: filteredList[i],
                      santriCount: provider.getSantriByMusyrif(filteredList[i].id).length,
                      halaqahCount: provider.halaqahList.where((h) => h.musyrifId == filteredList[i].id).length,
                      onReset: isAdmin ? () => _showResetPasswordDialog(context, provider, filteredList[i]) : null,
                      onEdit: isAdmin ? () => _showFormDialog(context, filteredList[i]) : null,
                      onDelete: isAdmin ? () => _confirmDelete(context, provider, filteredList[i]) : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'fab_musyrif_add',
              onPressed: () => _showFormDialog(context, null),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Musyrif'),
            )
          : null,
    );
  }

  Widget _emptyState(bool isAdmin, String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Musyrif'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<MusyrifData> _filterMusyrif(List<MusyrifData> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((m) {
      final haystack = [m.nama, m.nip, m.jabatan].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _showFormDialog(BuildContext context, MusyrifData? existing) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => MusyrifFormScreen(existing: existing)));
  }

  void _confirmDelete(BuildContext context, AppProvider provider, MusyrifData m) {
    final halaqahCount = provider.halaqahList.where((h) => h.musyrifId == m.id).length;
    if (halaqahCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${m.nama} masih memiliki $halaqahCount halaqah.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Musyrif?'),
        content: Text('Data "${m.nama}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { provider.removeMusyrif(m.id); Navigator.pop(ctx); },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AppProvider provider, MusyrifData musyrif) {
    final passwordCtrl = TextEditingController(text: DbHelper.onlyDigits(musyrif.nip));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Sandi'),
        content: TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Sandi Baru')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              await provider.resetPasswordForLinkedId(musyrif.id, passwordCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _MusyrifCard extends StatelessWidget {
  const _MusyrifCard({required this.musyrif, required this.santriCount, required this.halaqahCount, this.onEdit, this.onDelete, this.onReset});
  final MusyrifData musyrif; final int santriCount; final int halaqahCount;
  final VoidCallback? onEdit; final VoidCallback? onDelete; final VoidCallback? onReset;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MusyrifDetailScreen(musyrifId: musyrif.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AppAvatar(name: musyrif.nama, radius: 24, imagePath: musyrif.photoPath?.isNotEmpty == true ? musyrif.photoPath : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(musyrif.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${musyrif.jabatan} • ${musyrif.nip ?? '-'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _badge(Icons.groups_rounded, '$halaqahCount', AppTheme.primaryGreen),
                        const SizedBox(width: 6),
                        _badge(Icons.people_alt_rounded, '$santriCount', const Color(0xFF1565C0)),
                        if (!musyrif.isAktif) ...[const SizedBox(width: 6), _badge(Icons.info_outline, 'Non-aktif', Colors.grey)],
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null || onReset != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'edit') onEdit?.call();
                    if (val == 'delete') onDelete?.call();
                    if (val == 'reset') onReset?.call();
                  },
                  itemBuilder: (ctx) => [
                    if (onEdit != null) const PopupMenuItem(value: 'edit', child: _MenuAction(Icons.edit_rounded, 'Edit', AppTheme.primaryGreen)),
                    if (onReset != null) const PopupMenuItem(value: 'reset', child: _MenuAction(Icons.lock_reset_rounded, 'Reset Sandi', Colors.orange)),
                    if (onDelete != null) const PopupMenuItem(value: 'delete', child: _MenuAction(Icons.delete_outline_rounded, 'Hapus', Colors.red)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction(this.icon, this.label, this.color);
  final IconData icon; final String label; final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 10), Text(label)]);
  }
}
