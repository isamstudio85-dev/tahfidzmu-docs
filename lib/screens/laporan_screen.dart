import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/error_mark.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'setoran_screen.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const SetoranScreen();
  }
}

class LaporanScreenBody extends StatelessWidget {
  const LaporanScreenBody({super.key, required this.setorans, required this.provider});
  final List<SetoranRecord> setorans;
  final AppProvider provider;

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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1F8E9), Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // 1. Hero Performance Header
          _buildHeroHeader(avg, setorans.length),
          const SizedBox(height: 24),

          // 2. Adaptive Progress Cards (Glass-ish style)
          _buildSectionHeader('STATISTIK JENIS HAFALAN'),
          const SizedBox(height: 12),
          _buildDistributionCards(ziyadah, murojaah),
          const SizedBox(height: 24),

          // 3. Error Heatmap (Bubble style - Diversity in Shapes)
          _buildSectionHeader('ANALISIS KESALAHAN'),
          const SizedBox(height: 12),
          _buildErrorBubbleCard(tajwidCount, makhrojCount),
          const SizedBox(height: 24),

          // 4. Modern Weekly Chart
          _buildSectionHeader('AKTIVITAS MINGGUAN'),
          const SizedBox(height: 12),
          _WeeklyActivityCard(setorans: setorans),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(double avg, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Skor Rata-rata',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            avg.toStringAsFixed(0),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 54, fontWeight: FontWeight.bold, height: 1.1),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$total Setoran Tercatat',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCards(int ziyadah, int murojaah) {
    return Row(
      children: [
        _distCard('Ziyadah', ziyadah, Icons.add_chart_rounded, AppTheme.primaryGreen),
        const SizedBox(width: 12),
        _distCard("Muroja'ah", murojaah, Icons.history_rounded, Colors.purple),
      ],
    );
  }

  Widget _distCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBubbleCard(int tajwid, int makhroj) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _errorBubble('Tajwid', tajwid, AppTheme.tajwidColor),
          _errorBubble('Makhroj', makhroj, AppTheme.makhrojColor),
        ],
      ),
    );
  }

  Widget _errorBubble(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.2)],
            ),
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
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
          color: Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.setorans});
  final List<SetoranRecord> setorans;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final maxSetoran = days.map((d) => setorans.where((s) => s.date.day == d.day && s.date.month == d.month).length).fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
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
                width: 20,
                height: (80 * ratio).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primaryGreen : AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'][d.weekday - 1],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppTheme.primaryGreen : Colors.grey,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
