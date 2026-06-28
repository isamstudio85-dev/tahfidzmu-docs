import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/santri.dart';
import '../models/setoran.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/scoring_utils.dart';
import '../widgets/quran_widgets.dart';
import '../widgets/continuation_dialog.dart';
import '../widgets/app_avatar.dart';
import 'santri_form_screen.dart';
import 'setoran_detail_screen.dart';

class SantriDetailScreen extends StatelessWidget {
  const SantriDetailScreen({super.key, required this.santriId});
  final String santriId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final santri = provider.getSantriById(santriId);
        if (santri == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Santri')),
            body: const Center(child: Text('Santri tidak ditemukan')),
          );
        }

        final avg = santri.averageScore;
        final stars = santri.overallStarCount;
        final grade = ScoringUtils.scoreToGrade(avg);

        final isAdmin = provider.isAdmin;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Santri'),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.lock_reset_rounded),
                  tooltip: 'Reset Password',
                  onPressed: () =>
                      _showResetPasswordDialog(context, provider, santri),
                ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Profil',
                  onPressed: () =>
                      _showEditProfileDialog(context, provider, santri),
                ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Hapus Santri',
                  onPressed: () => _confirmDelete(context, provider, santri),
                ),
            ],
          ),
          floatingActionButton: provider.isMusyrif
              ? FloatingActionButton.extended(
                  heroTag: 'fab_detail_setoran',
                  onPressed: () => showSetoranOptions(context, santri),
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Mulai Setoran'),
                )
              : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card: avatar on top, name below — prevents overflow
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _showPhotoOptions(context, provider, santri),
                        child: AppAvatar(
                          name: santri.name,
                          radius: 48,
                          imagePath: (santri.photoPath?.isNotEmpty ?? false)
                              ? santri.photoPath
                              : null,
                          backgroundColor: AppTheme.primaryGreen.withValues(
                            alpha: 0.08,
                          ),
                          foregroundColor: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        santri.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (santri.kelas != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          santri.kelas!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      StarRatingWidget(rating: stars, size: 24),
                      const SizedBox(height: 6),
                      GradeBadgeWidget(
                        gradeName: grade,
                        stars: stars,
                        large: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Tahfidz info card ──────────────────────────────────
                if (santri.nis != null ||
                    santri.jenisKelamin != null ||
                    santri.namaAyah != null ||
                    santri.namaIbu != null ||
                    santri.nomorHpWali != null ||
                    santri.targetHafalan != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Santri',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (santri.nis != null)
                          _InfoRow(label: 'NIS', value: santri.nis!),
                        if (santri.jenisKelamin != null)
                          _InfoRow(
                            label: 'Jenis Kelamin',
                            value: santri.jenisKelamin == 'P'
                                ? 'Perempuan'
                                : 'Laki-laki',
                          ),
                        if (santri.halaqahId != null)
                          _InfoRow(
                            label: 'Halaqah',
                            value:
                                Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                ).getHalaqahById(santri.halaqahId)?.nama ??
                                '-',
                            valueColor: AppTheme.primaryGreen,
                          ),
                        if (santri.kelas != null)
                          _InfoRow(label: 'Kelas', value: santri.kelas!),
                        _InfoRow(
                          label: 'Jumlah Juz Hafalan',
                          value: santri.estimatedJuz >= 1
                              ? '≈ ${santri.estimatedJuz.toStringAsFixed(1)} Juz'
                              : '< 1 Juz',
                          valueColor: AppTheme.primaryGreen,
                        ),
                        if (santri.targetHafalan != null)
                          _InfoRow(
                            label: 'Target Hafalan',
                            value: santri.targetHafalan!,
                            valueColor: AppTheme.primaryGreen,
                          ),
                        if (santri.namaAyah != null)
                          _InfoRow(label: 'Nama Ayah', value: santri.namaAyah!),
                        if (santri.namaIbu != null)
                          _InfoRow(label: 'Nama Ibu', value: santri.namaIbu!),
                        if (santri.nomorHpWali != null)
                          _InfoRow(
                            label: 'No. HP Wali',
                            value: santri.nomorHpWali!,
                          ),
                        _InfoRow(
                          label: 'Status',
                          value: santri.isAktif ? 'Aktif' : 'Non-aktif',
                          valueColor: santri.isAktif
                              ? AppTheme.primaryGreen
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Setoran',
                        value: '${santri.totalSetoranCount}',
                        icon: Icons.list_alt_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Rata-rata Skor',
                        value: avg.toStringAsFixed(1),
                        icon: Icons.bar_chart_rounded,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Juz Hafalan',
                        value: santri.estimatedJuz >= 1
                            ? '≈ ${santri.estimatedJuz.toStringAsFixed(1)}'
                            : '< 1',
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF7B1FA2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Riwayat Setoran',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (santri.setoranHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat setoran',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  ...santri.setoranHistory.reversed.map(
                    (r) => GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SetoranDetailScreen(record: r, santri: santri),
                        ),
                      ),
                      child: _SetoranHistoryCard(record: r),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showPhotoOptions(
    BuildContext context,
    AppProvider provider,
    Santri santri,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto ${santri.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (santri.photoPath?.isNotEmpty ?? false)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.updateSantriPhoto(santri.id, '');
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 600,
    );
    if (file != null && context.mounted) {
      provider.updateSantriPhoto(santri.id, file.path);
    }
  }

  void _showEditProfileDialog(
    BuildContext context,
    AppProvider provider,
    Santri santri,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SantriFormScreen(existing: santri)),
    );
  }

  static Future<void> _showResetPasswordDialog(
    BuildContext context,
    AppProvider provider,
    Santri santri,
  ) async {
    if (santri.nis == null || santri.nis!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Reset password hanya tersedia untuk santri yang sudah memiliki akun NIS.',
            ),
          ),
        );
      }
      return;
    }

    final passwordCtrl = TextEditingController(text: santri.nis);
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Reset Password Santri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final newPassword = passwordCtrl.text.trim();
                if (newPassword.length < 4) {
                  setSt(() => error = 'Password minimal 4 karakter.');
                  return;
                }
                final ok = await provider.resetPasswordForLinkedId(
                  santri.id,
                  newPassword,
                );
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password santri berhasil direset.'),
                    ),
                  );
                } else {
                  setSt(() => error = 'Gagal mereset password.');
                }
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppProvider provider,
    Santri santri,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Santri?'),
        content: Text(
          'Data "${santri.name}" beserta seluruh riwayat setoran akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () {
              provider.removeSantri(santri.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetoranHistoryCard extends StatelessWidget {
  const _SetoranHistoryCard({required this.record});
  final SetoranRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.surahEnglishName} (${record.surahName})',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.juzLabel} · ${record.ayahRange} · ${record.type.label}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 70),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          record.finalScore.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        StarRatingWidget(rating: record.starCount, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _chip(
                    Icons.music_note,
                    'Tajwid: ${record.tajwidErrorCount}',
                    AppTheme.tajwidColor,
                  ),
                  _chip(
                    Icons.record_voice_over,
                    'Makhroj: ${record.makhrojErrorCount}',
                    AppTheme.makhrojColor,
                  ),
                  _chip(
                    Icons.accessibility_new,
                    'Kelancaran: ${record.fluencyRating}/5',
                    AppTheme.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(record.date),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 8,
        runSpacing: 4,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const Text(' : ', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
