import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
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

  bool _isSearching = false;
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
    _isSearching = widget.query.isNotEmpty;
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
            Container(
              color: const Color(0xFFF8F9FA), // Ensure the header area has the right BG
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                  child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSearching
                      ? Row(
                          key: const ValueKey('search_active'),
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGreen),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchController.clear();
                                });
                                widget.onQueryChanged('');
                              },
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 13),
                                  onChanged: widget.onQueryChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Cari nama santri atau surah...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.primaryGreen),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, size: 16),
                                            onPressed: () {
                                              _searchController.clear();
                                              widget.onQueryChanged('');
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('stats_active'),
                          children: [
                            // --- STATS OVERVIEW ---
                            if (!provider.isOrangTua) ...[
                              Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Setor: $sudahSetoran',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                              ),
                              const SizedBox(width: 14),
                              Icon(Icons.cancel_rounded, size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Belum: $belumSetoran',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                              ),
                            ] else ...[
                               const Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryGreen),
                               const SizedBox(width: 8),
                               const Text(
                                 'Riwayat Hafalan Anak',
                                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                               ),
                            ],
                            
                            const Spacer(),

                            // --- TOGGLE SCOPE (MY HALAQAH VS ALL SANTRI) ---
                            if (provider.isMusyrif)
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                icon: Icon(
                                  _onlyMyHalaqah ? Icons.person_pin_rounded : Icons.people_outline_rounded,
                                  color: _onlyMyHalaqah ? AppTheme.primaryGreen : Colors.grey.shade600,
                                  size: 22,
                                ),
                                tooltip: _onlyMyHalaqah ? 'Halaqah Saya' : 'Semua Santri',
                                onPressed: () {
                                  setState(() {
                                      _onlyMyHalaqah = !_onlyMyHalaqah;
                                  });
                                },
                              ),
                            
                            // --- SEARCH ICON (TRIGGERS INLINE SEARCH FIELD) ---
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              icon: Icon(
                                Icons.search_rounded, 
                                color: widget.query.isNotEmpty ? AppTheme.primaryGreen : Colors.grey.shade600,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                            ),
                            
                            // --- FILTER POPUP ---
                            PopupMenuButton<SetoranType?>(
                              icon: Icon(
                                Icons.filter_list_rounded, 
                                color: widget.filterType != null ? AppTheme.primaryGreen : Colors.grey.shade600,
                                size: 22,
                              ),
                              onSelected: widget.onTypeChanged,
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: null, child: Text('Semua')),
                                const PopupMenuItem(value: SetoranType.ziyadah, child: Text('Ziyadah')),
                                const PopupMenuItem(value: SetoranType.murojaah, child: Text('Muroja\'ah')),
                              ],
                            ),
                          ],
                        ),
                ),
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

    return Container(
      color: Colors.transparent, // Blends fully with page background
      child: ListTile(
        onTap: () {
          if (isOrangTua) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SetoranDetailScreen(santri: santri, record: record)));
          } else {
            showSetoranOptions(context, santri, record: record);
          }
        },
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: isOrangTua 
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 20),
            )
          : AppAvatar(name: santri.name, radius: 18, imagePath: santri.photoPath),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isOrangTua ? record.surahEnglishName : santri.name, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              )
            ),
            const SizedBox(width: 8),
            Text(_formatDate(record.date), style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                isOrangTua 
                  ? 'Ayat ${record.ayahStart}-${record.ayahEnd} • ${record.type.label}' 
                  : '${record.surahEnglishName} • Ayat ${record.ayahStart}-${record.ayahEnd}', 
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              )
            ),
            if (!isOrangTua) ...[
              const SizedBox(width: 8),
              _tag(record.type.label, record.type == SetoranType.ziyadah ? AppTheme.primaryGreen : Colors.purple),
            ]
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: const BoxConstraints(minWidth: 40),
          decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            record.finalScore.toStringAsFixed(0), 
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][d.month-1]} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  Widget _tag(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));
}
