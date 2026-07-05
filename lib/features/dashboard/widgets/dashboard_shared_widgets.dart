import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/education/screens/hadits_screen.dart';
import 'package:tahfidz_app/features/education/screens/quran_tadarus_screen.dart';
import 'package:tahfidz_app/features/education/screens/educational_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.black87,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          isOrangTua
              ? 'Ayat ${record.ayahStart}-${record.ayahEnd} • ${record.type.label}'
              : '${record.surahEnglishName} • Ayat ${record.ayahStart}-${record.ayahEnd}',
          style: const TextStyle(fontSize: 12),
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

class HafalanMenuSection extends StatelessWidget {
  const HafalanMenuSection({super.key, required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    final modules = [
      (
        title: 'Al-Quran Digital',
        sub: 'Membaca & Tadarus Al-Quran',
        icon: Icons.menu_book_rounded,
        color: Colors.teal,
        type: 'quran'
      ),
      if (provider.isModuleActive('hadits'))
        (
          title: 'Hadits Pilihan',
          sub: 'Kumpulan hadits shahih',
          icon: Icons.import_contacts_rounded,
          color: Colors.orange,
          type: 'hadits'
        ),
      if (provider.isModuleActive('tajwid'))
        (
          title: 'Ilmu Tajwid',
          sub: 'Hukum bacaan Al-Quran',
          icon: Icons.auto_stories_rounded,
          color: Colors.blue,
          type: 'tajwid'
        ),
      if (provider.isModuleActive('tahsin'))
        (
          title: 'Ilmu Tahsin',
          sub: 'Fasih & Makharijul huruf',
          icon: Icons.record_voice_over_rounded,
          color: Colors.deepPurple,
          type: 'tahsin'
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Menu Hafalan'),
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
