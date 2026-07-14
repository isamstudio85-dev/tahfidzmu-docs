import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/continuation_dialog.dart';

class QuranHistoryList extends StatefulWidget {
  const QuranHistoryList({
    super.key,
    required this.query,
    this.filterType,
    required this.onQueryChanged,
    required this.onTypeChanged,
  });

  final String query;
  final SetoranType? filterType;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SetoranType?> onTypeChanged;

  @override
  State<QuranHistoryList> createState() => _QuranHistoryListState();
}

class _QuranHistoryListState extends State<QuranHistoryList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _onlyMyHalaqah = true; // Toggle between Musyrif's own halaqah and all students
  late TextEditingController _searchController;

  // Cache variables for list memoization
  List<Santri>? _cachedDisplayList;
  List<(Santri, SetoranRecord)>? _cachedRecords;

  bool _areListsEqual(List<Santri> a, List<Santri> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].setoranHistory.length != b[i].setoranHistory.length) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final sourceList = provider.isMusyrif && provider.linkedMusyrif != null && _onlyMyHalaqah
            ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
            : provider.santriList;

        final displayList = provider.isOrangTua 
            ? sourceList.where((s) => s.id == provider.linkedSantriId).toList()
            : sourceList;

        // Memoize list mapping and sorting to prevent stuttering during tab animations
        if (_cachedDisplayList == null || _cachedRecords == null || !_areListsEqual(_cachedDisplayList!, displayList)) {
          _cachedDisplayList = List.from(displayList);
          final List<(Santri, SetoranRecord)> allRecords = [];
          for (var s in displayList) {
            for (var r in s.setoranHistory) {
              allRecords.add((s, r));
            }
          }
          allRecords.sort((a, b) => b.$2.date.compareTo(a.$2.date));
          _cachedRecords = allRecords;
        }

        final allRecords = _cachedRecords!;

        var filtered = allRecords.where((item) {
          final matchesQuery = item.$1.name.toLowerCase().contains(widget.query.toLowerCase()) || 
                               item.$2.surahEnglishName.toLowerCase().contains(widget.query.toLowerCase());
          final matchesType = widget.filterType == null || item.$2.type == widget.filterType;
          return matchesQuery && matchesType;
        }).toList();

        final today = DateTime.now();
        final todaySetoranSantriIds = allRecords
            .where((r) => r.$2.date.day == today.day && r.$2.date.month == today.month && r.$2.date.year == today.year)
            .map((r) => r.$1.id)
            .toSet();
        final totalSantri = displayList.length;
        final sudahSetoran = todaySetoranSantriIds.length;
        final belumSetoran = (totalSantri - sudahSetoran).clamp(0, totalSantri);

        return Column(
          children: [
            // --- SEARCH & MINI STATS (MERGED) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: widget.onQueryChanged,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Cari...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGreen, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (provider.isMusyrif) ...[
                    _compactActionBtn(
                      icon: _onlyMyHalaqah ? Icons.person_pin_rounded : Icons.people_outline_rounded,
                      onTap: () => setState(() => _onlyMyHalaqah = !_onlyMyHalaqah),
                      color: _onlyMyHalaqah ? AppTheme.primaryGreen : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _filterPopupCompact(widget.filterType, widget.onTypeChanged),
                ],
              ),
            ),
            
            if (!provider.isOrangTua)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _tinyStat('SETOR', '$sudahSetoran', AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    _tinyStat('BELUM', '$belumSetoran', Colors.red.shade400),
                  ],
                ),
              ),

            if (filtered.isEmpty)
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => await provider.setupFirestoreListeners(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      _emptyState(Icons.history_rounded, 'Data tidak ditemukan'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isTablet = constraints.maxWidth > 700;
                    
                    if (isTablet) {
                      return RefreshIndicator(
                        onRefresh: () async => await provider.setupFirestoreListeners(),
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 0,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => Column(
                            children: [
                              QuranHistoryCard(
                                santri: filtered[i].$1, 
                                record: filtered[i].$2,
                              ),
                              const Divider(
                                color: Color(0xFFEEEEEE),
                                height: 1,
                                thickness: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => await provider.setupFirestoreListeners(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => Column(
                          children: [
                            QuranHistoryCard(
                              santri: filtered[i].$1, 
                              record: filtered[i].$2,
                            ),
                            const Divider(
                              color: Color(0xFFEEEEEE),
                              height: 1,
                              thickness: 1,
                              indent: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tinyStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
            const Spacer(),
            Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _compactActionBtn({required IconData icon, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _filterPopupCompact(SetoranType? current, ValueChanged<SetoranType?> onSelected) {
    final active = current != null;
    final color = active ? AppTheme.primaryGreen : Colors.grey;
    return PopupMenuButton<SetoranType?>(
      icon: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.filter_list_rounded, color: color, size: 18),
      ),
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: null, child: Text('Semua')),
        const PopupMenuItem(value: SetoranType.ziyadah, child: Text('Ziyadah')),
        const PopupMenuItem(value: SetoranType.murojaah, child: Text('Muroja\'ah')),
      ],
    );
  }

  Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), Text(msg, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500))]));
}

class QuranHistoryCard extends StatelessWidget {
  const QuranHistoryCard({super.key, required this.santri, required this.record});
  final Santri santri;
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final bool isOrangTua = provider.isOrangTua;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GamifiedListItem(
      onTap: () {
        if (isOrangTua) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SetoranDetailScreen(santri: santri, record: record)));
        } else {
          showSetoranOptions(context, santri, record: record);
        }
      },
      leading: isOrangTua 
        ? Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 22),
          )
        : AppAvatar(name: santri.name, radius: 22, imagePath: santri.photoPath),
      title: isOrangTua ? record.surahEnglishName : santri.name,
      subtitle: isOrangTua 
          ? 'Ayat ${record.ayahStart}-${record.ayahEnd} • ${record.type.label}' 
          : '${record.surahEnglishName} • Ayat ${record.ayahStart}-${record.ayahEnd}',
      stats: [
        GamifiedStatItem(
          icon: Icons.star_rounded,
          label: 'Skor',
          value: record.finalScore.toStringAsFixed(0),
          color: AppTheme.gold,
        ),
        GamifiedStatItem(
          icon: Icons.history_edu_rounded,
          label: 'Tipe',
          value: record.type.label.toUpperCase(),
          color: record.type == SetoranType.ziyadah ? AppTheme.primaryGreen : Colors.purple,
        ),
        GamifiedStatItem(
          icon: Icons.access_time_filled_rounded,
          label: 'Waktu',
          value: _formatTime(record.date),
          color: Colors.blue,
        ),
      ],
      trailing: Text(
        _formatDate(record.date),
        style: TextStyle(fontSize: 9, color: isDark ? Colors.white24 : Colors.grey.shade400, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][d.month-1]}';
  String _formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
