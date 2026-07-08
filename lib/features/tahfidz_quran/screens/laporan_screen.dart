import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tahfidz_app/models/error_mark.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_memorization_screen.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const QuranMemorizationScreen();
  }
}

class LaporanScreenBody extends StatelessWidget {
  const LaporanScreenBody({super.key, required this.setorans, required this.provider});
  final List<SetoranRecord> setorans;
  final AppProvider provider;

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700, 
                    fontSize: 9, 
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child, 
    required Color backgroundColor, 
    required Color borderColor,
    Color? shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? Colors.black).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ziyadah = setorans.where((s) => s.type == SetoranType.ziyadah).length;
    final murojaah = setorans.length - ziyadah;
    final totalScores = setorans.map((s) => s.finalScore).toList();
    final avg = totalScores.isEmpty ? 0.0 : totalScores.reduce((a, b) => a + b) / setorans.length;
    
    final errors = setorans.expand((s) => s.errorMarks).toList();
    final tajwidCount = errors.where((e) => e.errorType == ErrorType.tajwid).length;
    final makhrojCount = errors.length - tajwidCount;

    return Container(
      color: const Color(0xFFF8F9FA), // Modern minimalist light grey background
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // 1. Hero Performance Header
          _buildHeroHeader(avg, setorans.length),
          const SizedBox(height: 20),

          // 2. Separate Metric Cards in 2x2 layout directly without headers (Color Accents!)
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  label: 'Ziyadah', 
                  value: '$ziyadah', 
                  icon: Icons.add_chart_rounded, 
                  iconColor: AppTheme.primaryGreen,
                  backgroundColor: const Color(0xFFE8F5E9), // Light green pastel
                  borderColor: const Color(0xFFC8E6C9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  label: "Muroja'ah", 
                  value: '$murojaah', 
                  icon: Icons.history_rounded, 
                  iconColor: Colors.purple.shade700,
                  backgroundColor: const Color(0xFFF3E5F5), // Light purple pastel
                  borderColor: const Color(0xFFE1BEE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  label: 'Ayat Lulus', 
                  value: '$passedCount', 
                  icon: Icons.check_circle_outline_rounded, 
                  iconColor: Colors.teal.shade700,
                  backgroundColor: const Color(0xFFE0F2F1), // Light teal pastel
                  borderColor: const Color(0xFFB2DFDB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  label: 'Ayat Gagal', 
                  value: '$failedCount', 
                  icon: Icons.error_outline_rounded, 
                  iconColor: Colors.red.shade700,
                  backgroundColor: const Color(0xFFFFEBEE), // Light red/rose pastel
                  borderColor: const Color(0xFFFFCDD2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 3. Target Achievement - Sleek Blue/Indigo Card
          _buildSectionHeader('PENCAPAIAN TARGET'),
          const SizedBox(height: 10),
          _buildTargetAchievementCard(),
          const SizedBox(height: 28),

          // 4. Error Analysis - Modern Orange/Amber Card
          _buildSectionHeader('ANALISIS KESALAHAN'),
          const SizedBox(height: 10),
          _buildMinimalistErrorCard(tajwidCount, makhrojCount),
          const SizedBox(height: 28),

          // 5. Weekly Activity Chart - Clean Green/Mint Card
          _buildSectionHeader('AKTIVITAS MINGGUAN'),
          const SizedBox(height: 10),
          _WeeklyActivityCard(setorans: setorans, sectionCard: _sectionCard),
        ],
      ),
    );
  }

  int get passedCount => setorans.fold(0, (sum, r) => sum + r.passedAyahs.length);
  int get failedCount => setorans.fold(0, (sum, r) => sum + r.failedAyahs.length);

  Widget _buildHeroHeader(double avg, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rata-rata Skor',
                style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                avg.toStringAsFixed(0),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold, height: 1.1),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$total',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Setoran Tercatat',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAchievementCard() {
    final isOrangTua = provider.isOrangTua && provider.linkedSantriId != null;
    
    double progress = 0.0;
    int currentAyahs = 0;
    const targetAyahs = 604; // 1 Juz
    String descText = '';
    String titleText = 'Target Tahunan';

    if (isOrangTua) {
      final santri = provider.getSantriById(provider.linkedSantriId!);
      if (santri == null) return const SizedBox.shrink();
      currentAyahs = santri.totalZiyadahAyahs;
      progress = (currentAyahs / targetAyahs).clamp(0.0, 1.0);
      descText = '$currentAyahs dari $targetAyahs Ayat berhasil dihafal tahun ini.';
      titleText = 'Target Tahunan Santri (1 Juz)';
    } else {
      final sourceList = provider.isMusyrif && provider.linkedMusyrif != null 
          ? provider.getSantriByMusyrif(provider.linkedMusyrif!.id) 
          : provider.santriList;
      
      if (sourceList.isEmpty) {
        return _sectionCard(
          backgroundColor: const Color(0xFFEBF3FC), // Light blue-grey tint
          borderColor: const Color(0xFFD2E3FC),
          child: const Text('Belum ada data santri untuk kalkulasi target.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        );
      }
      
      int totalAyahs = sourceList.fold(0, (sum, s) => sum + s.totalZiyadahAyahs);
      currentAyahs = totalAyahs ~/ sourceList.length;
      progress = (currentAyahs / targetAyahs).clamp(0.0, 1.0);
      descText = 'Rata-rata santri halaqah menghafal $currentAyahs dari $targetAyahs Ayat target tahun ini.';
      titleText = 'Rata-rata Target Halaqah (1 Juz)';
    }

    return _sectionCard(
      backgroundColor: const Color(0xFFEBF3FC), // Modern clean blue tint
      borderColor: const Color(0xFFD2E3FC),
      shadowColor: Colors.blue.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A73E8))),
              Text('${(progress * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A73E8))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              color: const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 12),
          Text(descText, style: const TextStyle(fontSize: 11, color: Color(0xFF185ABC))),
        ],
      ),
    );
  }

  Widget _buildMinimalistErrorCard(int tajwid, int makhroj) {
    final total = tajwid + makhroj;
    final double tajwidRatio = total == 0 ? 0.5 : tajwid / total;
    
    return _sectionCard(
      backgroundColor: const Color(0xFFFFF3E0), // Modern clean orange/amber tint
      borderColor: const Color(0xFFFFE0B2),
      shadowColor: Colors.orange.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _errorLabel('Tajwid', tajwid, AppTheme.tajwidColor),
              _errorLabel('Makhroj', makhroj, AppTheme.makhrojColor),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (tajwidRatio * 100).round(),
                    child: Container(color: AppTheme.tajwidColor),
                  ),
                  Expanded(
                    flex: ((1 - tajwidRatio) * 100).round(),
                    child: Container(color: AppTheme.makhrojColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              total == 0 ? 'Tidak ada kesalahan tercatat' : 'Total $total Kesalahan Terdeteksi',
              style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorLabel(String name, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$name: ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        Text(
          '$count',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.setorans, required this.sectionCard});
  final List<SetoranRecord> setorans;
  final Widget Function({required Widget child, required Color backgroundColor, required Color borderColor, Color? shadowColor}) sectionCard;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxSetoran = days.map((d) => setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length).fold(0, (a, b) => a > b ? a : b);

    return sectionCard(
      backgroundColor: const Color(0xFFE8F5E9), // Modern clean green/mint tint
      borderColor: const Color(0xFFC8E6C9),
      shadowColor: AppTheme.primaryGreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final count = setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length;
          final ratio = maxSetoran == 0 ? 0.0 : count / maxSetoran;
          final isToday = d.day == now.day && d.month == now.month;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 18,
                height: (80 * ratio).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primaryGreen : AppTheme.primaryGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'][d.weekday - 1],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppTheme.primaryGreen : Colors.grey.shade600,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
