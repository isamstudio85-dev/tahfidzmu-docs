import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/auth/screens/login_screen.dart';
import 'package:tahfidz_app/features/dashboard/screens/main_shell.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_reader_screen.dart';

class PublicPortalScreen extends StatefulWidget {
  const PublicPortalScreen({super.key});

  @override
  State<PublicPortalScreen> createState() => _PublicPortalScreenState();
}

class _PublicPortalScreenState extends State<PublicPortalScreen> {
  // Mock donation flag for AD hiding
  final bool _isVIPDonor = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            if (!_isVIPDonor) _buildAdBanner(),
            Expanded(
              child: _buildGrid(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.darkGreen, // Always dark green in light mode for consistency
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat Datang di',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'PesantrenMu',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSearchBox(),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'Cari layanan atau kitab...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text(
          'Ruang Iklan\n(Hilang jika berdonasi)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    // 4 columns grid for super-app look
    return GridView.count(
      crossAxisCount: 4,
      padding: const EdgeInsets.all(20),
      mainAxisSpacing: 24,
      crossAxisSpacing: 16,
      children: [
        _buildAppIcon(
          icon: Icons.menu_book_rounded,
          label: 'TahfidzMu',
          color: AppTheme.primaryGreen,
          isDark: isDark,
          onTap: () => _handleTahfidzLogin(context),
        ),
        _buildAppIcon(
          icon: Icons.book_outlined,
          label: 'Al-Quran',
          color: AppTheme.gold,
          isDark: isDark,
          onTap: () => _openPublicQuran(context),
        ),
        _buildAppIcon(
          icon: Icons.auto_stories_rounded,
          label: 'Hadits',
          color: Colors.blueAccent,
          isDark: isDark,
          onTap: () {
            // Placeholder
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kitab Hadits (Segera Hadir)')));
          },
        ),
        _buildAppIcon(
          icon: Icons.public_rounded,
          label: 'Web',
          color: Colors.purpleAccent,
          isDark: isDark,
          onTap: () => _openPesantrenWeb(),
        ),
        _buildAppIcon(
          icon: Icons.work_history_rounded,
          label: 'Manajemen',
          color: Colors.orangeAccent,
          isDark: isDark,
          onTap: () {
            // Placeholder
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manajemen Kerja (Login Spesifik)')));
          },
        ),
        _buildAppIcon(
          icon: Icons.mosque_outlined,
          label: 'Doa Harian',
          color: Colors.teal,
          isDark: isDark,
          onTap: () {
            // Placeholder
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kumpulan Doa (Segera Hadir)')));
          },
        ),
      ],
    );
  }

  Widget _buildAppIcon({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceVariant : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _handleTahfidzLogin(BuildContext context) {
    final provider = context.read<AppProvider>();
    if (provider.isLoggedIn) {
      if (provider.isSuperAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akses super admin dinonaktifkan di Android.')));
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _openPublicQuran(BuildContext context) {
    // Set a default surah to open, or you could create a Surah List Screen first.
    // For now, prototype routes directly to Al-Fatihah (Surah 1) in read-only mode.
    final provider = context.read<AppProvider>();
    provider.activeSetoranSurahNumber = 1;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuranReaderScreen(isReadOnly: true),
      ),
    );
  }

  Future<void> _openPesantrenWeb() async {
    final Uri url = Uri.parse('https://pesantrenmu.com');
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka website')));
      }
    }
  }
}
