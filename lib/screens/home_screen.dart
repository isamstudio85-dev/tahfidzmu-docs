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
import 'kelas_list_screen.dart';
import 'santri_list_screen.dart';
import 'santri_detail_screen.dart';
import 'setoran_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        if (provider.isOrangTua) {
          final child = provider.linkedSantri;
          if (child == null) {
            return const Scaffold(
              body: Center(child: Text('Data anak tidak ditemukan.')),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard')),
            body: _OrangTuaDashboard(child: child),
          );
        }
        if (provider.isAdmin) return _AdminDashboard(provider: provider);
        return _MusyrifDashboard(provider: provider);
      },
    );
  }
}

// ignore: unused_element
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
            _buildAdminStats(context),
            const SizedBox(height: 20),
            _buildHalaqahSummary(context),
            const SizedBox(height: 20),
            _buildAdminQuickActions(context),
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
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo: pesantren if set, else TahfidzMU
          Builder(
            builder: (context) {
              final info = provider.pesantrenInfo;
              if (info.hasLogo) {
                return Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(
                    File(info.logoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/TahfidzMU-logo-white.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }
              return Image.asset(
                'assets/images/TahfidzMU-logo-white.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.auto_stories_rounded,
                  size: 56,
                  color: Colors.white70,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TahfidzMU',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.pesantrenName.isNotEmpty
                      ? provider.pesantrenName
                      : 'Nama Pondok Pesantren',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
        _statTile(
          '${provider.santriList.length}',
          'Santri',
          Icons.people_alt_rounded,
          AppTheme.primaryGreen,
        ),
        const SizedBox(width: 8),
        _statTile(
          '${provider.musyrifList.length}',
          'Musyrif',
          Icons.menu_book_rounded,
          const Color(0xFF1565C0),
        ),
        const SizedBox(width: 8),
        _statTile(
          '${provider.kelasList.length}',
          'Kelas',
          Icons.class_rounded,
          const Color(0xFF7B1FA2),
        ),
      ],
    );
  }

  Widget _buildHalaqahSummary(BuildContext context) {
    final halaqahs = provider.halaqahList;
    if (halaqahs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ringkasan Halaqah',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HalaqahListScreen()),
              ),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: halaqahs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final h = halaqahs[i];
              final musyrif = provider.getMusyrifById(h.musyrifId);
              final count = provider.getSantriByHalaqah(h.id).length;
              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.nama,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      musyrif?.nama ?? 'Belum ada musyrif',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 13,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count santri',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            h.level,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFF57F17),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - 10;
        if (maxWidth <= 0) return const SizedBox.shrink();
        final cardWidth = maxWidth / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionCard(
              cardWidth,
              icon: Icons.people_alt_rounded,
              label: 'Kelola\nSantri',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SantriListScreen()),
              ),
            ),
            _actionCard(
              cardWidth,
              icon: Icons.groups_rounded,
              label: 'Kelola\nHalaqah',
              color: AppTheme.gold,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HalaqahListScreen()),
              ),
            ),
            _actionCard(
              cardWidth,
              icon: Icons.person_rounded,
              label: 'Kelola\nMusyrif',
              color: const Color(0xFF7B1FA2),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MusyrifListScreen()),
              ),
            ),
            _actionCard(
              cardWidth,
              icon: Icons.class_rounded,
              label: 'Kelola\nKelas',
              color: const Color(0xFF009688),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelasListScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statTile(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    double width, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent Setoran Tile ─────────────────────────────────────────────────────────

class _RecentSetoranTile extends StatelessWidget {
  const _RecentSetoranTile({
    required this.santriName,
    required this.santriId,
    required this.record,
  });
  final String santriName;
  final String santriId;
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SantriDetailScreen(santriId: santriId),
          ),
        ),
        leading: AppAvatar(name: santriName, radius: 22),
        title: Text(
          santriName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record.surahEnglishName} Ayat ${record.ayahStart}–${record.ayahEnd}',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  record.type == SetoranType.ziyadah
                      ? Icons.trending_up_rounded
                      : Icons.autorenew_rounded,
                  size: 16,
                  color: record.type == SetoranType.ziyadah
                      ? AppTheme.primaryGreen
                      : const Color(0xFF7B1FA2),
                ),
                const SizedBox(width: 6),
                Text(
                  record.finalScore.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                StarRatingWidget(rating: record.starCount, size: 14),
              ],
            ),
          ],
        ),
        trailing: const SizedBox.shrink(),
      ),
    );
  }
}

// ── Musyrif Dashboard ─────────────────────────────────────────────────────────

// ignore: unused_element
class _MusyrifDashboard extends StatelessWidget {
  const _MusyrifDashboard({required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final musyrif = provider.linkedMusyrif;
    final myHalaqah = musyrif != null
        ? provider.halaqahList.where((h) => h.musyrifId == musyrif.id).toList()
        : <HalaqahData>[];
    final mySantri = musyrif != null
        ? provider.getSantriByMusyrif(musyrif.id)
        : provider.santriList;
    final recentSetorans = <(String, String, SetoranRecord)>[];
    for (final s in mySantri) {
      for (final r in s.setoranHistory) {
        recentSetorans.add((s.name, s.id, r));
      }
    }
    recentSetorans.sort((a, b) => b.$3.date.compareTo(a.$3.date));
    final recent = recentSetorans.take(6).toList();

    return Scaffold(
      appBar: AppBar(title: Text(musyrif != null ? 'Beranda' : 'Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_musyrif_setoran',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetoranFormScreen()),
        ),
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Mulai Setoran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Musyrif header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AppAvatar(
                    name: musyrif?.nama ?? 'Musyrif',
                    radius: 30,
                    imagePath: musyrif?.photoPath,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musyrif?.nama ?? 'Musyrif',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          musyrif?.jabatan ?? 'Musyrif / Musyrifah',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (musyrif?.lembaga != null)
                          Text(
                            musyrif!.lembaga,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _mStatTile(
                  '${myHalaqah.length}',
                  'Halaqah Saya',
                  Icons.groups_rounded,
                  AppTheme.gold,
                ),
                const SizedBox(width: 12),
                _mStatTile(
                  '${mySantri.length}',
                  'Santri Saya',
                  Icons.people_alt_rounded,
                  AppTheme.primaryGreen,
                ),
                const SizedBox(width: 12),
                _mStatTile(
                  '${recent.length}',
                  'Setoran Terkini',
                  Icons.menu_book_rounded,
                  const Color(0xFF7B1FA2),
                ),
              ],
            ),

            // Halaqah saya
            if (myHalaqah.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Halaqah Saya',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...myHalaqah.map((h) {
                final count = provider.getSantriByHalaqah(h.id).length;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: AppTheme.primaryGreen,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      h.nama,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${h.level}${h.jadwal != null ? ' · ${h.jadwal}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            color: AppTheme.primaryGreen,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Recent setorans
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Setoran Terkini',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SantriListScreen(),
                      ),
                    ),
                    child: const Text('Lihat Semua'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 54,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada setoran santri Anda',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recent.map(
                (item) => _RecentSetoranTile(
                  santriName: item.$1,
                  santriId: item.$2,
                  record: item.$3,
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _mStatTile(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── OrangTua Dashboard ─────────────────────────────────────────────────────────

// ignore: unused_element
class _OrangTuaDashboard extends StatelessWidget {
  const _OrangTuaDashboard({required this.child});
  final Santri child;

  @override
  Widget build(BuildContext context) {
    final setorans = child.setoranHistory.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final avg = child.averageScore;
    final grade = ScoringUtils.scoreToGrade(avg);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: child.name,
                  radius: 32,
                  imagePath: (child.photoPath?.isNotEmpty ?? false)
                      ? child.photoPath
                      : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (child.kelas != null)
                        Text(
                          child.kelas!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      if (child.targetHafalan != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              color: Colors.white60,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${child.targetHafalan}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Stats ───────────────────────────────────────────────────────
          Row(
            children: [
              _orangTuaStat(
                icon: Icons.list_alt_rounded,
                label: 'Total Setoran',
                value: '${setorans.length}',
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 12),
              _orangTuaStat(
                icon: Icons.star_rounded,
                label: 'Rata-rata',
                value: avg > 0 ? avg.toStringAsFixed(1) : '-',
                color: AppTheme.gold,
              ),
              const SizedBox(width: 12),
              _orangTuaStat(
                icon: Icons.emoji_events_rounded,
                label: 'Predikat',
                value: grade,
                color: const Color(0xFF7B1FA2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SantriDetailScreen(santriId: child.id),
                ),
              ),
              icon: const Icon(Icons.person_search_rounded),
              label: const Text('Lihat Profil'),
            ),
          ),
          const SizedBox(height: 24),

          // ── Riwayat setoran ─────────────────────────────────────────────
          Text(
            'Riwayat Setoran',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (setorans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada riwayat setoran',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ),
            )
          else
            ...setorans
                .take(20)
                .map(
                  (r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      title: Text(
                        '${r.surahEnglishName} Ayat ${r.ayahStart}–${r.ayahEnd}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${r.type.label} · ${_formatDate(r.date)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            r.finalScore.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          StarRatingWidget(rating: r.starCount, size: 12),
                        ],
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _orangTuaStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
