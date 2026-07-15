import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

import 'hadits_screen.dart';
import 'quran_tadarus_screen.dart';
import 'educational_list_screen.dart';
import 'tahsin_list_screen.dart';
import 'pondok_knowledge_screen.dart';

class MemorizationQuestScreen extends StatelessWidget {
  const MemorizationQuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: const Text('PUSAT HAFALAN'),
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('MODUL UTAMA', Icons.auto_awesome_rounded, isDark),
            const SizedBox(height: 12),
            _QuestTile(
              title: 'Al-Quran Al-Karim',
              subtitle: 'Misi Utama: Tadarus & Hafalan',
              icon: Icons.menu_book_rounded,
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranTadarusScreen())),
              isPrimary: true,
              isDark: isDark,
            ),
            
            if (provider.isModuleActive('hadits')) ...[
              const SizedBox(height: 32),
              _sectionHeader('MODUL TAMBAHAN', Icons.import_contacts_rounded, isDark),
              const SizedBox(height: 12),
              _QuestTile(
                title: 'Hadits Pilihan',
                subtitle: 'Kumpulan hadits-hadits shahih',
                icon: Icons.library_books_rounded,
                color: Colors.orange.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaditsScreen())),
                isDark: isDark,
              ),
            ],

            const SizedBox(height: 32),
            _sectionHeader('WAWASAN & ILMU', Icons.bolt_rounded, isDark),
            Builder(
              builder: (context) {
                final List<Widget> listItems = [];
                
                if (provider.isModuleActive('fiqih')) {
                  listItems.add(
                    _buildListTile(
                      title: 'Fiqih',
                      subtitle: 'Belajar tata cara ibadah & hukum islam',
                      icon: Icons.menu_book_rounded,
                      color: Colors.brown,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationalListScreen(type: 'fiqih'))),
                      isDark: isDark,
                    ),
                  );
                }
                if (provider.isModuleActive('tajwid')) {
                  listItems.add(
                    _buildListTile(
                      title: 'Tajwid',
                      subtitle: 'Pedoman hukum membaca Al-Quran dengan benar',
                      icon: Icons.auto_stories_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EducationalListScreen(type: 'tajwid'))),
                      isDark: isDark,
                    ),
                  );
                }
                if (provider.isModuleActive('tahsin')) {
                  listItems.add(
                    _buildListTile(
                      title: 'Tahsin',
                      subtitle: 'Latihan makharijul huruf & pembetulan bacaan',
                      icon: Icons.record_voice_over_rounded,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TahsinListScreen())),
                      isDark: isDark,
                    ),
                  );
                }
                if (provider.isModuleActive('pondok_info')) {
                  final String pondokName = provider.pesantrenInfo.nama.trim();
                  listItems.add(
                    _buildListTile(
                      title: pondokName.isNotEmpty ? pondokName : 'Pondok',
                      subtitle: 'Wawasan sejarah & kepondokan pesantren',
                      icon: Icons.school_rounded,
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PondokKnowledgeScreen())),
                      isDark: isDark,
                    ),
                  );
                }

                if (listItems.isEmpty) return const SizedBox.shrink();

                final List<Widget> childrenWithDividers = [];
                for (int i = 0; i < listItems.length; i++) {
                  childrenWithDividers.add(listItems[i]);
                  if (i < listItems.length - 1) {
                    childrenWithDividers.add(
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        indent: 76,
                      ),
                    );
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, width: 1.2),
                    ),
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: childrenWithDividers,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: Opacity(
                opacity: 0.3,
                child: Column(
                  children: [
                    const Icon(Icons.explore_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Jelajahi terus ilmu Allah\ndan tingkatkan level pahlawanmu!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.white38 : Colors.grey, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: isDark ? Colors.white38 : Colors.grey,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: isPrimary ? [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withValues(alpha: 0.2), width: 2),
        ),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

