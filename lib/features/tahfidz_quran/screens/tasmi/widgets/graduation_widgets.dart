import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/models/graduation_event.dart';

class GraduationHeader extends StatelessWidget {
  const GraduationHeader({super.key, required this.event});
  final GraduationEvent event;

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      centerTitle: true,
      titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      title: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          event.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 10)],
          ),
        ),
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: 40,
            child: Opacity(
                opacity: 0.1,
                child: const Icon(Icons.school_rounded, size: 180, color: Colors.white)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.gold, size: 40),
                ),
                const SizedBox(height: 12),
                Text('WISUDA TAHFIDZ',
                    style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 10)),
                Text(event.year,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.2)),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.withValues(alpha: 0.3), size: 18),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          ])),
        ],
      ),
    );
  }
}
