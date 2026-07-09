import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';

class QuranRankingList extends StatefulWidget {
  const QuranRankingList({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<QuranRankingList> createState() => _QuranRankingListState();
}

class _QuranRankingListState extends State<QuranRankingList> with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.grey.shade100)
          ),
          child: TabBar(
            controller: _innerTab,
            indicator: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(15)),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [Tab(text: 'SANTRI'), Tab(text: 'HALAQAH')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [const _SantriRankingTab(), const _HalaqahRankingTab()],
          ),
        ),
      ],
    );
  }
}

class _SantriRankingTab extends StatefulWidget {
  const _SantriRankingTab();

  @override
  State<_SantriRankingTab> createState() => _SantriRankingTabState();
}

class _SantriRankingTabState extends State<_SantriRankingTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToChild();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToChild() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (!provider.isOrangTua || provider.linkedSantriId == null) return;

    final list = provider.santriList;
    var ranked = [...list];
    ranked.sort((a, b) {
      int cmp = b.estimatedJuz.compareTo(a.estimatedJuz);
      if (cmp == 0) return b.averageScore.compareTo(a.averageScore);
      return cmp;
    });

    final childIndex = ranked.indexWhere((s) => s.id == provider.linkedSantriId);
    if (childIndex != -1) {
      // Estimated item height + margin is ~82.0
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || !_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = (childIndex * 82.0).clamp(0.0, maxScroll);
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final list = provider.santriList;
      var ranked = [...list];
      ranked.sort((a, b) {
        int cmp = b.estimatedJuz.compareTo(a.estimatedJuz);
        if (cmp == 0) return b.averageScore.compareTo(a.averageScore);
        return cmp;
      });
      if (ranked.isEmpty) return _emptyState(Icons.emoji_events_outlined, 'Belum ada data peringkat');
      
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
          
          if (isTablet) {
            return GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 0,
              ),
              itemCount: ranked.length,
              itemBuilder: (ctx, i) => _RankCard(
                rank: i + 1, 
                santri: ranked[i],
                isChild: provider.isOrangTua && ranked[i].id == provider.linkedSantriId,
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: ranked.length,
            itemBuilder: (ctx, i) => _RankCard(
              rank: i + 1, 
              santri: ranked[i],
              isChild: provider.isOrangTua && ranked[i].id == provider.linkedSantriId,
            ),
          );
        }
      );
    });
  }
}

class _HalaqahRankingTab extends StatelessWidget {
  const _HalaqahRankingTab();
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final Map<String, (int ayahs, double score, int count)> stats = {};
      for (var s in provider.santriList) {
        if (s.halaqahId == null) continue;
        final curr = stats[s.halaqahId] ?? (0, 0.0, 0);
        stats[s.halaqahId!] = (curr.$1 + s.totalZiyadahAyahs, curr.$2 + s.averageScore, curr.$3 + 1);
      }
      final halaqahs = provider.halaqahList.map((h) {
        final s = stats[h.id] ?? (0, 0.0, 0);
        return (data: h, juz: s.$1 / 604.0, score: s.$3 == 0 ? 0.0 : s.$2 / s.$3);
      }).toList();
      halaqahs.sort((a, b) => b.juz.compareTo(a.juz));
      if (halaqahs.isEmpty) return _emptyState(Icons.groups_outlined, 'Belum ada data halaqah');
      
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth > 700;
          
          if (isTablet) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 4.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 0,
              ),
              itemCount: halaqahs.length,
              itemBuilder: (ctx, i) => _HalaqahRankCard(rank: i + 1, item: halaqahs[i]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: halaqahs.length,
            itemBuilder: (ctx, i) => _HalaqahRankCard(rank: i + 1, item: halaqahs[i]),
          );
        }
      );
    });
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.santri, this.isChild = false});
  final int rank; final Santri santri; final bool isChild;
  @override
  Widget build(BuildContext context) {
    final juz = santri.estimatedJuz;
    Color? bgColor = Colors.white;
    Color? borderColor = Colors.grey.shade100;
    if (isChild) {
      bgColor = const Color(0xFFE8F5E9); // Highlight hijau muda lembut
      borderColor = AppTheme.primaryGreen.withValues(alpha: 0.5);
    } else if (rank == 1) { bgColor = const Color(0xFFFFF9C4); borderColor = Colors.orange.shade200; }
    else if (rank == 2) { bgColor = const Color(0xFFF5F5F5); borderColor = Colors.blueGrey.shade100; }
    else if (rank == 3) { bgColor = const Color(0xFFFFECB3); borderColor = Colors.orange.shade100; }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: BorderSide(color: borderColor, width: isChild ? 2 : 1)
      ),
      color: bgColor, elevation: 0,
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id))),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            AppAvatar(name: santri.name, radius: 22, imagePath: santri.photoPath),
            if (rank <= 3) 
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.workspace_premium_rounded, color: rank == 1 ? AppTheme.gold : (rank == 2 ? Colors.blueGrey : Colors.brown), size: 14),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(santri.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (isChild)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Anak Anda',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text('${juz.toStringAsFixed(1)} Juz', style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isChild ? AppTheme.primaryGreen : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 8),
            if (juz >= 1.0)
              Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppTheme.gold, size: 20),
                  Text(juz.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ]
              ),
          ],
        ),
      ),
    );
  }
}

class _HalaqahRankCard extends StatelessWidget {
  const _HalaqahRankCard({required this.rank, required this.item});
  final int rank; final dynamic item;
  @override
  Widget build(BuildContext context) {
    Color? bgColor = rank == 1 ? const Color(0xFFE8F5E9) : Colors.white;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      color: bgColor, elevation: 0,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1), child: Text('$rank', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold))),
        title: Text(item.data.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Total Kolektif: ${item.juz.toStringAsFixed(1)} Juz', style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 20),
            Text(item.juz.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), Text(msg, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500))]));
