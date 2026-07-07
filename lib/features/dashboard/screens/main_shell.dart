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

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  UserRole? _lastRole;

  static List<Widget> _screensFor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return const [];
      case UserRole.admin:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          ManajemenScreen(),
          ProfilScreen(),
        ];
      case UserRole.musyrif:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          QuranMemorizationScreen(),
          ProfilScreen(),
        ];
      case UserRole.orangTua:
        return const [
          HomeScreen(),
          QuranMemorizationScreen(),
          ProfilScreen(),
        ];
      case UserRole.pengawas:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          ProfilScreen(),
        ];
    }
  }

  static List<NavigationDestination> _destinationsFor(UserRole role) {
    final List<NavigationDestination> dest = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Beranda',
      ),
    ];

    if (role != UserRole.orangTua) {
      dest.add(NavigationDestination(
        icon: const Icon(Icons.group_outlined),
        selectedIcon: const Icon(Icons.group_rounded),
        label: (role == UserRole.admin || role == UserRole.pengawas) ? 'Users' : 'Santri',
      ));
    }

    if (role != UserRole.admin && role != UserRole.pengawas) {
      dest.add(const NavigationDestination(
        icon: Icon(Icons.history_edu_outlined),
        selectedIcon: Icon(Icons.history_edu_rounded),
        label: 'Hafalan',
      ));
    }

    if (role == UserRole.admin) {
      dest.add(const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Sistem',
      ));
    }

    dest.add(const NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ));

    return dest;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AppProvider, UserRole?>((p) => p.currentRole);

    if (role == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_lastRole != role) {
      _lastRole = role;
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _index = 0));
    }

    final screens = _screensFor(role);
    final destinations = _destinationsFor(role);
    final safeIndex = _index.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          height: 65,
          backgroundColor: const Color(0xFFF1F8E9), 
          indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
          elevation: 0,
          destinations: destinations,
        ),
      ),
    );
  }
}
