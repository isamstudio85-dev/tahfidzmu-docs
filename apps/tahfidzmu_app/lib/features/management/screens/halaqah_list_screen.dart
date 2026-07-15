import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/management/screens/halaqah_form_screen.dart';

class HalaqahListScreen extends StatelessWidget {
  const HalaqahListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Halaqah')),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.halaqahList;
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => await provider.setupFirestoreListeners(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_off_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Belum ada halaqah', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (provider.isAdmin)
                            FilledButton.icon(onPressed: () => _showForm(context, null), icon: const Icon(Icons.add), label: const Text('Tambah Halaqah')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final isAdmin = provider.isAdmin;
          return RefreshIndicator(
            onRefresh: () async => await provider.setupFirestoreListeners(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final h = list[i];
                final musyrif = provider.getMusyrifById(h.musyrifId);
                final santriCount = provider.getSantriByHalaqah(h.id).length;
                return _HalaqahCard(
                  halaqah: h,
                  musyrifNama: musyrif?.nama,
                  santriCount: santriCount,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _HalaqahDetailScreen(halaqahId: h.id))),
                  onEdit: isAdmin ? () => _showForm(context, h) : null,
                  onDelete: isAdmin ? () => _confirmDelete(context, provider, h, santriCount) : null,
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, _) => provider.isAdmin
            ? FloatingActionButton.extended(
                heroTag: 'fab_halaqah_add_list',
                onPressed: () => _showForm(context, null),
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Tambah Halaqah'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _showForm(BuildContext context, HalaqahData? existing) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HalaqahFormScreen(existing: existing)));
  }

  void _confirmDelete(BuildContext context, AppProvider provider, HalaqahData h, int santriCount) {
    if (santriCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${h.nama}" masih memiliki $santriCount santri.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Halaqah?'),
        content: Text('Hapus "${h.nama}" secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () { provider.removeHalaqah(h.id); Navigator.pop(ctx); }, child: const Text('Hapus')),
        ],
      ),
    );
  }
}

class _HalaqahCard extends StatelessWidget {
  const _HalaqahCard({required this.halaqah, this.musyrifNama, required this.santriCount, required this.onTap, this.onEdit, this.onDelete});
  final HalaqahData halaqah; final String? musyrifNama; final int santriCount; final VoidCallback onTap; final VoidCallback? onEdit; final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GamifiedListItem(
      onTap: onTap,
      accentColor: AppTheme.primaryGreen,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1),
          image: (halaqah.photoPath != null)
              ? DecorationImage(image: FileImage(File(halaqah.photoPath!)), fit: BoxFit.cover)
              : null,
        ),
        child: (halaqah.photoPath == null)
            ? const Center(
                child: Icon(Icons.hub_rounded, color: AppTheme.primaryGreen, size: 24),
              )
            : null,
      ),
      title: halaqah.nama,
      subtitle: 'Musyrif: ${musyrifNama ?? "Belum Ditentukan"}',
      stats: [
        GamifiedStatItem(
          icon: Icons.person_pin_rounded,
          label: 'Musyrif',
          value: musyrifNama != null ? '1' : '0',
          color: Colors.blue,
        ),
        GamifiedStatItem(
          icon: Icons.people_alt_rounded,
          label: 'Santri',
          value: '$santriCount',
          color: AppTheme.gold,
        ),
      ],
      trailing: (onEdit != null || onDelete != null)
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) {
                if (val == 'edit') onEdit?.call();
                if (val == 'delete') onDelete?.call();
              },
              itemBuilder: (ctx) => [
                if (onEdit != null) const PopupMenuItem(value: 'edit', child: _MenuAction(Icons.edit_rounded, 'Edit', Colors.blue)),
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

class _HalaqahDetailScreen extends StatelessWidget {
  const _HalaqahDetailScreen({required this.halaqahId});
  final String halaqahId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final h = provider.getHalaqahById(halaqahId);
        if (h == null) return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));
        final musyrif = provider.getMusyrifById(h.musyrifId);
        final santriList = provider.getSantriByHalaqah(halaqahId);

        return Scaffold(
          appBar: AppBar(title: Text(h.nama)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                child: Column(
                  children: [
                    if (h.photoPath != null)
                      Image.file(File(h.photoPath!), height: 200, width: double.infinity, fit: BoxFit.cover)
                    else
                      const Padding(padding: EdgeInsets.all(24), child: Icon(Icons.groups_rounded, size: 64, color: AppTheme.primaryGreen)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text(h.nama, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Pembimbing: ${musyrif?.nama ?? '-'}', style: TextStyle(color: Colors.grey.shade600)),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Daftar Santri (${santriList.length})', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (santriList.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Belum ada santri', style: TextStyle(color: Colors.grey.shade400))))
              else
                ...santriList.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: s.id))),
                    leading: CircleAvatar(backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1), child: Text(s.name[0], style: const TextStyle(color: AppTheme.primaryGreen))),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(s.nis ?? '-', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }
}
