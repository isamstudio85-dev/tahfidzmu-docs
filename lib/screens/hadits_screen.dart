import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hadith.dart';
import '../services/hadith_service.dart';
import '../theme/app_theme.dart';
import 'hadits_detail_screen.dart';

class HaditsScreen extends StatefulWidget {
  const HaditsScreen({super.key});

  @override
  State<HaditsScreen> createState() => _HaditsScreenState();
}

class _HaditsScreenState extends State<HaditsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadits Pilihan'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Arbain Nawawi'),
            Tab(text: 'Berdasarkan Tema'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ArbainTab(), _TemaTab()],
      ),
    );
  }
}

// ── Tab Arbain Nawawi ──────────────────────────────────────────────────────────

class _ArbainTab extends StatelessWidget {
  const _ArbainTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Hadith>>(
      future: HadithService.getArbain(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return const Center(child: Text('Gagal memuat data hadits.'));
        }
        final hadiths = snap.data!;
        return Column(
          children: [
            // Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأربعون النووية',
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kitab Al-Arbain An-Nawawiyyah — Imam Yahya bin Syaraf An-Nawawi',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${hadiths.length} Hadits',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: hadiths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) =>
                    _HadithCard(hadith: hadiths[i], showArbainNo: true),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tab Berdasarkan Tema ───────────────────────────────────────────────────────

class _TemaTab extends StatelessWidget {
  const _TemaTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Hadith>>>(
      future: HadithService.getByTema(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return const Center(child: Text('Gagal memuat data hadits.'));
        }
        final byTema = snap.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: byTema.length,
          itemBuilder: (context, i) {
            final tema = byTema.keys.elementAt(i);
            final hadiths = byTema[tema]!;
            return _TemaSection(tema: tema, hadiths: hadiths);
          },
        );
      },
    );
  }
}

class _TemaSection extends StatefulWidget {
  const _TemaSection({required this.tema, required this.hadiths});
  final String tema;
  final List<Hadith> hadiths;

  @override
  State<_TemaSection> createState() => _TemaSectionState();
}

class _TemaSectionState extends State<_TemaSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _temaColor(widget.tema);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_temaIcon(widget.tema), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Hadith.temaLabel(widget.tema),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${widget.hadiths.length} hadits',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: widget.hadiths.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) =>
                  _HadithCard(hadith: widget.hadiths[i], showArbainNo: false),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hadith card ────────────────────────────────────────────────────────────────

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith, required this.showArbainNo});
  final Hadith hadith;
  final bool showArbainNo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HaditsDetailScreen(hadith: hadith)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: showArbainNo && hadith.isArbain
                    ? const Color(0xFF1A237E).withValues(alpha: 0.1)
                    : AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  showArbainNo && hadith.isArbain
                      ? '${hadith.arbainNo}'
                      : '${hadith.id}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: showArbainNo && hadith.isArbain
                        ? const Color(0xFF1A237E)
                        : AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic preview (first line)
                  Text(
                    hadith.matanArab,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 6),
                  // Perawi
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hadith.perawi,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Tema chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _temaColor(hadith.tema).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Hadith.temaLabel(hadith.tema),
                      style: TextStyle(
                        fontSize: 10,
                        color: _temaColor(hadith.tema),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Color _temaColor(String tema) {
  switch (tema) {
    case 'arbain':
      return const Color(0xFF283593);
    case 'niat':
      return const Color(0xFF00897B);
    case 'akidah':
      return const Color(0xFF1565C0);
    case 'ibadah':
      return AppTheme.primaryGreen;
    case 'akhlak':
      return const Color(0xFF6A1B9A);
    case 'quran':
      return const Color(0xFFE65100);
    case 'ilmu':
      return const Color(0xFF00838F);
    case 'muamalah':
      return const Color(0xFF558B2F);
    case 'keluarga':
      return const Color(0xFFC62828);
    case 'doa':
      return const Color(0xFF4527A0);
    case 'larangan':
      return const Color(0xFFBF360C);
    case 'dunia':
      return const Color(0xFF37474F);
    case 'kesehatan':
      return const Color(0xFF2E7D32);
    default:
      return Colors.blueGrey;
  }
}

IconData _temaIcon(String tema) {
  switch (tema) {
    case 'arbain':
      return Icons.auto_stories_rounded;
    case 'niat':
      return Icons.favorite_rounded;
    case 'akidah':
      return Icons.star_rounded;
    case 'ibadah':
      return Icons.mosque_rounded;
    case 'akhlak':
      return Icons.people_rounded;
    case 'quran':
      return Icons.menu_book_rounded;
    case 'ilmu':
      return Icons.school_rounded;
    case 'muamalah':
      return Icons.handshake_rounded;
    case 'keluarga':
      return Icons.family_restroom_rounded;
    case 'doa':
      return Icons.volunteer_activism_rounded;
    case 'larangan':
      return Icons.block_rounded;
    case 'dunia':
      return Icons.public_rounded;
    case 'kesehatan':
      return Icons.health_and_safety_rounded;
    default:
      return Icons.circle_rounded;
  }
}
