import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/models/error_mark.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/core/utils/scoring_utils.dart';
import 'package:tahfidz_app/features/tahfidz_quran/widgets/quran_widgets.dart';
import 'package:tahfidz_app/features/dashboard/screens/main_shell.dart';

import 'package:tahfidz_app/models/tasmi_record.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _fluency = 3;
  String _tasmiStatus = 'lulus'; // 'lulus', 'tidak_lulus', 'tinjau_ulang'
  dynamic _savedRecord;
  bool _saved = false;
  bool _showErrorDetails = false;

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
        final isTasmi = provider.isTasmiSession;
        final score = _saved ? _savedRecord.finalScore : _previewScore(provider);
        final stars = ScoringUtils.scoreToStars(score);
        final grade = ScoringUtils.scoreToGrade(score);
        final tajwid = _saved ? _savedRecord.errorMarks.where((e) => e.errorType == ErrorType.tajwid).length : provider.sessionTajwidCount;
        final makhroj = _saved ? _savedRecord.errorMarks.where((e) => e.errorType == ErrorType.makhroj).length : provider.sessionMakhrojCount;
        final errors = _saved ? _savedRecord.errorMarks : provider.sessionErrors.values.toList();

        return PopScope(
          canPop: false,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Penilaian Akhir'),
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  // 1. Compact Score Card (The Hero)
                  _buildUnifiedScoreCard(provider, score, stars, grade),
                  const SizedBox(height: 20),

                  // 2. Error Stats Row
                  _buildCompactErrorStats(tajwid, makhroj),
                  const SizedBox(height: 20),

                  // 3. Fluency Section (Only before save)
                  if (!_saved) ...[
                    _buildCompactFluencySection(),
                    const SizedBox(height: 20),
                    if (provider.isTasmiSession) ...[
                      _buildTasmiDecisionSection(),
                      const SizedBox(height: 20),
                    ],
                  ],

                  // 4. Collapsible Error Details (If any)
                  if (errors.isNotEmpty) ...[
                    _buildCollapsibleErrorDetails(errors),
                    const SizedBox(height: 24),
                  ],

                  // 5. Actions
                  if (!_saved)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('SIMPAN PENILAIAN'),
                        onPressed: () => _saveSetoran(provider),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('KEMBALI KE BERANDA'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                        ),
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (r) => false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnifiedScoreCard(AppProvider provider, double score, int stars, String grade) {
    final santri = provider.activeSetoranSantri;
    final isTasmi = provider.isTasmiSession;
    
    String subTitle = isTasmi 
      ? 'Ujian Tasmi Juz ${provider.activeTasmiJuz.join(", ")}'
      : '${provider.activeSetoranSurahEnglishName} • Ayat ${provider.activeSetoranAyahStart}-${provider.activeSetoranAyahEnd}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTasmi 
            ? [const Color(0xFF4527A0), const Color(0xFF7B1FA2)] // Purple gradient for Tasmi
            : [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: (isTasmi ? Colors.purple : AppTheme.primaryGreen).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppAvatar(name: santri?.name ?? '?', radius: 24, backgroundColor: Colors.white24, foregroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(santri?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subTitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),
          Text(isTasmi ? 'SKOR UJIAN TASMI' : 'SKOR AKHIR', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          Text(score.toStringAsFixed(0), style: GoogleFonts.poppins(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, height: 1.1)),
          const SizedBox(height: 8),
          StarRatingWidget(rating: stars, size: 28, color: AppTheme.gold),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(grade.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactErrorStats(int tajwid, int makhroj) {
    return Row(
      children: [
        _miniErrorBox('Tajwid', tajwid, AppTheme.tajwidColor),
        const SizedBox(width: 12),
        _miniErrorBox('Makhroj', makhroj, AppTheme.makhrojColor),
        const SizedBox(width: 12),
        _miniErrorBox('Total', tajwid + makhroj, Colors.blueGrey),
      ],
    );
  }

  Widget _miniErrorBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFluencySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Kelancaran Bacaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          StarRatingWidget(rating: _fluency, size: 36, onChanged: (v) => setState(() => _fluency = v)),
          const SizedBox(height: 8),
          Text(_fluencyLabel(_fluency), style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTasmiDecisionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keputusan Ujian Tasmi\'', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          _statusOption('LULUS WISUDA', 'lulus', Colors.green, Icons.check_circle_rounded),
          const SizedBox(height: 10),
          _statusOption('TINJAU ULANG / BERTAHAP', 'tinjau_ulang', Colors.orange, Icons.history_edu_rounded),
          const SizedBox(height: 10),
          _statusOption('TIDAK LULUS', 'tidak_lulus', Colors.red, Icons.cancel_rounded),
        ],
      ),
    );
  }

  Widget _statusOption(String label, String value, Color color, IconData icon) {
    final isSelected = _tasmiStatus == value;
    return InkWell(
      onTap: () => setState(() => _tasmiStatus = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? color : Colors.black54))),
            if (isSelected) Icon(Icons.check_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleErrorDetails(List errors) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _showErrorDetails = !_showErrorDetails),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Detail Kesalahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const Spacer(),
                Icon(_showErrorDetails ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_showErrorDetails)
          ...errors.map((e) {
            final type = e.errorType;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: type.bgColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: Text(e.word, style: GoogleFonts.amiri(fontSize: 20, color: type.color), textDirection: TextDirection.rtl)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Ayat ${e.ayahNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(type.label, style: TextStyle(fontSize: 10, color: type.color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _fluencyLabel(int f) {
    switch (f) {
      case 1: return 'Sangat Kurang';
      case 2: return 'Perlu Perbaikan';
      case 3: return 'Cukup Lancar';
      case 4: return 'Lancar';
      case 5: return 'Sangat Lancar';
      default: return '';
    }
  }

  void _saveSetoran(AppProvider provider) {
    if (provider.isTasmiSession) {
      final record = provider.completeTasmi(
        juzNumbers: provider.activeTasmiJuz,
        fluencyRating: _fluency,
        year: provider.activeTasmiYear,
        status: _tasmiStatus,
      );
      if (record == null) return;
      setState(() {
        _savedRecord = record;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.school_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Hasil: ${_tasmiStatus.toUpperCase()} Berhasil Disimpan!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          backgroundColor: _tasmiStatus == 'lulus' ? Colors.green : (_tasmiStatus == 'tinjau_ulang' ? Colors.orange : Colors.red),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final record = provider.completeSetoran(_fluency);
      if (record == null) return;
      setState(() {
        _savedRecord = record;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Hafalan Berhasil Disimpan!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
