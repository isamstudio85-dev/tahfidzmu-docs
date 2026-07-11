import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_history_list.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_ranking_list.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/laporan_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/verification_gate.dart';

import 'package:tahfidz_app/features/management/screens/presensi_history_screen.dart';

class QuranMemorizationScreen extends StatefulWidget {
  const QuranMemorizationScreen({super.key});

  @override
  State<QuranMemorizationScreen> createState() => _QuranMemorizationScreenState();
}

class _QuranMemorizationScreenState extends State<QuranMemorizationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _query = '';
  SetoranType? _filterType;

  @override
  void initState() {
    super.initState();
    // Admin & Pengawas get 4 tabs (including Presensi), others get 3
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context, listen: false);
    final int length = (provider.isAdmin || provider.isPengawas) ? 4 : 3;
    _tabController = TabController(length: length, vsync: this);
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
    final bool showPresensi = provider.isAdmin || provider.isPengawas;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Force consistent gray background
      appBar: AppBar(
        title: Text(
          'Progres Tahfidz',
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
          isScrollable: showPresensi, // Scrollable if many tabs
          tabs: [
            const Tab(text: 'Riwayat'),
            const Tab(text: 'Peringkat'),
            const Tab(text: 'Laporan'),
            if (showPresensi) const Tab(text: 'Presensi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          QuranHistoryList(
            query: _query, 
            filterType: _filterType,
            onQueryChanged: (v) => setState(() => _query = v),
            onTypeChanged: (v) => setState(() => _filterType = v),
          ),
          const QuranRankingList(),
          const _LaporanStatistikTab(),
          if (showPresensi) const PresensiHistoryScreen(),
        ],
      ),
      floatingActionButton: canAddSetoran
          ? FloatingActionButton.extended(
              heroTag: 'fab_setoran_main',
              onPressed: () => _showInputModeSelector(context),
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: const Text('Input Hafalan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryGreen,
            )
          : null,
    );
  }

  void _showInputModeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text(
              'Pilih Metode Input',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _modeOption(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR Santri',
                  sub: 'Jalur Ekspres & Simak Live',
                  color: AppTheme.primaryGreen,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final verifiedSantri = await VerificationGate.show(context: context);
                    if (verifiedSantri != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SetoranFormScreen(santri: verifiedSantri, isQuickModeInitial: false)),
                      );
                    }
                  },
                ),
                const SizedBox(width: 16),
                _modeOption(
                  context,
                  icon: Icons.bolt_rounded,
                  label: 'Mode Cepat',
                  sub: 'Input Manual (Rekap)',
                  color: Colors.orange.shade800,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SetoranFormScreen(isQuickModeInitial: true)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeOption(BuildContext context, {required IconData icon, required String label, required String sub, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              const SizedBox(height: 4),
              Text(sub, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            ],
          ),
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
        final displayList = provider.isOrangTua 
            ? sourceList.where((s) => s.id == provider.linkedSantriId).toList()
            : sourceList;
        final setorans = displayList.expand((s) => s.setoranHistory).toList();
        if (setorans.isEmpty) return _emptyState(Icons.bar_chart_rounded, 'Belum ada data statistik');
        return LaporanScreenBody(setorans: setorans, provider: provider);
      },
    );
  }

  Widget _emptyState(IconData icon, String msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Colors.grey.shade200), const SizedBox(height: 16), Text(msg, style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500))]));
}
