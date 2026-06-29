import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'santri_list_screen.dart';
import 'user_management_screen.dart';
import 'laporan_screen.dart';
import 'profil_screen.dart';
import 'manajemen_screen.dart';

/// Root shell — shows role-specific tabs in a NavigationBar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  UserRole? _lastRole;

  // ── Role configs ─────────────────────────────────────────────────────────

  static List<Widget> _screensFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          LaporanScreen(),
          ManajemenScreen(),
          ProfilScreen(),
        ];
      case UserRole.musyrif:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          LaporanScreen(),
          ProfilScreen(),
        ];
      case UserRole.orangTua:
        return const [HomeScreen(), LaporanScreen(), ProfilScreen()];
    }
  }

  static List<NavigationDestination> _destinationsFor(UserRole role) {
    const dashboard = NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    );
    // For admin we show "Users" (manages santri & musyrif),
    // for other roles keep the label 'Santri'.
    final users = NavigationDestination(
      icon: const Icon(Icons.group_outlined),
      selectedIcon: const Icon(Icons.group_rounded),
      label: role == UserRole.admin ? 'Users' : 'Santri',
    );
    const laporan = NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart_rounded),
      label: 'Laporan',
    );
    const manajemen = NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Manajemen',
    );
    const profil = NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    );

    switch (role) {
      case UserRole.admin:
        return [dashboard, users, laporan, manajemen, profil];
      case UserRole.musyrif:
        return [dashboard, users, laporan, profil];
      case UserRole.orangTua:
        return [dashboard, laporan, profil];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppProvider>().currentRole!;

    // Reset index when role changes (e.g., after re-login)
    if (_lastRole != role) {
      _lastRole = role;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() => _index = 0),
      );
    }

    final screens = _screensFor(role);
    final destinations = _destinationsFor(role);
    final safeIndex = _index.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 60,
        destinations: destinations,
      ),
    );
  }
}
