import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/models/halaqah_data.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/halaqah_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_form_screen.dart';
import 'package:tahfidz_app/features/education/screens/hadits_screen.dart';
import 'package:tahfidz_app/features/education/screens/quran_tadarus_screen.dart';
import 'package:tahfidz_app/features/education/screens/educational_list_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/tasmi_form_screen.dart';

import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _popupShownInSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_popupShownInSession) {
        _showMotivationalPopup();
        _popupShownInSession = true;
      }
    });
  }

  void _showMotivationalPopup() {
    final provider = context.read<AppProvider>();
    final activeEvents = provider.graduationEvents.where((e) => e.isPublished).toList();
    if (activeEvents.isEmpty) return;

    final event = activeEvents.first;
    final candidatesCount = provider.santriList.where((s) => s.tasmiHistory.any((t) => t.year == event.year && t.isPass)).length;

    // The popup appears for all users (Admin, Musyrif, and Parents)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image or Icon Header
            if (event.bannerPath != null)
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: event.bannerPath!.startsWith('assets/')
                        ? AssetImage(event.bannerPath!) as ImageProvider
                        : FileImage(File(event.bannerPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.purple.withValues(alpha: 0.1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 80, color: AppTheme.gold.withValues(alpha: 0.2)),
                    const Icon(Icons.school_rounded, size: 50, color: Colors.purple),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('AYO SEMANGAT!', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.purple, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('Pendaftaran ${event.title} Telah Dibuka!', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text('$candidatesCount Santri Sudah Lulus Seleksi', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Jangan sampai ketinggalan momen berharga ini. Tingkatkan hafalanmu dan jadilah penjaga Al-Quran selanjutnya!', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => GraduationPortalScreen(event: event)));
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                      child: const Text('LIHAT DETAIL WISUDA'),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final role = provider.currentRole;

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (provider.isOrangTua) {
      final child = provider.linkedSantri;
      if (child == null) return const Scaffold(body: Center(child: Text('Data tidak ditemukan.')));
      return Scaffold(appBar: AppBar(title: const Text('Dashboard')), body: _OrangTuaDashboard(child: child));
    }
    if (provider.isAdmin) return _AdminDashboard(provider: provider);
    return _MusyrifDashboard(provider: provider);
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard({required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(context),
            const SizedBox(height: 20),
            _buildGraduationBanner(context, provider),
            const SizedBox(height: 24),
            _buildAdminStats(context),
            const SizedBox(height: 24),
            _sectionTitle('Aksi Cepat'),
            const SizedBox(height: 12),
            _buildAdminQuickActions(context),
            const SizedBox(height: 24),
            _sectionTitle('Ringkasan Halaqah'),
            const SizedBox(height: 12),
            _buildHalaqahList(context),
            const SizedBox(height: 24),
            _HafalanMenuSection(provider: provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGraduationBanner(BuildContext context, AppProvider provider) {
    final activeEvents = provider.graduationEvents.where((e) => e.isPublished).toList();
    if (activeEvents.isEmpty) return const SizedBox.shrink();

    final event = activeEvents.first;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GraduationPortalScreen(event: event))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.school_rounded, color: Colors.purple, size: 24),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Lihat informasi wisuda & hasil ujian', style: TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
          child: const Text('INFO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.darkGreen, AppTheme.primaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/TahfidzMU-logo-white.png', width: 60, height: 60, errorBuilder: (_, __, ___) => const Icon(Icons.auto_stories_rounded, size: 40, color: Colors.white70)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TahfidzMU', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(provider.pesantrenName, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStats(BuildContext context) {
    return Row(
      children: [
        _statTile('${provider.santriList.length}', 'Santri', Icons.people_alt_rounded, Colors.blue),
        const SizedBox(width: 12),
        _statTile('${provider.musyrifList.length}', 'Musyrif', Icons.person_pin_rounded, Colors.orange),
        const SizedBox(width: 12),
        _statTile('${provider.halaqahList.length}', 'Halaqah', Icons.groups_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildHalaqahList(BuildContext context) {
    final halaqahs = provider.halaqahList;
    if (halaqahs.isEmpty) return _emptyState('Belum ada data halaqah.');
    return Column(
      children: halaqahs.take(5).map((h) {
        final count = provider.getSantriByHalaqah(h.id).length;
        final m = provider.getMusyrifById(h.musyrifId);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: h.photoPath != null
                  ? Image.file(File(h.photoPath!), fit: BoxFit.cover)
                  : const Icon(Icons.groups_rounded, color: AppTheme.primaryGreen),
            ),
            title: Text(h.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(m?.nama ?? 'Tanpa Pembimbing', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('$count Santri', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12, runSpacing: 12,
        children: [
          _actionCard(w, icon: Icons.people_alt_rounded, label: 'Kelola Santri', color: const Color(0xFF1565C0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SantriListScreen()))),
          _actionCard(w, icon: Icons.school_rounded, label: 'Ujian Tasmi\'', color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasmiFormScreen()))),
        ],
      );
    });
  }

  Widget _statTile(String value, String label, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: color))), Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600))]),
    ));
  }

  Widget _actionCard(double w, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(width: w, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))]),
    )));
  }
}

class _MusyrifDashboard extends StatelessWidget {
  const _MusyrifDashboard({required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final musyrif = provider.linkedMusyrif;
    final myHalaqah = musyrif != null ? provider.halaqahList.where((h) => h.musyrifId == musyrif.id).toList() : <HalaqahData>[];
    final mySantri = musyrif != null ? provider.getSantriByMusyrif(musyrif.id) : provider.santriList;
    final recent = <(Santri, SetoranRecord)>[];
    for (final s in mySantri) { for (final r in s.setoranHistory) { recent.add((s, r)); } }
    recent.sort((a, b) => b.$2.date.compareTo(a.$2.date));

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Musyrif')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_m_setoran', 
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetoranFormScreen())), 
        icon: const Icon(Icons.mic_rounded), 
        label: const Text('Input Hafalan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(height: 20),
            _buildGraduationBanner(context, provider),
            const SizedBox(height: 24),
            _sectionTitle('Statistik Saya'),
            const SizedBox(height: 12),
            Row(children: [
              _mStatTile('${myHalaqah.length}', 'Halaqah', Icons.groups_rounded, AppTheme.gold),
              const SizedBox(width: 12),
              _mStatTile('${mySantri.length}', 'Santri', Icons.people_alt_rounded, AppTheme.primaryGreen),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasmiFormScreen())),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Mulai Ujian Tasmi\''),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.purple, side: const BorderSide(color: Colors.purple)),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Aktivitas Terkini'),
            const SizedBox(height: 12),
            if (recent.isEmpty) _emptyState('Belum ada riwayat hafalan dari santri Anda.')
            else ...recent.take(5).map((item) => _RecentSetoranTile(santri: item.$1, record: item.$2)),
            const SizedBox(height: 24),
            _HafalanMenuSection(provider: provider),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildGraduationBanner(BuildContext context, AppProvider provider) {
    final activeEvents = provider.graduationEvents.where((e) => e.isPublished).toList();
    if (activeEvents.isEmpty) return const SizedBox.shrink();

    final event = activeEvents.first;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GraduationPortalScreen(event: event))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.school_rounded, color: Colors.purple, size: 24),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Lihat informasi wisuda & hasil ujian', style: TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
          child: const Text('INFO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final m = provider.linkedMusyrif;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.darkGreen, AppTheme.primaryGreen]), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          AppAvatar(name: m?.nama ?? 'Musyrif', radius: 30, imagePath: m?.photoPath, backgroundColor: Colors.white24, foregroundColor: Colors.white),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m?.nama ?? 'Musyrif', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(m?.jabatan ?? 'Pembimbing', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
          Opacity(opacity: 0.5, child: Image.asset('assets/images/TahfidzMU-logo-white.png', width: 40, height: 40)),
        ],
      ),
    );
  }

  Widget _mStatTile(String value, String label, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: color))), Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600))]),
    ));
  }
}

class _OrangTuaDashboard extends StatelessWidget {
  const _OrangTuaDashboard({required this.child});
  final Santri child;

  @override
  Widget build(BuildContext context) {
    final setorans = child.setoranHistory.toList()..sort((a, b) => b.date.compareTo(a.date));
    final avg = child.averageScore;
    final grade = ScoringUtils.scoreToGrade(avg);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBanner(),
          const SizedBox(height: 20),
          _buildGraduationBanner(context, context.read<AppProvider>()),
          const SizedBox(height: 24),
          Row(
            children: [
              _oStat(Icons.list_alt_rounded, 'Total Baris', '${setorans.length}', AppTheme.primaryGreen),
              const SizedBox(width: 12),
              _oStat(Icons.star_rounded, 'Rata-rata', avg > 0 ? avg.toStringAsFixed(0) : '-', AppTheme.gold),
              const SizedBox(width: 12),
              _oStat(Icons.emoji_events_rounded, 'Predikat', grade, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle('Riwayat Terbaru'),
          const SizedBox(height: 12),
          if (setorans.isEmpty) _emptyState('Belum ada riwayat setoran.')
          else ...setorans.take(5).map((r) => _RecentSetoranTile(santri: child, record: r)),
          const SizedBox(height: 24),
          _HafalanMenuSection(provider: context.read<AppProvider>()),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: child.id))), icon: const Icon(Icons.person_search_rounded), label: const Text('Lihat Detail Lengkap'))),
        ],
      ),
    );
  }

  Widget _buildGraduationBanner(BuildContext context, AppProvider provider) {
    final activeEvents = provider.graduationEvents.where((e) => e.isPublished).toList();
    if (activeEvents.isEmpty) return const SizedBox.shrink();

    final event = activeEvents.first;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GraduationPortalScreen(event: event))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.school_rounded, color: Colors.purple, size: 24),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Lihat informasi wisuda & hasil ujian', style: TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
          child: const Text('INFO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9)),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          AppAvatar(name: child.name, radius: 32, imagePath: child.photoPath, backgroundColor: Colors.white24, foregroundColor: Colors.white),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(child.name, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            if (child.targetHafalan != null) Text('Target: ${child.targetHafalan}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Opacity(opacity: 0.3, child: Image.asset('assets/images/TahfidzMU-logo-white.png', width: 40, height: 40)),
        ],
      ),
    );
  }

  Widget _oStat(IconData icon, String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(children: [
        Icon(icon, color: color, size: 24), 
        const SizedBox(height: 8), 
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color))), 
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1),
      ]),
    ));
  }
}

class _HafalanMenuSection extends StatelessWidget {
  const _HafalanMenuSection({required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final modules = [
      (title: 'Al-Quran Digital', sub: 'Membaca & Tadarus Al-Quran', icon: Icons.menu_book_rounded, color: Colors.teal, type: 'quran'),
      if (provider.isModuleActive('hadits'))
        (title: 'Hadits Pilihan', sub: 'Kumpulan hadits shahih', icon: Icons.import_contacts_rounded, color: Colors.orange, type: 'hadits'),
      if (provider.isModuleActive('tajwid')) 
        (title: 'Ilmu Tajwid', sub: 'Hukum bacaan Al-Quran', icon: Icons.auto_stories_rounded, color: Colors.blue, type: 'tajwid'),
      if (provider.isModuleActive('tahsin'))
        (title: 'Ilmu Tahsin', sub: 'Fasih & Makharijul huruf', icon: Icons.record_voice_over_rounded, color: Colors.deepPurple, type: 'tahsin'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Menu Hafalan'),
        const SizedBox(height: 12),
        ...modules.map((m) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            onTap: () {
              if (m.type == 'quran') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranTadarusScreen()));
              } else if (m.type == 'hadits') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HaditsScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EducationalListScreen(type: m.type)));
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: m.color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(m.icon, color: m.color, size: 20),
            ),
            title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(m.sub, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
          ),
        )),
      ],
    );
  }
}

class _RecentSetoranTile extends StatelessWidget {
  const _RecentSetoranTile({required this.santri, required this.record});
  final Santri santri; final SetoranRecord record;
  @override
  Widget build(BuildContext context) {
    final bool isOrangTua = context.read<AppProvider>().isOrangTua;
    return Card(
      margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: () {
          if (isOrangTua) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SetoranDetailScreen(santri: santri, record: record)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id)));
          }
        },
        leading: isOrangTua 
          ? Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 20))
          : AppAvatar(name: santri.name, radius: 22, imagePath: santri.photoPath),
        title: Text(isOrangTua ? record.surahEnglishName : santri.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(isOrangTua ? 'Ayat ${record.ayahStart}-${record.ayahEnd} • ${record.type.label}' : '${record.surahEnglishName} • Ayat ${record.ayahStart}-${record.ayahEnd}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
                Text(
                  record.finalScore.toStringAsFixed(0),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(String t) => Text(t, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87));
Widget _emptyState(String m) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(m, style: TextStyle(color: Colors.grey.shade400))));
