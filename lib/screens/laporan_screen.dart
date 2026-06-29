import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/error_mark.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/scoring_utils.dart';
import '../widgets/app_avatar.dart';
import '../widgets/quran_widgets.dart';
import 'santri_detail_screen.dart';
import 'setoran_detail_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});
  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Tahfidz'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          tabs: const [Tab(text: 'Statistik'), Tab(text: 'Peringkat')],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          final setorans = provider.isOrangTua ? (provider.linkedSantri?.setoranHistory.toList() ?? []) : provider.santriList.expand((s) => s.setoranHistory).toList();
          setorans.sort((a, b) => b.date.compareTo(a.date));
          return TabBarView(
            controller: _tab,
            children: [
              _StatistikTab(setorans: setorans, provider: provider),
              _PeringkatTab(provider: provider, santriForRank: provider.santriList),
            ],
          );
        },
      ),
    );
  }
}

class _StatistikTab extends StatelessWidget {
  const _StatistikTab({required this.setorans, required this.provider});
  final List<SetoranRecord> setorans;
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    if (setorans.isEmpty) return const _EmptyState();
    final ziyadah = setorans.where((s) => s.type == SetoranType.ziyadah).length;
    final avg = setorans.map((s) => s.finalScore).reduce((a, b) => a + b) / setorans.length;
    final errors = setorans.expand((s) => s.errorMarks).toList();
    final tajwid = errors.where((e) => e.errorType == ErrorType.tajwid).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryRow(avg),
        const SizedBox(height: 24),
        _sectionLabel('JENIS SETORAN'),
        const SizedBox(height: 12),
        _buildProgressCard('Ziyadah', ziyadah, setorans.length, AppTheme.primaryGreen),
        _buildProgressCard("Muroja'ah", setorans.length - ziyadah, setorans.length, const Color(0xFF7B1FA2)),
        const SizedBox(height: 24),
        _sectionLabel('KESALAHAN TERBANYAK'),
        const SizedBox(height: 12),
        _buildProgressCard('Tajwid', tajwid, errors.length, AppTheme.tajwidColor),
        _buildProgressCard('Makhroj', errors.length - tajwid, errors.length, AppTheme.makhrojColor),
        const SizedBox(height: 24),
        _sectionLabel('7 HARI TERAKHIR'),
        const SizedBox(height: 12),
        _WeeklyActivity(setorans: setorans),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _summaryRow(double avg) {
    return Row(
      children: [
        _miniStat('Total Setoran', '${setorans.length}', AppTheme.primaryGreen),
        const SizedBox(width: 12),
        _miniStat('Rata-rata Skor', avg.toStringAsFixed(1), AppTheme.gold),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
        child: Column(children: [
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildProgressCard(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : count / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: pct, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 6, borderRadius: BorderRadius.circular(3)),
        ],
      ),
    );
  }
}

class _PeringkatTab extends StatelessWidget {
  const _PeringkatTab({required this.provider, required this.santriForRank});
  final AppProvider provider; final List<Santri> santriForRank;

  @override
  Widget build(BuildContext context) {
    final ranked = [...santriForRank]..sort((a, b) => b.estimatedJuz.compareTo(a.estimatedJuz));
    if (ranked.isEmpty) return const _EmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranked.length,
      itemBuilder: (ctx, i) => _RankTile(rank: i + 1, santri: ranked[i]),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.santri});
  final int rank; final Santri santri;
  @override
  Widget build(BuildContext context) {
    final color = rank == 1 ? AppTheme.gold : (rank == 2 ? const Color(0xFFB0BEC5) : (rank == 3 ? Colors.orange.shade300 : Colors.grey.shade300));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id))),
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Text('$rank', style: TextStyle(color: color.withValues(alpha: 1.0), fontWeight: FontWeight.bold))),
        title: Text(santri.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('≈ ${santri.estimatedJuz.toStringAsFixed(1)} Juz', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: Text(santri.averageScore.toStringAsFixed(1), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}

class _WeeklyActivity extends StatelessWidget {
  const _WeeklyActivity({required this.setorans});
  final List<SetoranRecord> setorans;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final max = days.map((d) => setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length).fold(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final count = setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length;
          final ratio = max == 0 ? 0.0 : count / max;
          return Column(children: [
            Container(width: 24, height: (50 * ratio).clamp(4.0, 50.0), decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: d.day == now.day ? 1.0 : 0.4), borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Text(['S','S','R','K','J','S','M'][d.weekday-1], style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ]);
        }).toList(),
      ),
    );
  }
}

Widget _sectionLabel(String title) => Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0));

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300), const SizedBox(height: 12), const Text('Belum ada data', style: TextStyle(color: Colors.grey))]));
  }
}
