import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/core/utils/gamification_utils.dart';
import 'package:tahfidz_app/core/utils/badge_system.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/continuation_dialog.dart';
import 'package:tahfidz_app/features/management/screens/santri_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_history_list.dart';

class SantriDetailScreen extends StatefulWidget {
  const SantriDetailScreen({super.key, required this.santriId});
  final String santriId;

  @override
  State<SantriDetailScreen> createState() => _SantriDetailScreenState();
}

class _SantriDetailScreenState extends State<SantriDetailScreen> {
  int _activeTab = 0; // 0: History, 1: Badges, 2: Info

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppProvider>().listenToActiveSantriHistory(widget.santriId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final santri = provider.getSantriById(widget.santriId);
        if (santri == null) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            body: const Center(child: Text('Santri tidak ditemukan')),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          appBar: AppBar(
            title: Text(
              'DETAIL SANTRI',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (provider.isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri))),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              _buildHeroHeader(santri, isDark),
              const SizedBox(height: 16),
              _buildStatsHUD(santri, isDark),
              const SizedBox(height: 24),
              _buildGameTabs(isDark),
              const SizedBox(height: 16),
              _buildTabContent(santri, provider, isDark),
              const SizedBox(height: 100),
            ],
          ),
          floatingActionButton: provider.isMusyrif
              ? FloatingActionButton.extended(
                  backgroundColor: AppTheme.primaryGreen,
                  onPressed: () => showSetoranOptions(context, santri),
                  icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                  label: const Text('MULAI SETORAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeroHeader(Santri santri, bool isDark) {
    final int level = GamificationUtils.calculateLevel(santri.totalXP);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          AppAvatar(name: santri.name, radius: 36, imagePath: santri.photoPath, activeFrame: santri.activeFrame, streakDays: santri.streakDays),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  santri.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(8)),
                      child: Text('LVL $level', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Text('${santri.totalXP} XP', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (santri.activeTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(santri.activeTitle!.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.gold, letterSpacing: 1)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHUD(Santri santri, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _hudItem(Icons.auto_stories_rounded, santri.estimatedJuz.toStringAsFixed(1), 'JUZ', Colors.purpleAccent, isDark),
          _hudItem(Icons.star_rounded, santri.averageScore > 0 ? santri.averageScore.toStringAsFixed(0) : '-', 'SKOR', AppTheme.gold, isDark),
          _hudItem(Icons.local_fire_department_rounded, '${santri.streakDays}', 'STREAK', Colors.orange, isDark),
          _hudItem(Icons.stars_rounded, '${santri.totalCoins}', 'KOIN', Colors.blueAccent, isDark),
        ],
      ),
    );
  }

  Widget _hudItem(IconData icon, String val, String label, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(val, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildGameTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabBtn(0, 'RIWAYAT', Icons.history_rounded, isDark),
          _tabBtn(1, 'LENCANA', Icons.emoji_events_rounded, isDark),
          _tabBtn(2, 'INFO', Icons.person_search_rounded, isDark),
        ],
      ),
    );
  }

  Widget _tabBtn(int idx, String label, IconData icon, bool isDark) {
    final bool active = _activeTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = idx),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? Colors.white : (isDark ? Colors.white38 : Colors.grey), size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: active ? Colors.white : (isDark ? Colors.white38 : Colors.grey), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Santri santri, AppProvider provider, bool isDark) {
    switch (_activeTab) {
      case 0:
        return _buildAdventureLog(santri, provider, isDark);
      case 1:
        return _buildTrophyRoom(santri, isDark);
      case 2:
        return _buildCharacterInfo(santri, provider, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdventureLog(Santri santri, AppProvider provider, bool isDark) {
    final history = santri.setoranHistory;
    if (history.isEmpty) {
      return _emptyState('Belum ada riwayat setoran.', isDark);
    }
    return Column(
      children: history.map((r) => QuranHistoryCard(santri: santri, record: r)).toList(),
    );
  }

  Widget _buildTrophyRoom(Santri santri, bool isDark) {
    final unlockedIds = santri.unlockedBadges;
    final badges = unlockedIds.map((id) => BadgeSystem.badges[id]).whereType<BadgeInfo>().toList();
    if (badges.isEmpty) {
      return _emptyState('Belum ada lencana yang terbuka.', isDark);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: badges.length,
      itemBuilder: (ctx, i) => _TrophyTile(badge: badges[i], isDark: isDark),
    );
  }

  Widget _buildCharacterInfo(Santri santri, AppProvider provider, bool isDark) {
    final halaqah = provider.getHalaqahById(santri.halaqahId);
    return Column(
      children: [
        _attributeCard('DATA AKADEMIK', [
          _attrRow('NIS/ID', santri.nis ?? santri.id, isDark, Icons.tag_rounded),
          _attrRow('KELAS', santri.kelas ?? 'Umum', isDark, Icons.class_rounded),
          _attrRow('HALAQAH', halaqah?.nama ?? '-', isDark, Icons.flag_rounded),
        ], isDark),
        const SizedBox(height: 16),
        _attributeCard('INFORMASI PERSONAL', [
          _attrRow('GENDER', santri.jenisKelamin == 'P' ? 'PEREMPUAN' : 'LAKI-LAKI', isDark, Icons.wc_rounded),
          _attrRow('WALI', santri.namaOrangTua ?? '-', isDark, Icons.family_restroom_rounded),
          _attrRow('STATUS', santri.status.toUpperCase(), isDark, Icons.verified_user_rounded, color: santri.isAktif ? Colors.green : Colors.red),
        ], isDark),
      ],
    );
  }

  Widget _attributeCard(String title, List<Widget> children, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _attrRow(String key, String val, bool isDark, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(key, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(val, style: TextStyle(color: color ?? (isDark ? Colors.white : const Color(0xFF1E293B)), fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _emptyState(String msg, bool isDark) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.help_outline_rounded, color: isDark ? Colors.white12 : Colors.grey.shade200, size: 64),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TrophyTile extends StatelessWidget {
  const _TrophyTile({required this.badge, required this.isDark});
  final BadgeInfo badge; final bool isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon, size: 32, color: badge.color),
          const SizedBox(height: 8),
          Text(badge.name.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
