import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_memorization_screen.dart';
import 'package:tahfidz_app/models/user_role.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/dashboard/screens/home_screen.dart';
import 'package:tahfidz_app/features/management/screens/user_management_screen.dart';
import 'package:tahfidz_app/features/management/screens/manajemen_screen.dart';
import 'package:tahfidz_app/features/profile/screens/profil_screen.dart';
import 'package:tahfidz_app/features/management/screens/presensi_history_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  UserRole? _lastRole;

  List<Widget> _getScreens(AppProvider provider) {
    final role = provider.currentRole;
    final isKoordinator = provider.linkedMusyrif?.isKoordinator ?? false;

    switch (role) {
      case UserRole.admin:
        return [
          const HomeScreen(),               // 0
          const UserManagementScreen(),     // 1
          const QuranMemorizationScreen(),  // 2 (Center)
          const ManajemenScreen(),          // 3
          const ProfilScreen(),             // 4
        ];
      case UserRole.musyrif:
        if (isKoordinator) {
          return [
            const HomeScreen(),               // 0
            const UserManagementScreen(),     // 1
            const QuranMemorizationScreen(),  // 2 (Center)
            const ManajemenScreen(),          // 3
            const ProfilScreen(),             // 4
          ];
        }
        return [
          const HomeScreen(),               // 0
          const UserManagementScreen(),     // 1
          const QuranMemorizationScreen(),  // 2 (Center)
          const PresensiHistoryScreen(),    // 3
          const ProfilScreen(),             // 4
        ];
      case UserRole.pengawas:
        return [
          const HomeScreen(),               // 0
          const UserManagementScreen(),     // 1
          const QuranMemorizationScreen(),  // 2 (Center)
          const PresensiHistoryScreen(),    // 3
          const ProfilScreen(),             // 4
        ];
      case UserRole.orangTua:
        return [
          const HomeScreen(),               // 0
          const QuranMemorizationScreen(),  // 1 (Center)
          const ProfilScreen(),             // 2
        ];
      default:
        return [const HomeScreen()];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final role = provider.currentRole;
    final isKoordinator = provider.linkedMusyrif?.isKoordinator ?? false;

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (_lastRole != role) {
      _lastRole = role;
      _index = 0;
    }

    final screens = _getScreens(provider);
    final bool isFiveMenu = role != UserRole.orangTua;
    final int safeIndex = _index.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, -4), // Distinct top shadow
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: isFiveMenu 
                ? Row(
                    children: [
                      _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
                      _navItem(1, Icons.group_outlined, Icons.group_rounded, 'Pengguna'),
                      _centerLogoItem(2),
                      _navItem(3, Icons.assignment_outlined, Icons.assignment_rounded, (role == UserRole.admin || isKoordinator) ? 'Kelola' : 'Riwayat'),
                      _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                    ],
                  )
                : Row(
                    children: [
                      _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
                      _centerLogoItem(1),
                      _navItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _centerLogoItem(int idx) {
    final isSelected = _index == idx;
    return Expanded(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _index = idx),
            borderRadius: BorderRadius.circular(28), // Matches the circle
            splashColor: Colors.black.withValues(alpha: 0.05), // Neutral grey ripple
            child: Container(
              width: 58, // Slightly smaller bulatan as requested
              height: 58,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  // Changed from Green to Thin Grey
                  color: isSelected ? Colors.grey.shade300 : Colors.grey.shade100,
                  width: 1.0,
                ),
              ),
              child: Image.asset(
                'assets/images/TahfidzMU-logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.auto_stories_rounded,
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final isSelected = _index == idx;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _index = idx),
          borderRadius: BorderRadius.circular(16), // SQUIRCLE RIPPLE
          splashColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
