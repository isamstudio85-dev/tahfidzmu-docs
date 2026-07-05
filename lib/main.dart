import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'package:tahfidz_app/features/auth/screens/login_screen.dart';
import 'package:tahfidz_app/features/dashboard/screens/main_shell.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Menahan splash screen agar tidak hilang sebelum aplikasi siap
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Optimal Offline Support: Enable Firestore persistence and large cache
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
    return MaterialApp(
      title: 'TahfidzMU',
      theme: AppTheme.light,
      home: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (provider.isInitializing) {
            return const _AppBootstrapLoadingScreen();
          }
          return provider.isLoggedIn ? const MainShell() : const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppBootstrapLoadingScreen extends StatefulWidget {
  const _AppBootstrapLoadingScreen();

  @override
  State<_AppBootstrapLoadingScreen> createState() =>
      _AppBootstrapLoadingScreenState();
}

class _AppBootstrapLoadingScreenState extends State<_AppBootstrapLoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/logo-tahfidzmu.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_stories_rounded,
                size: 100,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 40,
              height: 40,
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
    );
  }
}
