import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_reader_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_form_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';

/// Shows a bottom sheet with three choices:
///  1. **Lanjut** — directly start from the detected next position
///  2. **Pilih Manual** — open the form pre-filled
///  3. **Lihat Detail** — view the specific record details (optional)
///
/// If the santri has no history (or surah list not loaded), opens the form
/// directly without a dialog.
Future<void> showSetoranOptions(BuildContext context, Santri santri, {SetoranRecord? record}) async {
  final provider = context.read<AppProvider>();
  final continuation = provider.getNextSetoranSuggestion(santri.id);

  // If we have a specific record, we might want to show details.
  // If no history, just go to form.
  if (continuation == null && record == null) {
    if (!context.mounted) return;
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(expectedSantri: santri),
      ),
    );
    if (verified == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SetoranFormScreen(santri: santri)),
      );
    }
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
                AppAvatar(name: santri.name, radius: 22, imagePath: santri.photoPath),
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
                        record != null ? 'Pilih aksi untuk setoran ini' : 'Lanjutan setoran terdeteksi',
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
            // 1. Quick continue tile (if possible)
             if (continuation != null)
              _OptionTile(
                icon: Icons.play_circle_filled_rounded,
                color: AppTheme.primaryGreen,
                title: 'Lanjutkan Hafalan',
                subtitle: 'Mulai: ${continuation.description}',
                onTap: () async {
                  Navigator.pop(ctx);
                  final verified = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrScannerScreen(expectedSantri: santri),
                    ),
                  );
                  if (verified == true) {
                    provider.startSetoranSession(
                      santri: santri,
                      type: continuation.type,
                      surah: continuation.surah,
                      ayahStart: continuation.ayahStart,
                      ayahEnd: continuation.ayahEnd,
                    );
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuranReaderScreen()),
                      );
                    }
                  }
                },
              ),
            if (continuation != null) const SizedBox(height: 10),
            
            // 2. View Detail (if record provided)
            if (record != null)
              _OptionTile(
                icon: Icons.assignment_outlined,
                color: Colors.purple,
                title: 'Lihat Detail Setoran',
                subtitle: 'Lihat skor, tajwid, dan makhroj record ini',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetoranDetailScreen(santri: santri, record: record),
                    ),
                  );
                },
              ),
            if (record != null) const SizedBox(height: 10),

            // 3. Manual selection tile
            _OptionTile(
              icon: Icons.tune_rounded,
              color: const Color(0xFF1565C0),
              title: 'Tambah Hafalan Baru',
              onTap: () async {
                Navigator.pop(ctx);
                final verified = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrScannerScreen(expectedSantri: santri),
                  ),
                );
                if (verified == true && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetoranFormScreen(
                        santri: santri,
                        initialSurah: continuation?.surah,
                        initialAyahStart: continuation?.ayahStart,
                        initialType: continuation?.type ?? SetoranType.ziyadah,
                      ),
                    ),
                  );
                }
              },
              subtitle: 'Atur surah, ayat, dan jenis secara manual',
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
