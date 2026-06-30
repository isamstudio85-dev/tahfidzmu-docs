import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/halaqah_data.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/scoring_utils.dart';
import '../widgets/quran_widgets.dart';
import '../widgets/app_avatar.dart';
import 'halaqah_list_screen.dart';
import 'musyrif_list_screen.dart';
import 'santri_list_screen.dart';
import 'santri_detail_screen.dart';
import 'setoran_form_screen.dart';
import 'hadits_screen.dart';
import 'quran_tadarus_screen.dart';
import 'educational_list_screen.dart';
import 'setoran_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        if (provider.isOrangTua) {
          final child = provider.linkedSantri;
          if (child == null) return const Scaffold(body: Center(child: Text('Data tidak ditemukan.')));
          return Scaffold(appBar: AppBar(title: const Text('Dashboard')), body: _OrangTuaDashboard(child: child));
        }
        if (provider.isAdmin) return _AdminDashboard(provider: provider);
        return _MusyrifDashboard(provider: provider);
      },
    );
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
          _actionCard(w, icon: Icons.groups_rounded, label: 'Kelola Halaqah', color: AppTheme.gold, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalaqahListScreen()))),
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
            const SizedBox(height: 24),
            _sectionTitle('Statistik Saya'),
            const SizedBox(height: 12),
            Row(children: [
              _mStatTile('${myHalaqah.length}', 'Halaqah', Icons.groups_rounded, AppTheme.gold),
              const SizedBox(width: 12),
              _mStatTile('${mySantri.length}', 'Santri', Icons.people_alt_rounded, AppTheme.primaryGreen),
            ]),
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
