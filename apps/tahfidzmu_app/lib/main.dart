import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'package:tahfidz_app/features/auth/screens/login_screen.dart';
import 'package:tahfidz_app/features/dashboard/screens/main_shell.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi lokalisasi bahasa Indonesia untuk format tanggal (Riwayat Presensi)
  await initializeDateFormatting('id_ID', null);

  // Crashlytics: tangkap semua error Flutter
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Crashlytics: tangkap error async yang tidak tertangkap
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const TahfidzApp(),
    ),
  );
}

class TahfidzApp extends StatefulWidget {
  const TahfidzApp({super.key});

  @override
  State<TahfidzApp> createState() => _TahfidzAppState();
}

class _TahfidzAppState extends State<TahfidzApp> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Menunggu inisialisasi provider selesai
      final provider = context.read<AppProvider>();
      await provider.initialize();
    } catch (e) {
      debugPrint("Error initializing app: $e");
    } finally {
      // Menghapus splash screen setelah data siap (atau jika error)
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    return MaterialApp(
      title: 'TahfidzMU',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: provider.themeMode,
      home: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (provider.isInitializing || provider.isLoggingOut) {
            return const _AppBootstrapLoadingScreen();
          }
          if (!provider.isLoggedIn) return const LoginScreen();

          if (provider.isSuperAdmin) {
            return const _SuperAdminMobileDisabledScreen();
          }
          return const MainShell();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SuperAdminMobileDisabledScreen extends StatefulWidget {
  const _SuperAdminMobileDisabledScreen();

  @override
  State<_SuperAdminMobileDisabledScreen> createState() =>
      _SuperAdminMobileDisabledScreenState();
}

class _SuperAdminMobileDisabledScreenState
    extends State<_SuperAdminMobileDisabledScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AppProvider>().logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 56,
                color: AppTheme.primaryGreen,
              ),
              SizedBox(height: 16),
              Text(
                'Akses super admin di Android dinonaktifkan. Gunakan web admin untuk masuk sebagai super admin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppTheme.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBootstrapLoadingScreen extends StatefulWidget {
  const _AppBootstrapLoadingScreen();

  @override
  State<_AppBootstrapLoadingScreen> createState() =>
      _AppBootstrapLoadingScreenState();
}

class _AppBootstrapLoadingScreenState
    extends State<_AppBootstrapLoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Loader & Logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/logo-tahfidzmu.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_stories_rounded,
                      size: 90,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Memuat data...',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Developer Branding
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Opacity(
                  opacity: 0.5, // Make it more discreet
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'created by',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/images/isam-logo.png',
                        height: 18, // Much smaller, professional look
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(
                          'iSam',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
