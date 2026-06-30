import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_role.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'santri_list_screen.dart';
import 'user_management_screen.dart';
import 'setoran_screen.dart';
import 'profil_screen.dart';
import 'manajemen_screen.dart';

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
      case UserRole.admin:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          SetoranScreen(),
          ManajemenScreen(),
          ProfilScreen(),
        ];
      case UserRole.musyrif:
        return const [
          HomeScreen(),
          UserManagementScreen(),
          SetoranScreen(),
          ProfilScreen(),
        ];
      case UserRole.orangTua:
        return const [HomeScreen(), SetoranScreen(), ProfilScreen()];
    }
  }

  static List<NavigationDestination> _destinationsFor(UserRole role) {
    return [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Beranda',
      ),
      NavigationDestination(
        icon: const Icon(Icons.group_outlined),
        selectedIcon: const Icon(Icons.group_rounded),
        label: role == UserRole.admin ? 'Users' : 'Santri',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_edu_outlined),
        selectedIcon: Icon(Icons.history_edu_rounded),
        label: 'Setoran',
      ),
      if (role == UserRole.admin)
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Sistem',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppProvider>().currentRole!;

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
              offset: const Offset(0, -2), // Shadow pointing upwards
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
