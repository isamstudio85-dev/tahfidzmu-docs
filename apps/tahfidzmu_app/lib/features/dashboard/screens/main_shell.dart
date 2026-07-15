import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/features/tahfidz_quran/screens/quran_memorization_screen.dart';
import 'package:core_models/core_models.dart';
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
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: BorderSide(
              color: isDark 
                  ? AppTheme.primaryGreen.withValues(alpha: 0.25)
                  : borderColor,
              width: isDark ? 1.5 : 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? AppTheme.primaryGreen.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _index = idx),
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.black.withValues(alpha: 0.05),
            child: Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? const Color(0xFF334155) : Colors.white) 
                    : (isDark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.9)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? AppTheme.gold.withValues(alpha: 0.4) 
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: isSelected ? 8 : 4,
                    spreadRadius: isSelected ? 1 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isSelected 
                      ? AppTheme.gold 
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Image.asset(
                'assets/images/TahfidzMU-logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.auto_stories_rounded,
                  color: isSelected ? AppTheme.gold : Colors.grey.shade400,
                  size: 20,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final activeColor = AppTheme.primaryGreen;
    final inactiveColor = isDark ? Colors.white30 : Colors.grey.shade400;
    final labelColor = isSelected 
        ? activeColor 
        : (isDark ? Colors.white70 : Colors.grey.shade600);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _index = idx),
          borderRadius: BorderRadius.circular(16),
          splashColor: activeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Positioned(
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 3,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
