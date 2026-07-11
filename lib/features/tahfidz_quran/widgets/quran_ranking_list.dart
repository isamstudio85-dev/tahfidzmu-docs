import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class QuranRankingList extends StatefulWidget {
  const QuranRankingList({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<QuranRankingList> createState() => _QuranRankingListState();
}

class _QuranRankingListState extends State<QuranRankingList> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _innerTab;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(14), 
            ),
            child: TabBar(
              controller: _innerTab,
              indicator: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppTheme.primaryGreen,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
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
      ),
    );
  }
}

class _SantriRankingTab extends StatefulWidget {
  const _SantriRankingTab();

  @override
  State<_SantriRankingTab> createState() => _SantriRankingTabState();
}

class _SantriRankingTabState extends State<_SantriRankingTab> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

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
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || !_scrollController.hasClients) return;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetOffset = (childIndex * 60.0).clamp(0.0, maxScroll);
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
    super.build(context);
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final list = provider.santriList;
      var ranked = [...list];
      ranked.sort((a, b) {
        int cmp = b.estimatedJuz.compareTo(a.estimatedJuz);
        if (cmp == 0) return b.averageScore.compareTo(a.averageScore);
        return cmp;
      });

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        ranked = ranked.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || (s.nis?.contains(_searchQuery) ?? false)).toList();
      }

      return Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isSearching ? 50 : 0,
              child: _isSearching 
                ? TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama santri...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _searchQuery = '';
                          _isSearching = false;
                        }),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  )
                : const SizedBox.shrink(),
            ),
          ),
          
          if (!_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Leaderboard Santri', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  IconButton(
                    onPressed: () => setState(() => _isSearching = true),
                    icon: const Icon(Icons.search, size: 20, color: AppTheme.primaryGreen),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ranked.isEmpty 
              ? _emptyState(Icons.search_off_rounded, 'Santri tidak ditemukan')
              : RefreshIndicator(
                  onRefresh: () async => await provider.setupFirestoreListeners(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                    itemCount: ranked.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE), indent: 56),
                    itemBuilder: (ctx, i) => _RankCard(
                      rank: i + 1, 
                      santri: ranked[i],
                      isChild: provider.isOrangTua && ranked[i].id == provider.linkedSantriId,
                    ),
                  ),
                ),
          ),
        ],
      );
    });
  }
}

class _HalaqahRankingTab extends StatefulWidget {
  const _HalaqahRankingTab();

  @override
  State<_HalaqahRankingTab> createState() => _HalaqahRankingTabState();
}

class _HalaqahRankingTabState extends State<_HalaqahRankingTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      
      return RefreshIndicator(
        onRefresh: () async => await provider.setupFirestoreListeners(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
          itemCount: halaqahs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE), indent: 56),
          itemBuilder: (ctx, i) => _HalaqahRankCard(rank: i + 1, item: halaqahs[i]),
        ),
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
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          // Rank Number with Trophy for Top 3
          SizedBox(
            width: 32,
            child: rank <= 3 
              ? Icon(Icons.emoji_events_rounded, color: rank == 1 ? AppTheme.gold : (rank == 2 ? Colors.blueGrey : Colors.brown), size: 20)
              : Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          
          // Squircle Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
              image: (santri.photoPath?.isNotEmpty ?? false)
                  ? DecorationImage(image: NetworkImage(santri.photoPath!), fit: BoxFit.cover)
                  : null,
            ),
            child: (santri.photoPath?.isEmpty ?? true)
                ? Center(child: Text(santri.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)))
                : null,
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  santri.name, 
                  style: GoogleFonts.poppins(
                    fontWeight: isChild ? FontWeight.bold : FontWeight.w600, 
                    fontSize: 13, 
                    color: isChild ? AppTheme.primaryGreen : Colors.black87
                  ), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                Text(
                  '${juz.toStringAsFixed(1)} Juz dihafal', 
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          
          if (isChild)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('Anak Anda', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _HalaqahRankCard extends StatelessWidget {
  const _HalaqahRankCard({required this.rank, required this.item});
  final int rank; final dynamic item;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: rank == 1 ? AppTheme.primaryGreen : Colors.grey.shade400, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.data.nama, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                Text(
                  'Kolektif: ${item.juz.toStringAsFixed(1)} Juz', 
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
                ),
              ],
            ),
          ),
          
          Icon(Icons.stars_rounded, color: rank == 1 ? AppTheme.gold : Colors.grey.shade300, size: 18),
        ],
      ),
    );
  }
}

Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), Text(msg, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500))]));
