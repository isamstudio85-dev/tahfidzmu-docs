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

class _LaporanScreenState extends State<LaporanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.gold,
          tabs: const [
            Tab(text: 'Statistik'),
            Tab(text: 'Peringkat'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          // Stats tab: OrangTua sees only their child; others see all
          final List<SetoranRecord> allSetorans;
          if (provider.isOrangTua) {
            final child = provider.linkedSantri;
            allSetorans = child?.setoranHistory.toList() ?? [];
          } else {
            allSetorans = provider.santriList
                .expand((s) => s.setoranHistory)
                .toList();
          }
          allSetorans.sort((a, b) => b.date.compareTo(a.date));

          // Ranking tab: always show ALL santri so every user can see the board
          final santriForRank = provider.santriList.toList();

          return TabBarView(
            controller: _tab,
            children: [
              _StatistikTab(setorans: allSetorans, provider: provider),
              _PeringkatTab(provider: provider, santriForRank: santriForRank),
            ],
          );
        },
      ),
    );
  }
}

// ── Statistik Tab ──────────────────────────────────────────────────────────────

class _StatistikTab extends StatelessWidget {
  const _StatistikTab({required this.setorans, required this.provider});

  final List<SetoranRecord> setorans;
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    if (setorans.isEmpty) return const _EmptyLaporan();

    final ziyadahCount = setorans
        .where((s) => s.type == SetoranType.ziyadah)
        .length;
    final murojaahCount = setorans.length - ziyadahCount;
    final avgScore =
        setorans.map((s) => s.finalScore).reduce((a, b) => a + b) /
        setorans.length;
    final allErrors = setorans.expand((s) => s.errorMarks).toList();
    final tajwidCount = allErrors
        .where((e) => e.errorType == ErrorType.tajwid)
        .length;
    final makhrojCount = allErrors.length - tajwidCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Ringkasan'),
          const SizedBox(height: 10),
          _summaryRow(avgScore),
          const SizedBox(height: 20),

          if (provider.isOrangTua &&
              provider.linkedSantri != null &&
              provider.linkedSantri!.setoranHistory.isNotEmpty) ...[
            _sectionTitle('Riwayat Terbaru'),
            const SizedBox(height: 10),
            ...provider.linkedSantri!.setoranHistory.reversed.take(3).map((
              record,
            ) {
              final santri = provider.linkedSantri!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SetoranDetailScreen(record: record, santri: santri),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${record.surahEnglishName} (${record.surahName})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${record.ayahRange} • ${record.type.label}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record.finalScore.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          _sectionTitle('Jenis Setoran'),
          const SizedBox(height: 10),
          _TypeBreakdown(ziyadah: ziyadahCount, murojaah: murojaahCount),
          const SizedBox(height: 20),

          _sectionTitle('Sebaran Kesalahan'),
          const SizedBox(height: 10),
          _ErrorBreakdown(tajwid: tajwidCount, makhroj: makhrojCount),
          const SizedBox(height: 20),

          _sectionTitle('Distribusi Nilai'),
          const SizedBox(height: 10),
          _GradeDistribution(setorans: setorans),
          const SizedBox(height: 20),

          _sectionTitle('Aktivitas 7 Hari Terakhir'),
          const SizedBox(height: 10),
          _WeeklyActivity(setorans: setorans),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.grey.shade700,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _summaryRow(double avgScore) {
    final totalAktif = provider.santriList
        .where((s) => s.setoranHistory.isNotEmpty)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final children = [
          Expanded(
            child: _MiniStat(
              icon: Icons.assignment_turned_in_rounded,
              label: 'Total Setoran',
              value: '${setorans.length}',
              color: AppTheme.primaryGreen,
            ),
          ),
          SizedBox(width: isNarrow ? 8 : 10),
          Expanded(
            child: _MiniStat(
              icon: Icons.people_alt_rounded,
              label: 'Santri Aktif',
              value: '$totalAktif',
              color: const Color(0xFF7B1FA2),
            ),
          ),
          SizedBox(width: isNarrow ? 8 : 10),
          Expanded(
            child: _MiniStat(
              icon: Icons.star_rounded,
              label: 'Rata-rata',
              value: avgScore.toStringAsFixed(1),
              color: AppTheme.gold,
            ),
          ),
        ];

        return Row(children: children);
      },
    );
  }
}

// ── Peringkat Tab ──────────────────────────────────────────────────────────────

class _PeringkatTab extends StatefulWidget {
  const _PeringkatTab({required this.provider, required this.santriForRank});

  final AppProvider provider;
  final List<Santri> santriForRank;

  @override
  State<_PeringkatTab> createState() => _PeringkatTabState();
}

class _PeringkatTabState extends State<_PeringkatTab> {
  List<Santri> _sorted() {
    final list = [...widget.santriForRank];
    list.sort((a, b) => b.estimatedJuz.compareTo(a.estimatedJuz));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _sorted();
    if (ranked.isEmpty) return const _EmptyLaporan();

    final linkedId = widget.provider.linkedSantriId;

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: ranked.length,
            itemBuilder: (ctx, i) {
              final s = ranked[i];
              return _RankCard(
                rank: i + 1,
                santri: s,
                isHighlighted: s.id == linkedId,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => SantriDetailScreen(santriId: s.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Rank Card ──────────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.rank,
    required this.santri,
    required this.isHighlighted,
    required this.onTap,
  });

  final int rank;
  final Santri santri;
  final bool isHighlighted;
  final VoidCallback onTap;

  // Medal palette
  static const _medalBg = [
    Color(0xFFFFFDE7), // rank 1 – warm gold tint
    Color(0xFFF5F5F5), // rank 2 – silver tint
    Color(0xFFFFF3E0), // rank 3 – bronze tint
  ];
  static const _medalBorder = [
    Color(0xFFFFD700), // gold
    Color(0xFFB0BEC5), // silver
    Color(0xFFFF9800), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final hasSejaran = santri.setoranHistory.isNotEmpty;
    final juz = santri.estimatedJuz;

    final isMedal = rank <= 3;
    final bgColor = isMedal
        ? _medalBg[rank - 1]
        : isHighlighted
        ? AppTheme.primaryGreen.withValues(alpha: 0.06)
        : Colors.white;
    final borderColor = isMedal
        ? _medalBorder[rank - 1]
        : isHighlighted
        ? AppTheme.primaryGreen.withValues(alpha: 0.4)
        : null;

    return GestureDetector(
      onTap: hasSejaran ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(color: borderColor, width: isMedal ? 1.5 : 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile avatar
            AppAvatar(name: santri.name, radius: 24),
            const SizedBox(width: 12),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    santri.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Peringkat Hafalan $rank',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasSejaran) ...[
                    const SizedBox(height: 6),
                    Text(
                      '≈ ${juz.toStringAsFixed(1)} Juz',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Belum ada setoran',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasSejaran ? santri.averageScore.toStringAsFixed(1) : '-',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: hasSejaran
                        ? AppTheme.primaryGreen
                        : Colors.grey.shade400,
                  ),
                ),
                if (hasSejaran)
                  StarRatingWidget(rating: santri.overallStarCount, size: 13),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBreakdown extends StatelessWidget {
  const _TypeBreakdown({required this.ziyadah, required this.murojaah});

  final int ziyadah;
  final int murojaah;

  @override
  Widget build(BuildContext context) {
    const zColor = AppTheme.primaryGreen;
    const mColor = Color(0xFF7B1FA2);
    final total = ziyadah + murojaah;
    final zPct = total == 0 ? 0 : (ziyadah / total * 100).round();

    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Legend(color: zColor, label: 'Ziyadah ($ziyadah)'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Legend(color: mColor, label: "Muro'jaah ($murojaah)"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  if (ziyadah > 0)
                    Flexible(
                      flex: ziyadah,
                      child: Container(color: zColor),
                    ),
                  if (murojaah > 0)
                    Flexible(
                      flex: murojaah,
                      child: Container(color: mColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$zPct% Ziyadah · ${100 - zPct}% Murojaah',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ErrorBreakdown extends StatelessWidget {
  const _ErrorBreakdown({required this.tajwid, required this.makhroj});

  final int tajwid;
  final int makhroj;

  @override
  Widget build(BuildContext context) {
    final total = tajwid + makhroj;
    if (total == 0) {
      return _Card(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tidak ada kesalahan tercatat 🎉',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ),
      );
    }
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Legend(
                  color: AppTheme.tajwidColor,
                  label: 'Tajwid ($tajwid)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Legend(
                  color: AppTheme.makhrojColor,
                  label: 'Makhroj ($makhroj)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  if (tajwid > 0)
                    Flexible(
                      flex: tajwid,
                      child: Container(color: AppTheme.tajwidColor),
                    ),
                  if (makhroj > 0)
                    Flexible(
                      flex: makhroj,
                      child: Container(color: AppTheme.makhrojColor),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeDistribution extends StatelessWidget {
  const _GradeDistribution({required this.setorans});

  final List<SetoranRecord> setorans;

  @override
  Widget build(BuildContext context) {
    const gradeOrder = [
      'Mumtaz',
      'Jayyid Jiddan',
      'Jayyid',
      'Maqbul',
      'Perlu Perbaikan',
    ];
    const gradeColors = {
      'Mumtaz': Color(0xFF2E7D32),
      'Jayyid Jiddan': Color(0xFF1565C0),
      'Jayyid': Color(0xFFF57F17),
      'Maqbul': Color(0xFFE65100),
      'Perlu Perbaikan': Color(0xFFB71C1C),
    };

    final counts = <String, int>{for (final g in gradeOrder) g: 0};
    for (final s in setorans) {
      final g = ScoringUtils.scoreToGrade(s.finalScore);
      counts[g] = (counts[g] ?? 0) + 1;
    }

    return _Card(
      child: Column(
        children: gradeOrder.where((g) => (counts[g] ?? 0) > 0).map((g) {
          final count = counts[g]!;
          final ratio = count / setorans.length;
          final color = gradeColors[g] ?? AppTheme.primaryGreen;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    g,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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
    final counts = {
      for (final d in days)
        d: setorans
            .where(
              (s) =>
                  s.date.year == d.year &&
                  s.date.month == d.month &&
                  s.date.day == d.day,
            )
            .length,
    };
    final maxCount = counts.values.fold(0, (a, b) => a > b ? a : b);
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return _Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final count = counts[d] ?? 0;
          final ratio = maxCount == 0 ? 0.0 : count / maxCount;
          final isToday =
              d.year == now.year && d.month == now.month && d.day == now.day;
          final name = dayNames[(d.weekday - 1) % 7];
          return Column(
            children: [
              Text(
                count > 0 ? '$count' : '',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 60,
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 28,
                  height: (60 * ratio).clamp(4, 60),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 10,
                  color: isToday ? AppTheme.primaryGreen : Colors.grey.shade500,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _EmptyLaporan extends StatelessWidget {
  const _EmptyLaporan();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Belum ada data setoran',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
