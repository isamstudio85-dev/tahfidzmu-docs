import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/features/management/screens/santri_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/pengawas_list_screen.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isAdmin = provider.isAdmin;
    final isMusyrif = provider.isMusyrif;

    final tabs = <Widget>[];
    final views = <Widget>[];

    if (isMusyrif) {
      // 1. Tab Halaqah Saya (Filtered Santri)
      tabs.add(const Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Halaqah', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ));
      views.add(const SantriListScreen(hideAppBar: true, showOnlyMine: true));
 
      // 2. Tab Semua Santri
      tabs.add(const Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_rounded, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Santri', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ));
      views.add(const SantriListScreen(hideAppBar: true, showOnlyMine: false));
    } else {
      // Admin only sees standard tabs
      tabs.add(const Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_rounded, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Santri', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ));
      views.add(const SantriListScreen(hideAppBar: true));
    }
 
    // Musyrif Tab (Common for both roles)
    tabs.add(Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin_rounded, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(isMusyrif ? 'Musyrif' : 'Musyrif', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    ));
    views.add(const MusyrifListScreen(hideAppBar: true));
 
    // Admin sees Pengawas tab as well
    if (isAdmin) {
      tabs.add(const Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_rounded, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Pengawas', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ));
      views.add(const PengawasListScreen(hideAppBar: true));
    }
 
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdmin ? 'Manajemen Pengguna' : 'Data Pengguna'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4), // Maximum horizontal space allocation
            isScrollable: false, // Stretch tabs across screen width, no horizontal scroll
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Disable swiping/sliding
          children: views,
        ),
      ),
    );
  }
}
