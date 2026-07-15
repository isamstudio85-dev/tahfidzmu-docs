import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/services/hadith_service.dart';
import 'package:tahfidz_app/features/education/screens/hadits_detail_screen.dart';

class HaditsScreen extends StatefulWidget {
  const HaditsScreen({super.key});

  @override
  State<HaditsScreen> createState() => _HaditsScreenState();
}

class _HaditsScreenState extends State<HaditsScreen> {
  Hadith? _selectedHadith;
  String _searchQuery = "";
  Map<String, List<Hadith>> _allData = {};
  Map<String, List<Hadith>> _filteredData = {};

  Future<Map<String, List<Hadith>>> _loadThemesAndArbain() async {
    if (_allData.isNotEmpty) return _allData;
    final byTema = await HadithService.getByTema();
    final arbain = await HadithService.getArbain();
    
    final Map<String, List<Hadith>> combined = {};
    if (arbain.isNotEmpty) combined['arbain'] = arbain;
    combined.addAll(byTema);
    _allData = combined;
    _filteredData = combined;
    return combined;
  }

  void _filterHadits(String q) {
    setState(() {
      _searchQuery = q.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredData = _allData;
      } else {
        final Map<String, List<Hadith>> result = {};
        _allData.forEach((tema, list) {
          final matches = list.where((h) {
            return h.judul.toLowerCase().contains(_searchQuery) || 
                   h.terjemah.toLowerCase().contains(_searchQuery) ||
                   h.perawi.toLowerCase().contains(_searchQuery);
          }).toList();
          if (matches.isNotEmpty) result[tema] = matches;
        });
        _filteredData = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;

    return FutureBuilder<Map<String, List<Hadith>>>(
      future: _loadThemesAndArbain(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && _allData.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Hadits Pilihan')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Auto select first hadith if none selected in wide mode
        if (isWide && _selectedHadith == null && _filteredData.isNotEmpty) {
          final firstTema = _filteredData.keys.first;
          if (_filteredData[firstTema]!.isNotEmpty) {
            _selectedHadith = _filteredData[firstTema]!.first;
          }
        }

        Widget sidebarHeader = Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: _filterHadits,
            decoration: InputDecoration(
              hintText: 'Cari hadits atau makna...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: isWide ? Colors.white : const Color(0xFFF4EAD4).withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        );

        Widget listWidget = Column(
          children: [
            sidebarHeader,
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filteredData.length,
                separatorBuilder: (ctx, i) => const Divider(
                  color: Color(0xFFE5D5B8),
                  height: 1,
                  thickness: 1.2,
                ),
                itemBuilder: (context, i) {
                  final tema = _filteredData.keys.elementAt(i);
                  final hadiths = _filteredData[tema]!;
                  return _TemaSection(
                    key: ValueKey('tema_$tema'),
                    tema: tema, 
                    hadiths: hadiths,
                    isWide: isWide,
                    selectedHadith: _selectedHadith,
                    onHadithTap: (h) {
                      if (isWide) {
                        setState(() => _selectedHadith = h);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HaditsDetailScreen(hadith: h)),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );

        if (isWide) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDF9F0),
            appBar: AppBar(
              title: const Text('Hadits Pilihan'),
              backgroundColor: const Color(0xFF2E5A27),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Row(
              children: [
                SizedBox(
                  width: 350,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Color(0xFFE5D5B8), width: 1)),
                    ),
                    child: listWidget,
                  ),
                ),
                Expanded(
                  child: _selectedHadith == null
                      ? const Center(child: Text('Pilih hadits untuk melihat detail'))
                      : HaditsDetailScreen(
                          key: ValueKey('hadith_${_selectedHadith!.id}'),
                          hadith: _selectedHadith!,
                          hideAppBar: true,
                        ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFDF9F0),
          appBar: AppBar(
            title: const Text('Hadits Pilihan'),
            backgroundColor: const Color(0xFF2E5A27),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: listWidget,
        );
      },
    );
  }
}

// ── Tema Section ───────────────────────────────────────────────────────────────

class _TemaSection extends StatefulWidget {
  const _TemaSection({
    super.key,
    required this.tema, 
    required this.hadiths,
    required this.isWide,
    this.selectedHadith,
    required this.onHadithTap,
  });
  final String tema;
  final List<Hadith> hadiths;
  final bool isWide;
  final Hadith? selectedHadith;
  final Function(Hadith) onHadithTap;

  @override
  State<_TemaSection> createState() => _TemaSectionState();
}

class _TemaSectionState extends State<_TemaSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // Default closed even on wide screens to keep sidebar clean
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final color = _temaColor(widget.tema);
    final isArbain = widget.tema == 'arbain';
    final String label = isArbain ? "Arba'in An-Nawawiyyah" : Hadith.temaLabel(widget.tema);
    
    return Container(
      color: const Color(0xFFFDF9F0),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_temaIcon(widget.tema), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFF4E342E), // Soft Espresso
                          ),
                        ),
                        Text(
                          '${widget.hadiths.length} hadits',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: const Color(0xFF2E5A27),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: widget.hadiths.length,
                separatorBuilder: (_, __) => const Divider(
                  color: Color(0xFFEDE8DF),
                  height: 1,
                  thickness: 0.8,
                ),
                itemBuilder: (context, i) => _HadithCard(
                  hadith: widget.hadiths[i], 
                  showArbainNo: isArbain,
                  isWide: widget.isWide,
                  isSelected: widget.selectedHadith?.id == widget.hadiths[i].id,
                  onTap: () => widget.onHadithTap(widget.hadiths[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hadith card ────────────────────────────────────────────────────────────────

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.hadith, 
    required this.showArbainNo,
    required this.isWide,
    required this.isSelected,
    required this.onTap,
  });
  final Hadith hadith;
  final bool showArbainNo;
  final bool isWide;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected && isWide ? const Color(0xFFF4EAD4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge (Kitab Kuning Arabic Circle Style)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E5A27).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5D5B8), width: 1),
                ),
                child: Center(
                  child: Text(
                    showArbainNo && hadith.isArbain
                        ? '${hadith.arbainNo}'
                        : '${hadith.id}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: const Color(0xFF2E5A27),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hadith Title
                    Text(
                      hadith.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4E342E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Arabic preview (snippet)
                    Text(
                      hadith.matanArab,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        color: const Color(0xFF1B5E20).withValues(alpha: 0.7),
                      ),
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
                  ],
                ),
              ),
              if (!isWide)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2E5A27),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Color _temaColor(String? tema) {
  if (tema == null) return Colors.blueGrey;
  switch (tema) {
    case 'arbain':
      return const Color(0xFF2E5A27); // Standardize theme color to Olive Green
    case 'niat':
      return const Color(0xFF00897B);
    case 'akidah':
      return const Color(0xFF1565C0);
    case 'ibadah':
      return const Color(0xFF2E5A27);
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

IconData _temaIcon(String? tema) {
  if (tema == null) return Icons.circle_rounded;
  switch (tema) {
    case 'arbain':
      return Icons.menu_book_rounded;
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
