import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/presensi_halaqah.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class PresensiHistoryScreen extends StatefulWidget {
  const PresensiHistoryScreen({super.key});

  @override
  State<PresensiHistoryScreen> createState() => _PresensiHistoryScreenState();
}

class _PresensiHistoryScreenState extends State<PresensiHistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final List<PresensiHalaqah> sortedPresensi = List.from(provider.presensiList)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    final filteredPresensi = sortedPresensi.where((p) {
      final matchesHalaqah = p.halaqahNama.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMusyrif = p.musyrifNama.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesHalaqah || matchesMusyrif;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Presensi Halaqah'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari Halaqah atau Musyrif...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredPresensi.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredPresensi.length,
                    itemBuilder: (context, index) {
                      final presensi = filteredPresensi[index];
                      return _PresensiRecordCard(presensi: presensi);
                    },
                  ),
          ),
        ],
      ),
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
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(presensi.tanggal);
    final timeStr = DateFormat('HH:mm').format(presensi.waktuSubmit);

    final stats = _calculateStats();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: ExpansionTile(
        title: Text(
          presensi.halaqahNama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Musyrif: ${presensi.musyrifNama}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text('$dateStr • $timeStr WIB', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 24),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildStatRow(stats),
                const SizedBox(height: 12),
                const Text(
                  'Daftar Kehadiran Santri:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
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
    );
  }

  Widget _buildStatRow(Map<String, int> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _miniStat('Hadir', stats['hadir'] ?? 0, Colors.green),
        _miniStat('Sakit', stats['sakit'] ?? 0, Colors.orange),
        _miniStat('Izin', stats['izin'] ?? 0, Colors.blue),
        _miniStat('Alfa', stats['alfa'] ?? 0, Colors.red),
      ],
    );
  }

  Widget _miniStat(String label, int val, Color color) {
    return Column(
      children: [
        Text('$val', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
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

    Color color;
    String label;

    switch (status) {
      case 'setoran':
        color = Colors.green;
        label = 'Hadir (Setoran)';
        break;
      case 'ditunda':
        color = Colors.teal;
        label = 'Hadir (Belum Sesi)';
        break;
      case 'sakit':
        color = Colors.orange;
        label = 'Sakit';
        break;
      case 'izin':
        color = Colors.blue;
        label = 'Izin';
        break;
      case 'alfa':
        color = Colors.red;
        label = 'Alfa';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              (santri?.name ?? 'S')[0],
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              santri?.name ?? 'Santri ID: $santriId',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
