import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/halaqah_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/continuation_dialog.dart';
import 'santri_detail_screen.dart';
import 'setoran_form_screen.dart';
import 'laporan_screen.dart';

class SetoranScreen extends StatefulWidget {
  const SetoranScreen({super.key});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _query = '';
  SetoranType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canAddSetoran = provider.isAdmin || provider.isMusyrif;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
          'Setoran Hafalan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Daftar'),
            Tab(text: 'Peringkat'),
            Tab(text: 'Laporan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DaftarTab(
            query: _query, 
            filterType: _filterType,
            onQueryChanged: (v) => setState(() => _query = v),
            onTypeChanged: (v) {
              setState(() => _filterType = v);
            },
          ),
          const _PeringkatTabContainer(),
          const _LaporanStatistikTab(),
        ],
      ),
      floatingActionButton: canAddSetoran
          ? FloatingActionButton.extended(
              heroTag: 'fab_setoran_main',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetoranFormScreen())),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: const Text('Setoran Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryGreen,
            )
          : null,
    );
  }
}

class _DaftarTab extends StatelessWidget {
  const _DaftarTab({required this.query, this.filterType, required this.onQueryChanged, required this.onTypeChanged});
  final String query;
  final SetoranType? filterType;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SetoranType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        List<(Santri, SetoranRecord)> allRecords = [];
        final sourceList = provider.isMusyrif && provider.linkedMusyrif != null
            ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
            : provider.santriList;

        for (var s in sourceList) {
          for (var r in s.setoranHistory) {
            allRecords.add((s, r));
          }
        }
        allRecords.sort((a, b) => b.$2.date.compareTo(a.$2.date));

        var filtered = allRecords.where((item) {
          final matchesQuery = item.$1.name.toLowerCase().contains(query.toLowerCase()) || 
                               item.$2.surahEnglishName.toLowerCase().contains(query.toLowerCase());
          final matchesType = filterType == null || item.$2.type == filterType;
          return matchesQuery && matchesType;
        }).toList();

        return Column(
          children: [
            _buildQuickStats(allRecords),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: onQueryChanged,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau surah...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<SetoranType?>(
                    icon: Icon(Icons.filter_list_rounded, color: filterType != null ? AppTheme.primaryGreen : Colors.grey.shade600),
                    onSelected: (val) {
                      onTypeChanged(val);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: null, child: Text('Semua')),
                      const PopupMenuItem(value: SetoranType.ziyadah, child: Text('Ziyadah')),
                      const PopupMenuItem(value: SetoranType.murojaah, child: Text('Muroja\'ah')),
                    ],
                  ),
                ],
              ),
            ),
            if (filtered.isEmpty)
              Expanded(child: _emptyState(Icons.history_rounded, 'Data tidak ditemukan'))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _SetoranCard(santri: filtered[i].$1, record: filtered[i].$2),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(List<(Santri, SetoranRecord)> records) {
    final today = DateTime.now();
    final todayCount = records.where((r) => r.$2.date.day == today.day && r.$2.date.month == today.month && r.$2.date.year == today.year).length;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _statBox('Total Setoran', '${records.length}', Colors.blue),
          const SizedBox(width: 12),
          _statBox('Hari Ini', '$todayCount', AppTheme.primaryGreen),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SetoranCard extends StatelessWidget {
  const _SetoranCard({required this.santri, required this.record});
  final Santri santri;
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      color: Colors.white,
      elevation: 0.5,
      child: ListTile(
        onTap: () => showSetoranOptions(context, santri, record: record),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: AppAvatar(name: santri.name, radius: 18, imagePath: santri.photoPath),
        title: Row(
          children: [
            Expanded(child: Text(santri.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(_formatDate(record.date), style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(child: Text('${record.surahEnglishName} • Ayat ${record.ayahStart}-${record.ayahEnd}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            _tag(record.type.label, record.type == SetoranType.ziyadah ? AppTheme.primaryGreen : Colors.purple),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(record.finalScore.toStringAsFixed(0), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
        ),
      ),
    );
  }
}

class _PeringkatTabContainer extends StatefulWidget {
  const _PeringkatTabContainer();
  @override
  State<_PeringkatTabContainer> createState() => _PeringkatTabContainerState();
}

class _PeringkatTabContainerState extends State<_PeringkatTabContainer> with SingleTickerProviderStateMixin {
  late TabController _innerTab;
  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
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

class _SantriRankingTab extends StatelessWidget {
  const _SantriRankingTab();
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
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ranked.length,
        itemBuilder: (ctx, i) => _RankCard(rank: i + 1, santri: ranked[i]),
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
      // Ranked by total kolektif juz
      halaqahs.sort((a, b) => b.juz.compareTo(a.juz));
      if (halaqahs.isEmpty) return _emptyState(Icons.groups_outlined, 'Belum ada data halaqah');
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: halaqahs.length,
        itemBuilder: (ctx, i) => _HalaqahRankCard(rank: i + 1, item: halaqahs[i]),
      );
    });
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank, required this.santri});
  final int rank; final Santri santri;
  @override
  Widget build(BuildContext context) {
    final juz = santri.estimatedJuz;
    
    // Top 3 Visuals
    Color? bgColor = Colors.white;
    Color? borderColor = Colors.grey.shade100;
    if (rank == 1) { bgColor = const Color(0xFFFFF9C4); borderColor = Colors.orange.shade200; }
    else if (rank == 2) { bgColor = const Color(0xFFF5F5F5); borderColor = Colors.blueGrey.shade100; }
    else if (rank == 3) { bgColor = const Color(0xFFFFECB3); borderColor = Colors.orange.shade100; }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: borderColor)),
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
        title: Text(santri.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${juz.toStringAsFixed(1)} Juz', style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
        trailing: juz >= 1.0 
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.emoji_events_rounded, color: AppTheme.gold, size: 20),
              Text(juz.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
            ])
          : null,
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
          children: [
            const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 20),
            Text(item.juz.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _LaporanStatistikTab extends StatelessWidget {
  const _LaporanStatistikTab();
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final sourceList = provider.isMusyrif && provider.linkedMusyrif != null ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id) : provider.santriList;
        final setorans = sourceList.expand((s) => s.setoranHistory).toList();
        if (setorans.isEmpty) return _emptyState(Icons.bar_chart_rounded, 'Belum ada data statistik');
        return LaporanScreenBody(setorans: setorans, provider: provider);
      },
    );
  }
}

Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), Text(msg, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500))]));
String _formatDate(DateTime d) => '${d.day} ${['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][d.month-1]}';
Widget _tag(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));
