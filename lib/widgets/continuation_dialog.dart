import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../providers/app_provider.dart';
import 'package:tahfidz_app/screens/musyrif/quran_reader_screen.dart';
import 'package:tahfidz_app/screens/musyrif/setoran_form_screen.dart';
import '../theme/app_theme.dart';
import 'app_avatar.dart';

/// Shows a bottom sheet with two choices:
///  1. **Lanjut** — directly start from the detected next position
///  2. **Pilih Manual** — open the form pre-filled (user can adjust)
///
/// If the santri has no history (or surah list not loaded), opens the form
/// directly without a dialog.
Future<void> showSetoranOptions(BuildContext context, Santri santri) async {
  final provider = context.read<AppProvider>();
  final continuation = provider.getNextSetoranSuggestion(santri.id);

  // No history or no surah list yet → open form normally
  if (continuation == null) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SetoranFormScreen(santri: santri)),
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Santri name
            Row(
              children: [
                AppAvatar(name: santri.name, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        santri.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Lanjutan setoran terdeteksi',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Quick continue tile
            _OptionTile(
              icon: Icons.play_circle_filled_rounded,
              color: AppTheme.primaryGreen,
              title: 'Lanjut Setoran',
              subtitle: continuation.description,
              onTap: () {
                Navigator.pop(ctx);
                provider.startSetoranSession(
                  santri: santri,
                  type: continuation.type,
                  surah: continuation.surah,
                  ayahStart: continuation.ayahStart,
                  ayahEnd: continuation.ayahEnd,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuranReaderScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            // Manual selection tile
            _OptionTile(
              icon: Icons.tune_rounded,
              color: const Color(0xFF1565C0),
              title: 'Pilih Manual',
              subtitle: 'Atur surah, ayat, dan jenis setoran sendiri',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SetoranFormScreen(
                      santri: santri,
                      initialSurah: continuation.surah,
                      initialAyahStart: continuation.ayahStart,
                      initialAyahEnd: continuation.ayahEnd,
                      initialType: continuation.type,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
