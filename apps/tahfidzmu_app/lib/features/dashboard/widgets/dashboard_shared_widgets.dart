import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';
import 'package:tahfidz_app/features/education/screens/memorization_quest_screen.dart';
import 'package:tahfidz_app/features/gamification/screens/reward_store_screen.dart';
import 'package:tahfidz_app/features/gamification/screens/my_vouchers_screen.dart';
import 'package:tahfidz_app/core/utils/gamification_utils.dart';
import 'package:tahfidz_app/core/utils/badge_system.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class GamificationCard extends StatelessWidget {
  const GamificationCard({super.key, required this.santri});
  final Santri santri;

  @override
  Widget build(BuildContext context) {
    final int level = GamificationUtils.calculateLevel(santri.totalXP);
    final String title = GamificationUtils.getLevelTitle(level);
    final double progress = GamificationUtils.levelProgress(santri.totalXP);
    final int nextLevelXP = GamificationUtils.xpForLevel(level + 1);
    final String xpText = '${santri.totalXP} / $nextLevelXP XP';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.5), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0B1914), const Color(0xFF143026)]
              : [const Color(0xFF004D40), const Color(0xFF00796B)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Level Badge with Gold Glow
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'LVL',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '$level',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Title & XP info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${santri.totalCoins}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            xpText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Shop & Voucher Buttons
                Row(
                  children: [
                    _actionButton(
                      context,
                      icon: Icons.confirmation_number_rounded,
                      color: Colors.orangeAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyVouchersScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      context,
                      icon: Icons.storefront_rounded,
                      color: AppTheme.gold,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RewardStoreScreen(santri: santri)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Badges Row (More Compact)
            if (santri.unlockedBadges.isNotEmpty) ...[
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: santri.unlockedBadges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final badgeId = santri.unlockedBadges[index];
                    final badge = BadgeSystem.badges[badgeId];
                    if (badge == null) return const SizedBox.shrink();
                    return _badgeIcon(badge, isDark);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PROGRES LEVEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1)),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.gold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black26,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _badgeIcon(BadgeInfo badge, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: badge.color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: badge.color.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Tooltip(
        message: '${badge.name}: ${badge.description}',
        child: Icon(badge.icon, color: badge.color, size: 20),
      ),
    );
  }
}

class PusatHafalanPortalCard extends StatelessWidget {
  const PusatHafalanPortalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemorizationQuestScreen()),
          ),
          child: Stack(
            children: [
              // Background Gradient
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                        ? [AppTheme.primaryGreen, AppTheme.darkGreen]
                        : [AppTheme.primaryGreen, const Color(0xFF059669)],
                    ),
                  ),
                ),
              ),
              // Decoration Icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.explore_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PUSAT HAFALAN',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Mulai setoran harian & tingkatkan levelmu!',
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  const EmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }
}

class RecentSetoranTile extends StatelessWidget {
  const RecentSetoranTile({super.key, required this.santri, required this.record});
  final Santri santri;
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    final bool isOrangTua = context.read<AppProvider>().isOrangTua;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () {
          if (isOrangTua) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SetoranDetailScreen(santri: santri, record: record),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: santri.id)),
            );
          }
        },
        leading: isOrangTua
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryGreen, size: 20),
              )
            : AppAvatar(name: santri.name, radius: 22, imagePath: santri.photoPath),
        title: Text(
          isOrangTua ? record.surahEnglishName : santri.name,
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isOrangTua
              ? 'Ayat ${record.ayahStart}-${record.ayahEnd}${record.totalLines != null ? " (${record.totalLines} baris)" : ""} • ${record.type.label}'
              : '${record.surahEnglishName} • Ayat ${record.ayahStart}-${record.ayahEnd}${record.totalLines != null ? " (${record.totalLines} baris)" : ""}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


