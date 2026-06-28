import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/halaqah_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'santri_detail_screen.dart';
import 'halaqah_form_screen.dart';

class HalaqahListScreen extends StatelessWidget {
  const HalaqahListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Halaqah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Tambah Halaqah',
            onPressed: () => _showFormDialog(context, null),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final list = provider.halaqahList;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada halaqah',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _showFormDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Halaqah'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _HalaqahDetailScreen(halaqahId: h.id),
                  ),
                ),
                onEdit: () => _showFormDialog(context, h),
                onDelete: () =>
                    _confirmDelete(context, provider, h, santriCount),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_halaqah_add',
        onPressed: () => _showFormDialog(context, null),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Tambah Halaqah'),
      ),
    );
  }

  void _showFormDialog(BuildContext context, HalaqahData? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HalaqahFormScreen(existing: existing)),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    HalaqahData h,
    int santriCount,
  ) {
    if (santriCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${h.nama}" masih memiliki $santriCount santri. Pindahkan santri terlebih dahulu.',
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
        title: const Text('Hapus Halaqah?'),
        content: Text('Halaqah "${h.nama}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.removeHalaqah(h.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Halaqah Card ───────────────────────────────────────────────────────────────

class _HalaqahCard extends StatelessWidget {
  const _HalaqahCard({
    required this.halaqah,
    required this.musyrifNama,
    required this.santriCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final HalaqahData halaqah;
  final String? musyrifNama;
  final int santriCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _levelColor {
    switch (halaqah.level) {
      case 'Lanjutan':
        return const Color(0xFF1565C0);
      case 'Menengah':
        return const Color(0xFFF57F17);
      case 'Takhassus':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: _levelColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          halaqah.nama,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _levelColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                halaqah.level,
                                style: TextStyle(
                                  color: _levelColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$santriCount santri',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    color: Colors.grey.shade600,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: Colors.red,
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (musyrifNama != null || halaqah.jadwal != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (musyrifNama != null)
                  _infoRow(Icons.person_rounded, 'Musyrif', musyrifNama!),
                if (halaqah.jadwal != null)
                  _infoRow(Icons.schedule_rounded, 'Jadwal', halaqah.jadwal!),
                if (halaqah.lokasi != null)
                  _infoRow(
                    Icons.location_on_rounded,
                    'Lokasi',
                    halaqah.lokasi!,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Halaqah Detail (list santri in halaqah) ────────────────────────────────────

class _HalaqahDetailScreen extends StatelessWidget {
  const _HalaqahDetailScreen({required this.halaqahId});
  final String halaqahId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final h = provider.getHalaqahById(halaqahId);
        if (h == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Halaqah')),
            body: const Center(child: Text('Halaqah tidak ditemukan')),
          );
        }
        final musyrif = provider.getMusyrifById(h.musyrifId);
        final santriList = provider.getSantriByHalaqah(halaqahId);

        return Scaffold(
          appBar: AppBar(title: Text(h.nama)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Halaqah',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (musyrif != null)
                        _detail(Icons.person_rounded, 'Musyrif', musyrif.nama),
                      _detail(Icons.stairs_rounded, 'Level', h.level),
                      if (h.jadwal != null)
                        _detail(Icons.schedule_rounded, 'Jadwal', h.jadwal!),
                      if (h.lokasi != null)
                        _detail(Icons.location_on_rounded, 'Lokasi', h.lokasi!),
                      if (h.deskripsi != null)
                        _detail(Icons.notes_rounded, 'Ket.', h.deskripsi!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Santri (${santriList.length})',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              if (santriList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Belum ada santri di halaqah ini',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                )
              else
                ...santriList.map(
                  (s) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SantriDetailScreen(santriId: s.id),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.15,
                        ),
                        child: Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${s.kelas ?? ''}'
                        '${s.targetHafalan != null ? ' · Target: ${s.targetHafalan}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${s.totalSetoranCount} setoran',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
