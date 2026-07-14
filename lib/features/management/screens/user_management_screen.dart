import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
            Text('Halaqah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            Text('Santri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            Text('Santri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ));
      views.add(const SantriListScreen(hideAppBar: true));
    }
 
    // Musyrif Tab (Common for both roles)
    tabs.add(const Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_rounded, size: 16),
          SizedBox(width: 4),
          Text('Musyrif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            Text('Pengawas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ));
      views.add(const PengawasListScreen(hideAppBar: true));
    }
 
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                isAdmin ? 'ACADEMY HUB' : 'DATA PENGGUNA',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
              ),
              Text(
                isAdmin ? 'Manajemen Seluruh Karakter' : 'Daftar Pejuang Al-Qur\'an',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryGreen, Color(0xFF065F46)],
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                tabs: tabs,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBg : const Color(0xFFF8F9FA),
          ),
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: views,
          ),
        ),
      ),
    );
  }
}
