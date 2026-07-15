import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_form_screen.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_detail_screen.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';
import 'package:tahfidz_app/core/widgets/user_avatar_with_frame.dart';

class MusyrifListScreen extends StatefulWidget {
  const MusyrifListScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  State<MusyrifListScreen> createState() => _MusyrifListScreenState();
}

class _MusyrifListScreenState extends State<MusyrifListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<AppProvider>();
    final isAdmin = provider.isAdmin;
    final showAppBar = !widget.hideAppBar;

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
                child: GamifiedSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  hintText: 'Cari nama, NIP, jabatan...',
                ),
              ),
              if (list.isEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          child: _emptyStateNoExpanded(isAdmin, 'Belum ada musyrif.'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: const CustomScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          child: Center(child: Text('Tidak ada musyrif yang cocok', style: TextStyle(color: Colors.grey))),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: filteredList.length,
                      itemBuilder: (_, i) => _MusyrifListItem(
                        musyrif: filteredList[i],
                        santriCount: provider.getSantriByMusyrif(filteredList[i].id).length,
                        halaqahCount: provider.halaqahList.where((h) => h.musyrifId == filteredList[i].id).length,
                        onReset: isAdmin ? () => _showResetPasswordDialog(context, provider, filteredList[i]) : null,
                        onEdit: isAdmin ? () => _showFormDialog(context, filteredList[i]) : null,
                        onDelete: isAdmin ? () => _confirmDelete(context, provider, filteredList[i]) : null,
                      ),
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

  Widget _emptyStateNoExpanded(bool isAdmin, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
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
    final passwordCtrl = TextEditingController(text: musyrif.nip?.replaceAll(RegExp(r'\D+'), '') ?? '');
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

class _MusyrifListItem extends StatelessWidget {
  const _MusyrifListItem({required this.musyrif, required this.santriCount, required this.halaqahCount, this.onEdit, this.onDelete, this.onReset});
  final MusyrifData musyrif; final int santriCount; final int halaqahCount;
  final VoidCallback? onEdit; final VoidCallback? onDelete; final VoidCallback? onReset;
  
  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF1565C0);
    return GamifiedListItem(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MusyrifDetailScreen(musyrifId: musyrif.id))),
      accentColor: accentColor,
      leading: UserAvatarWithFrame(
        photoPath: musyrif.photoPath,
        name: musyrif.nama,
        size: 48,
        fallbackColor: accentColor,
      ),
      title: musyrif.nama,
      subtitle: '${musyrif.jabatan} • ${musyrif.nip ?? "NIP -"}',
      stats: [
        GamifiedStatItem(
          icon: Icons.groups_rounded,
          label: 'Halaqah',
          value: '$halaqahCount',
          color: AppTheme.primaryGreen,
        ),
        GamifiedStatItem(
          icon: Icons.people_alt_rounded,
          label: 'Santri',
          value: '$santriCount',
          color: accentColor,
        ),
      ],
      trailing: (onEdit != null || onDelete != null || onReset != null)
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
            )
          : null,
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
