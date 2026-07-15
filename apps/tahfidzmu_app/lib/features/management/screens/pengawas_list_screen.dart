import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';
import 'package:tahfidz_app/core/widgets/user_avatar_with_frame.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_form_screen.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_detail_screen.dart';

class PengawasListScreen extends StatefulWidget {
  const PengawasListScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  State<PengawasListScreen> createState() => _PengawasListScreenState();
}

class _PengawasListScreenState extends State<PengawasListScreen> with AutomaticKeepAliveClientMixin {
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
      appBar: showAppBar ? AppBar(title: const Text('Daftar Pengawas')) : null,
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.pengawasList;
          final filteredList = _filterPengawas(list);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GamifiedSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  hintText: 'Cari nama, username, jabatan...',
                ),
              ),
              if (list.isEmpty)
                _emptyStateNoExpanded(isAdmin, 'Belum ada pengawas.')
              else if (filteredList.isEmpty)
                const Expanded(child: Center(child: Text('Tidak ada pengawas yang cocok', style: TextStyle(color: Colors.grey))))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredList.length,
                    itemBuilder: (_, i) => _PengawasListItem(
                      pengawas: filteredList[i],
                      onReset: isAdmin ? () => _showResetPasswordDialog(context, provider, filteredList[i]) : null,
                      onEdit: isAdmin ? () => _showFormDialog(context, provider, filteredList[i]) : null,
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
              heroTag: 'fab_pengawas_add',
              onPressed: () => _showFormDialog(context, provider, null),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Tambah Pengawas'),
            )
          : null,
    );
  }

  Widget _emptyStateNoExpanded(bool isAdmin, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showFormDialog(context, context.read<AppProvider>(), null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Pengawas'),
            ),
          ],
        ],
      ),
    );
  }

  List<PengawasData> _filterPengawas(List<PengawasData> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((p) {
      final haystack = [p.nama, p.username, p.jabatan].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _showFormDialog(BuildContext context, AppProvider provider, PengawasData? existing) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PengawasFormScreen(existing: existing)));
  }

  void _showResetPasswordDialog(BuildContext context, AppProvider provider, PengawasData pengawas) {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Sandi Pengawas'),
        content: TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Sandi Baru')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (passwordCtrl.text.trim().isEmpty) return;
              await provider.resetPasswordForLinkedId(pengawas.id, passwordCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, PengawasData pengawas) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengawas?'),
        content: Text('Akun "${pengawas.nama}" akan dihapus permanen dari sistem.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.removePengawas(pengawas.id, pengawas.username);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _PengawasListItem extends StatelessWidget {
  const _PengawasListItem({required this.pengawas, this.onEdit, this.onDelete, this.onReset});
  final PengawasData pengawas;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.orange;
    return GamifiedListItem(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PengawasDetailScreen(pengawasId: pengawas.id))),
      accentColor: accentColor,
      leading: UserAvatarWithFrame(
        photoPath: pengawas.photoPath,
        name: pengawas.nama,
        size: 48,
        fallbackColor: accentColor,
      ),
      title: pengawas.nama,
      subtitle: '${pengawas.jabatan} • @${pengawas.username}',
      stats: [
        GamifiedStatItem(
          icon: Icons.security_rounded,
          label: 'Akses',
          value: 'Guardian',
          color: accentColor,
        ),
        const GamifiedStatItem(
          icon: Icons.remove_red_eye_rounded,
          label: 'Status',
          value: 'Aktif',
          color: AppTheme.primaryGreen,
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
                if (onEdit != null) const PopupMenuItem(value: 'edit', child: _MenuAction(Icons.edit_rounded, 'Edit Profile', Colors.blue)),
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
