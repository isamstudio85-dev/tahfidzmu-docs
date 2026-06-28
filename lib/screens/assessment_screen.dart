import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/setoran.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../utils/scoring_utils.dart';
import '../widgets/quran_widgets.dart';
import 'main_shell.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _fluency = 3;
  SetoranRecord? _savedRecord;
  bool _saved = false;

  double _previewScore(AppProvider p) {
    return ScoringUtils.calculateScore(
      errorMarks: p.sessionErrors.values.toList(),
      fluencyRating: _fluency,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final score = _saved
            ? _savedRecord!.finalScore
            : _previewScore(provider);
        final stars = ScoringUtils.scoreToStars(score);
        final grade = ScoringUtils.scoreToGrade(score);
        final tajwid = _saved
            ? _savedRecord!.tajwidErrorCount
            : provider.sessionTajwidCount;
        final makhroj = _saved
            ? _savedRecord!.makhrojErrorCount
            : provider.sessionMakhrojCount;

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Penilaian Setoran'),
              automaticallyImplyLeading: false,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Santri & surah info
                  _buildInfoCard(provider),
                  const SizedBox(height: 20),
                  // Error summary
                  _buildErrorSummary(tajwid, makhroj),
                  const SizedBox(height: 20),
                  // Fluency rating
                  if (!_saved) _buildFluencySection(),
                  if (!_saved) const SizedBox(height: 20),
                  // Score card
                  _buildScoreCard(score, stars, grade),
                  const SizedBox(height: 20),
                  // Error list (details)
                  if (!_saved && provider.sessionErrors.isNotEmpty)
                    _buildErrorList(provider),
                  if (_saved && _savedRecord!.errorMarks.isNotEmpty)
                    _buildSavedErrorList(_savedRecord!),
                  const SizedBox(height: 24),
                  // Action buttons
                  if (!_saved)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Simpan Penilaian'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _saveSetoran(provider),
                      ),
                    )
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Kembali ke Beranda'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (r) => false,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(AppProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                AppAvatar(
                  name: provider.activeSetoranSantri?.name ?? '?',
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.activeSetoranSantri?.name ?? '',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        provider.activeSetoranType.label,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.activeSetoranSurahEnglishName.isNotEmpty
                        ? '${provider.activeSetoranSurahEnglishName} — Ayat '
                              '${provider.activeSetoranAyahStart}–${provider.activeSetoranAyahEnd}'
                        : '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  provider.activeSetoranSurahName,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    color: AppTheme.primaryGreen,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSummary(int tajwid, int makhroj) {
    return Row(
      children: [
        _errorBox('Tajwid', tajwid, AppTheme.tajwidColor, Icons.music_note),
        const SizedBox(width: 12),
        _errorBox(
          'Makhroj',
          makhroj,
          AppTheme.makhrojColor,
          Icons.record_voice_over,
        ),
        const SizedBox(width: 12),
        _errorBox(
          'Total',
          tajwid + makhroj,
          Colors.grey.shade700,
          Icons.error_outline_rounded,
        ),
      ],
    );
  }

  Widget _errorBox(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFluencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Penilaian Kelancaran',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Seberapa lancar bacaan santri secara keseluruhan?',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            StarRatingWidget(
              rating: _fluency,
              size: 44,
              onChanged: (v) => setState(() => _fluency = v),
            ),
            const SizedBox(height: 8),
            Text(
              _fluencyLabel(_fluency),
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            _fluencyHint(),
          ],
        ),
      ),
    );
  }

  String _fluencyLabel(int f) {
    switch (f) {
      case 1:
        return 'Sangat Perlu Bimbingan';
      case 2:
        return 'Perlu Perbaikan';
      case 3:
        return 'Cukup Lancar';
      case 4:
        return 'Lancar';
      case 5:
        return 'Sangat Lancar';
      default:
        return '';
    }
  }

  Widget _fluencyHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Tidak Lancar',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        Text(
          'Sangat Lancar',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildScoreCard(double score, int stars, String grade) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Skor Akhir',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '/ 100',
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 12),
          StarRatingWidget(rating: stars, size: 36, color: AppTheme.gold),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              grade,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Akurasi 60% + Kelancaran 40%',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList(AppProvider provider) {
    final errors = provider.sessionErrors.values.toList();
    return _ErrorDetailSection(errors: errors);
  }

  Widget _buildSavedErrorList(SetoranRecord record) {
    return _ErrorDetailSection(errors: record.errorMarks);
  }

  void _saveSetoran(AppProvider provider) {
    final record = provider.completeSetoran(_fluency);
    setState(() {
      _savedRecord = record;
      _saved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Setoran berhasil disimpan!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}

class _ErrorDetailSection extends StatelessWidget {
  const _ErrorDetailSection({required this.errors});
  final List errors; // List<ErrorMark>

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Kesalahan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...errors.map((e) {
          final type = e.errorType as dynamic;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: type.bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (type.color as Color).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  type.icon as IconData,
                  color: type.color as Color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.word as String,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      color: type.color as Color,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Text(
                  'Ayat ${e.ayahNumber}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (type.color as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type.label as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: type.color as Color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
