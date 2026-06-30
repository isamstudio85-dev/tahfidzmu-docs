import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'package:tahfidz_app/features/auth/screens/login_screen.dart';
import 'package:tahfidz_app/features/dashboard/screens/main_shell.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Menahan splash screen agar tidak hilang sebelum aplikasi siap
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
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

class _AppBootstrapLoadingScreenState extends State<_AppBootstrapLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.1),
              AppTheme.primaryGreen.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 50,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'TahfidzMU',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aplikasi Manajemen Tahfidz',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Loading indicator dengan custom style
              _buildAnimatedLoader(),
              const SizedBox(height: 20),
              Text(
                'Mempersiapkan aplikasi...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoader() {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  width: 4,
                ),
              ),
            ),
          ),
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border(
                  top: BorderSide(color: AppTheme.primaryGreen, width: 4),
                  right: BorderSide(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                    width: 4,
                  ),
                  bottom: BorderSide(color: Colors.transparent, width: 4),
                  left: BorderSide(color: Colors.transparent, width: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
