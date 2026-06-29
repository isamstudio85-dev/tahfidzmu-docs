import 'package:flutter/material.dart';
import 'santri_list_screen.dart';
import 'musyrif_list_screen.dart';
import '../theme/app_theme.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pengguna'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.people_alt_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Santri', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_pin_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Musyrif', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SantriListScreen(hideAppBar: true),
            MusyrifListScreen(hideAppBar: true),
          ],
        ),
      ),
    );
  }
}
