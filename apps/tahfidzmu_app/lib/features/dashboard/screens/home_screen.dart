import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/dashboard/widgets/admin_dashboard.dart';
import 'package:tahfidz_app/features/dashboard/widgets/musyrif_dashboard.dart';
import 'package:tahfidz_app/features/dashboard/widgets/orang_tua_dashboard.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/tasmi/graduation_portal_screen.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _popupShownInSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_popupShownInSession) {
        _showMotivationalPopup();
        _popupShownInSession = true;
      }
    });
  }

  void _showMotivationalPopup() {
    final provider = context.read<AppProvider>();
    final activeEvents = provider.graduationEvents
        .where((e) => e.isPublished)
        .toList();
    if (activeEvents.isEmpty) return;

    final event = activeEvents.first;
    final candidatesCount = provider.santriList
        .where(
          (s) => s.tasmiHistory.any((t) => t.year == event.year && t.isPass),
        )
        .length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (event.bannerPath != null)
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: event.bannerPath!.startsWith('assets/')
                        ? AssetImage(event.bannerPath!) as ImageProvider
                        : FileImage(File(event.bannerPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: Colors.purple.withValues(alpha: 0.1),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 80,
                      color: AppTheme.gold.withValues(alpha: 0.2),
                    ),
                    const Icon(
                      Icons.school_rounded,
                      size: 50,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'AYO SEMANGAT!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.purple,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pendaftaran ${event.title} Telah Dibuka!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$candidatesCount Santri Sudah Lulus Seleksi',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Jangan sampai ketinggalan momen berharga ini. Tingkatkan hafalanmu dan jadilah penjaga Al-Quran selanjutnya!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GraduationPortalScreen(event: event),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('LIHAT DETAIL WISUDA'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Nanti Saja',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final role = provider.currentRole;

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget body;
    if (provider.isOrangTua) {
      final child = provider.linkedSantri;
      if (child == null) {
        body = const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      } else {
        body = OrangTuaDashboard(child: child);
      }
    } else if (provider.isAdmin || provider.isPengawas) {
      body = AdminDashboard(provider: provider);
    } else {
      body = MusyrifDashboard(provider: provider);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.setupFirestoreListeners();
        },
        child: body,
      ),
    );
  }
}
