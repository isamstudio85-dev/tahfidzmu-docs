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

class QuranHistoryList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        List<(Santri, SetoranRecord)> allRecords = [];
        final sourceList = provider.isMusyrif && provider.linkedMusyrif != null
            ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id)
            : provider.santriList;

        final displayList = provider.isOrangTua 
            ? sourceList.where((s) => s.id == provider.linkedSantriId).toList()
            : sourceList;

        for (var s in displayList) {
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
                    onSelected: onTypeChanged,
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
                  itemBuilder: (ctx, i) => QuranHistoryCard(santri: filtered[i].$1, record: filtered[i].$2),
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
          _statBox('Total Baris', '${records.length}', Colors.blue),
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
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      color: Colors.white,
      elevation: 0.5,
      child: ListTile(
        onTap: () {
          if (isOrangTua) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SetoranDetailScreen(santri: santri, record: record)));
          } else {
            showSetoranOptions(context, santri, record: record);
          }
        },
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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

  String _formatDate(DateTime d) => '${d.day} ${['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'][d.month-1]}';
  Widget _tag(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));
}
