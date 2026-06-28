import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/musyrif_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import 'musyrif_form_screen.dart';

class MusyrifListScreen extends StatelessWidget {
  const MusyrifListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Musyrif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Tambah Musyrif',
            onPressed: () => _showFormDialog(context, null),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.musyrifList;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off_rounded,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada musyrif',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _showFormDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Musyrif'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _MusyrifCard(
              musyrif: list[i],
              santriCount: provider.getSantriByMusyrif(list[i].id).length,
              halaqahCount: provider.halaqahList
                  .where((h) => h.musyrifId == list[i].id)
                  .length,
              onReset: provider.isAdmin
                  ? () => _showResetPasswordDialog(context, provider, list[i])
                  : null,
              onEdit: () => _showFormDialog(context, list[i]),
              onDelete: () => _confirmDelete(context, provider, list[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_musyrif_add',
        onPressed: () => _showFormDialog(context, null),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Musyrif'),
      ),
    );
  }

  void _showFormDialog(BuildContext context, MusyrifData? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MusyrifFormScreen(existing: existing)),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    MusyrifData m,
  ) {
    // Check if musyrif has halaqah
    final halaqahCount = provider.halaqahList
        .where((h) => h.musyrifId == m.id)
        .length;
    if (halaqahCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${m.nama} masih memiliki $halaqahCount halaqah. Pindahkan halaqah terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Musyrif?'),
        content: Text('Data "${m.nama}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.removeMusyrif(m.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    AppProvider provider,
    MusyrifData musyrif,
  ) {
    final passwordCtrl = TextEditingController(text: musyrif.nip ?? '');
    String? error;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Reset Password Musyrif'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final newPassword = passwordCtrl.text.trim();
                if (newPassword.length < 4) {
                  setSt(() => error = 'Password minimal 4 karakter.');
                  return;
                }
                final ok = await provider.resetPasswordForLinkedId(
                  musyrif.id,
                  newPassword,
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password musyrif berhasil direset.'),
                    ),
                  );
                } else {
                  setSt(() => error = 'Gagal mereset password.');
                }
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MusyrifCard extends StatelessWidget {
  const _MusyrifCard({
    required this.musyrif,
    required this.santriCount,
    required this.halaqahCount,
    required this.onEdit,
    required this.onDelete,
    this.onReset,
  });

  final MusyrifData musyrif;
  final int santriCount;
  final int halaqahCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppAvatar(
              name: musyrif.nama,
              radius: 28,
              imagePath: musyrif.photoPath?.isNotEmpty == true
                  ? musyrif.photoPath
                  : null,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
              foregroundColor: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          musyrif.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!musyrif.isAktif)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Non-aktif',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${musyrif.jabatan} · ${musyrif.lembaga}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (musyrif.nomorHp.isNotEmpty)
                    Text(
                      musyrif.nomorHp,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _badge(
                        Icons.groups_rounded,
                        '$halaqahCount Halaqah',
                        AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      _badge(
                        Icons.people_alt_rounded,
                        '$santriCount Santri',
                        const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (onReset != null)
                  IconButton(
                    icon: const Icon(Icons.lock_reset_rounded, size: 20),
                    color: Colors.orange.shade700,
                    tooltip: 'Reset Password',
                    onPressed: onReset,
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: AppTheme.primaryGreen,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: Colors.red,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
