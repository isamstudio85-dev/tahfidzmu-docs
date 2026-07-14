import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/presensi_halaqah.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class PresensiHistoryScreen extends StatefulWidget {
  const PresensiHistoryScreen({super.key, this.hideAppBar = false});
  final bool hideAppBar;

  @override
  State<PresensiHistoryScreen> createState() => _PresensiHistoryScreenState();
}

class _PresensiHistoryScreenState extends State<PresensiHistoryScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AppProvider>();
    final List<PresensiHalaqah> sortedPresensi = List.from(provider.presensiList)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    final filteredPresensi = sortedPresensi.where((p) {
      final matchesHalaqah = p.halaqahNama.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMusyrif = p.musyrifNama.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesHalaqah || matchesMusyrif;
    }).toList();

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Cari Halaqah atau Musyrif...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: isDark ? AppTheme.darkSurface : Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        if (widget.hideAppBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  'LOG KEHADIRAN HALAQAH',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, 
                    fontSize: 10, 
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredPresensi.length} Data',
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : Colors.grey.shade400, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        Expanded(
          child: filteredPresensi.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filteredPresensi.length,
                  itemBuilder: (context, index) {
                    final presensi = filteredPresensi[index];
                    return _PresensiRecordCard(presensi: presensi);
                  },
                ),
        ),
      ],
    );

    if (widget.hideAppBar) {
      return Container(
        color: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Riwayat Presensi')),
      body: body,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada data presensi.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _PresensiRecordCard extends StatelessWidget {
  const _PresensiRecordCard({required this.presensi});
  final PresensiHalaqah presensi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(presensi.tanggal);
    final timeStr = DateFormat('HH:mm').format(presensi.waktuSubmit);

    final stats = _calculateStats();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          title: Text(
            presensi.halaqahNama.toUpperCase(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900, 
              fontSize: 14, 
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_pin_rounded, size: 12, color: AppTheme.primaryGreen.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Musyrif: ${presensi.musyrifNama}', 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('$dateStr • $timeStr WIB', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500)),
            ],
          ),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_rounded, color: AppTheme.primaryGreen, size: 24),
              ),
              // THE STAMP
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white, 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                ),
              ),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 16),
                  // Tactical Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                    ),
                    child: _buildStatRow(stats),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SANTRI MISSION LOG:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900, 
                      fontSize: 9, 
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...presensi.daftarHadir.entries.map((entry) {
                    return _SantriPresenceTile(
                      santriId: entry.key,
                      status: entry.value,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(Map<String, int> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _miniStat('COMPLETED', stats['hadir'] ?? 0, Colors.green),
        _miniStat('INJURED', stats['sakit'] ?? 0, Colors.orange),
        _miniStat('AWAY', stats['izin'] ?? 0, Colors.blue),
        _miniStat('MISSING', stats['alfa'] ?? 0, Colors.red),
      ],
    );
  }

  Widget _miniStat(String label, int val, Color color) {
    return Column(
      children: [
        Text(
          '$val', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, color: color, fontSize: 18)
        ),
        Text(
          label, 
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)
        ),
      ],
    );
  }

  Map<String, int> _calculateStats() {
    int hadir = 0;
    int sakit = 0;
    int izin = 0;
    int alfa = 0;

    for (var status in presensi.daftarHadir.values) {
      if (status == 'setoran' || status == 'ditunda') {
        hadir++;
      } else if (status == 'sakit') {
        sakit++;
      } else if (status == 'izin') {
        izin++;
      } else if (status == 'alfa') {
        alfa++;
      }
    }

    return {'hadir': hadir, 'sakit': sakit, 'izin': izin, 'alfa': alfa};
  }
}

class _SantriPresenceTile extends StatelessWidget {
  const _SantriPresenceTile({required this.santriId, required this.status});
  final String santriId;
  final String status;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final santri = provider.getSantriById(santriId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color color;
    String label;

    switch (status) {
      case 'setoran':
        color = Colors.green;
        label = 'COMPLETED';
        break;
      case 'ditunda':
        color = Colors.teal;
        label = 'WAITING';
        break;
      case 'sakit':
        color = Colors.orange;
        label = 'INJURED';
        break;
      case 'izin':
        color = Colors.blue;
        label = 'AWAY';
        break;
      case 'alfa':
        color = Colors.red;
        label = 'MISSING';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Status Orb
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              santri?.name ?? 'Santri ID: $santriId',
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
