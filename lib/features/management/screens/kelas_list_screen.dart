import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/models/kelas_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class KelasListScreen extends StatelessWidget {
  const KelasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Kelas'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.kelasList;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada data kelas', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _showForm(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kelas'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final k = list[i];
              final santriCount = provider.santriList.where((s) => s.kelas == k.nama).length;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.meeting_room_rounded, color: AppTheme.primaryGreen, size: 20),
                  ),
                  title: Text(k.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$santriCount Santri', style: const TextStyle(fontSize: 12)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') _showForm(context, k);
                      if (val == 'delete') _confirmDelete(context, provider, k, santriCount);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kelas'),
      ),
    );
  }

  void _showForm(BuildContext context, KelasData? existing) {
    final ctrl = TextEditingController(text: existing?.nama);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Tambah Kelas' : 'Edit Kelas'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nama Kelas', hintText: 'cth: 7A, 10-IPA'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              final p = context.read<AppProvider>();
              if (existing == null) {
                p.addKelas(KelasData(id: DateTime.now().millisecondsSinceEpoch.toString(), nama: ctrl.text.trim()));
              } else {
                p.updateKelas(existing.id, KelasData(id: existing.id, nama: ctrl.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, KelasData k, int count) {
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelas ${k.nama} masih memiliki $count santri.'), backgroundColor: Colors.red),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kelas?'),
        content: Text('Hapus kelas "${k.nama}" secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.removeKelas(k.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
