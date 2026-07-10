import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/models/pengawas_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_form_screen.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_detail_screen.dart';

class PengawasListScreen extends StatefulWidget {
  const PengawasListScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  State<PengawasListScreen> createState() => _PengawasListScreenState();
}

class _PengawasListScreenState extends State<PengawasListScreen> {
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
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, username, jabatan...',
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
                _emptyState(isAdmin, 'Belum ada pengawas.')
              else if (filteredList.isEmpty)
                Expanded(child: Center(child: Text('Tidak ada pengawas yang cocok', style: TextStyle(color: Colors.grey.shade500))))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
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

  Widget _emptyState(bool isAdmin, String message) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
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
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PengawasDetailScreen(pengawasId: pengawas.id))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // More compact
        child: Row(
          children: [
            // SQUIRCLE AVATAR
            Container(
              width: 36, // Smaller
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                image: (pengawas.photoPath?.isNotEmpty ?? false)
                    ? DecorationImage(image: NetworkImage(pengawas.photoPath!), fit: BoxFit.cover)
                    : null,
              ),
              child: (pengawas.photoPath?.isEmpty ?? true)
                  ? Center(
                      child: Text(
                        pengawas.nama[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pengawas.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${pengawas.jabatan} • @${pengawas.username}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null || onReset != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune_rounded, size: 18, color: Colors.grey), // Changed
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  if (val == 'edit') onEdit?.call();
                  if (val == 'delete') onDelete?.call();
                  if (val == 'reset') onReset?.call();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16, color: Colors.blue), SizedBox(width: 8), Text('Edit Profile', style: TextStyle(fontSize: 13))])),
                  const PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.vpn_key_rounded, size: 16, color: Colors.orange), SizedBox(width: 8), Text('Reset Sandi', style: TextStyle(fontSize: 13))])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus Akun', style: TextStyle(fontSize: 13))])),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
