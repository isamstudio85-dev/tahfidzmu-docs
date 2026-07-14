import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/gamification_utils.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12), 
            ),
            child: TabBar(
              controller: _innerTab,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark ? AppTheme.primaryGreen : Colors.white,
              ),
              labelColor: isDark ? Colors.white : AppTheme.primaryGreen,
              unselectedLabelColor: isDark ? Colors.white38 : Colors.grey.shade600,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToChild());
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

    final ranked = _getRankedList(provider.santriList);
    final childIndex = ranked.indexWhere((s) => s.id == provider.linkedSantriId);
    
    if (childIndex != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final targetOffset = (childIndex * 84.0).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(targetOffset, duration: const Duration(milliseconds: 1000), curve: Curves.fastOutSlowIn);
      });
    }
  }

  List<Santri> _getRankedList(List<Santri> list) {
    var ranked = [...list];
    ranked.sort((a, b) {
      // Game logic: rank by Level first, then XP
      if (a.totalXP != b.totalXP) return b.totalXP.compareTo(a.totalXP);
      return b.averageScore.compareTo(a.averageScore);
    });
    return ranked;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      var fullRanked = _getRankedList(provider.santriList);
      
      if (_searchQuery.isNotEmpty) {
        fullRanked = fullRanked.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || (s.nis?.contains(_searchQuery) ?? false)).toList();
      }

      // Separate Top 3 for Podium
      final List<Santri> top3 = fullRanked.length >= 3 ? fullRanked.sublist(0, 3) : fullRanked;
      final List<Santri> others = fullRanked.length > 3 ? fullRanked.sublist(3) : [];

      return Column(
        children: [
          _buildSearchAndHeader(),
          Expanded(
            child: fullRanked.isEmpty 
              ? _emptyState(Icons.search_off_rounded, 'Santri tidak ditemukan')
              : RefreshIndicator(
                  onRefresh: () async => await provider.setupFirestoreListeners(),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (_searchQuery.isEmpty && top3.isNotEmpty) ...[
                        _EpicPortraitCards(top3: top3),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              Text(
                                'KLASEMEN LAINNYA', 
                                style: GoogleFonts.poppins(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.grey.withValues(alpha: 0.6), 
                                  letterSpacing: 1.5
                                )
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_searchQuery.isNotEmpty)
                        ...fullRanked.asMap().entries.map((e) => _RankCard(
                          rank: e.key + 1,
                          santri: e.value,
                          isChild: provider.isOrangTua && e.value.id == provider.linkedSantriId,
                        ))
                      else
                        ...others.asMap().entries.map((e) => _RankCard(
                          rank: e.key + 4,
                          santri: e.value,
                          isChild: provider.isOrangTua && e.value.id == provider.linkedSantriId,
                        )),
                    ],
                  ),
                ),
          ),
        ],
      );
    });
  }

  Widget _buildSearchAndHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _isSearching 
              ? SizedBox(
                  height: 36,
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Cari nama...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() { _searchQuery = ''; _isSearching = false; })),
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                    ),
                  ),
                )
              : Text('PERINGKAT SANTRI', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 1.5)),
          ),
          if (!_isSearching)
            IconButton(onPressed: () => setState(() => _isSearching = true), icon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.primaryGreen)),
        ],
      ),
    );
  }
}

class _HalaqahRankingTab extends StatelessWidget {
  const _HalaqahRankingTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final Map<String, (int xp, double juz, int count)> stats = {};
      for (var s in provider.santriList) {
        if (s.halaqahId == null) continue;
        final curr = stats[s.halaqahId] ?? (0, 0.0, 0);
        stats[s.halaqahId!] = (curr.$1 + s.totalXP, curr.$2 + s.estimatedJuz, curr.$3 + 1);
      }
      final halaqahs = provider.halaqahList.map((h) {
        final s = stats[h.id] ?? (0, 0.0, 0);
        return (data: h, xp: s.$1, juz: s.$2, members: s.$3);
      }).toList();
      
      halaqahs.sort((a, b) => b.xp.compareTo(a.xp));
      
      if (halaqahs.isEmpty) return _emptyState(Icons.groups_outlined, 'Belum ada data halaqah');
      
      return RefreshIndicator(
        onRefresh: () async => await provider.setupFirestoreListeners(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: halaqahs.length,
          itemBuilder: (ctx, i) => _GuildRankCard(rank: i + 1, item: halaqahs[i]),
        ),
      );
    });
  }
}

class _EpicPortraitCards extends StatelessWidget {
  const _EpicPortraitCards({required this.top3});
  final List<Santri> top3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (top3.isNotEmpty) _portraitCard(top3[0], 1, AppTheme.gold, 'THE CHAMPION'),
        if (top3.length >= 2) _portraitCard(top3[1], 2, const Color(0xFF94A3B8), 'THE CONTENDER'),
        if (top3.length >= 3) _portraitCard(top3[2], 3, const Color(0xFFB45309), 'THE ELITE'),
      ],
    );
  }

  Widget _portraitCard(Santri santri, int rank, Color color, String title) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDark ? [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ] : [
              color.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.3), width: rank == 1 ? 2 : 1),
        ),
        child: Stack(
          children: [
            // Background Artwork (Small Icon)
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  rank == 1 ? Icons.workspace_premium_rounded : Icons.military_tech_rounded, 
                  size: 100, 
                  color: color
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Rank & Avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: AppAvatar(name: santri.name, radius: 24, imagePath: santri.photoPath),
                      ),
                      Positioned(
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? AppTheme.darkBg : Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '#$rank',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900, 
                            fontSize: 7, 
                            color: color, 
                            letterSpacing: 1.2
                          ),
                        ),
                        Text(
                          santri.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900, 
                            fontSize: 13, 
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (santri.activeTitle != null)
                          Text(
                            santri.activeTitle!.toUpperCase(), 
                            style: TextStyle(
                              fontSize: 7, 
                              fontWeight: FontWeight.w900, 
                              color: AppTheme.gold, 
                              letterSpacing: 0.5
                            )
                          ),
                      ],
                    ),
                  ),
                  // Power Stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${santri.totalXP}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900, 
                            fontSize: 12, 
                            color: color,
                          ),
                        ),
                        const Text(
                          'PWR XP',
                          style: TextStyle(
                            fontSize: 6, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.grey, 
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int level = GamificationUtils.calculateLevel(santri.totalXP);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isChild 
          ? (isDark ? AppTheme.primaryGreen.withValues(alpha: 0.1) : AppTheme.primaryGreen.withValues(alpha: 0.05))
          : (isDark ? AppTheme.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isChild ? AppTheme.primaryGreen.withValues(alpha: 0.3) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          width: isChild ? 2 : 1,
        ),
        boxShadow: isChild ? [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.1), blurRadius: 10)] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank Number
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  fontSize: 14,
                ),
              ),
            ),
            // Avatar
            AppAvatar(name: santri.name, radius: 18, imagePath: santri.photoPath),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    santri.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (santri.activeTitle != null)
                    Text(
                      santri.activeTitle!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.gold,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
            // Level & XP
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LVL $level',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${santri.totalXP} XP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuildRankCard extends StatelessWidget {
  const _GuildRankCard({required this.rank, required this.item});
  final int rank; final dynamic item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50, shape: BoxShape.circle),
            child: Center(child: Text('#$rank', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.grey.shade300))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.data.nama, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text('${item.members} Santri • ${item.juz.toStringAsFixed(1)} Total Juz', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.xp}', style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w900, fontSize: 16)),
              const Text('TOTAL XP', style: TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.05)), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.w500))]));
