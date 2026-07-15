import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/continuation_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/utils/gamification_utils.dart';
import 'package:tahfidz_app/core/widgets/user_avatar_with_frame.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';
import 'package:tahfidz_app/features/management/screens/santri_form_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';

class SantriListScreen extends StatefulWidget {
  const SantriListScreen({super.key, this.hideAppBar = false, this.showOnlyMine});
  final bool hideAppBar;
  final bool? showOnlyMine;

  @override
  State<SantriListScreen> createState() => _SantriListScreenState();
}

class _SantriListScreenState extends State<SantriListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final provider = context.watch<AppProvider>();
    final canManage = provider.isAdmin || provider.isCoordinator;
    final showAppBar = !widget.hideAppBar;

    return Scaffold(
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
                child: GamifiedSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  hintText: 'Cari nama, NIS, kelas...',
                  trailing: _buildFilterButton(provider),
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
                        _emptyStateNoExpanded(canManage, 'Belum ada santri.'),
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
                        const Center(child: Text('Tidak ada santri yang cocok', style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await provider.setupFirestoreListeners(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredList.length,
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

  Widget _emptyStateNoExpanded(bool canManage, String message) {
    return Center(
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => SantriFormScreen()));
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

    final level = GamificationUtils.calculateLevel(santri.totalXP);
    final progress = GamificationUtils.levelProgress(santri.totalXP);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GamifiedListItem(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id))),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatarWithFrame(
            photoPath: santri.photoPath,
            name: santri.name,
            frameId: santri.activeFrame,
            size: 56,
          ),
          if (todayStatus != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: _buildMiniStatusBadge(todayStatus),
            ),
        ],
      ),
      title: santri.name,
      subtitle: '${santri.nis ?? "NIS -"} • ${halaqah?.nama ?? "Tanpa Halaqah"}',
      extraContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (santri.activeTitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
              ),
              child: Text(
                santri.activeTitle!,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.gold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
      stats: [
        GamifiedStatItem(
          icon: Icons.shield_rounded,
          label: 'Level',
          value: '$level',
        ),
        GamifiedStatItem(
          icon: Icons.auto_awesome_rounded,
          label: 'XP',
          value: '${santri.totalXP}',
          color: Colors.blue,
        ),
        GamifiedStatItem(
          icon: Icons.stars_rounded,
          label: 'Koin',
          value: '${santri.totalCoins}',
          color: AppTheme.gold,
        ),
      ],
      trailing: canManage
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) async {
                if (val == 'setoran') showSetoranOptions(context, santri);
                if (val == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri)));
                if (val == 'delete') _confirmDelete(context, provider, santri);
                if (val == 'reset') _showResetPasswordDialog(context, provider, santri);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'setoran', child: _MenuAction(Icons.play_circle_fill_rounded, 'Mulai Setoran', AppTheme.primaryGreen)),
                const PopupMenuItem(value: 'edit', child: _MenuAction(Icons.edit_rounded, 'Edit Profile', Colors.blue)),
                const PopupMenuItem(value: 'reset', child: _MenuAction(Icons.lock_reset_rounded, 'Reset Sandi', Colors.orange)),
                const PopupMenuItem(value: 'delete', child: _MenuAction(Icons.delete_outline_rounded, 'Hapus', Colors.red)),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.play_circle_outline_rounded, color: AppTheme.primaryGreen, size: 24),
              onPressed: () => showSetoranOptions(context, santri),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
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
