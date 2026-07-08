import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/services/login_preferences_service.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/qr_scanner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pesantrenIdCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await LoginPreferencesService.loadLastCredentials();
    if (!mounted || saved == null) return;
    setState(() {
      _pesantrenIdCtrl.text = saved.pesantrenId ?? '';
      _usernameCtrl.text = saved.username;
      _passwordCtrl.text = saved.password;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _pesantrenIdCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _canLogin =>
      _usernameCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      !_isLoading;

  Future<void> _login() async {
    if (!_canLogin) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String? pesantrenId = _pesantrenIdCtrl.text.trim().isEmpty
        ? null
        : _pesantrenIdCtrl.text.trim();
    final String username = _usernameCtrl.text.trim();
    final String password = _passwordCtrl.text;

    final ok = await context.read<AppProvider>().loginWithCredentials(
      pesantrenId,
      username,
      password,
    );

    if (!mounted) return;
    if (!ok) {
      final err = context.read<AppProvider>().loginError;
      setState(() {
        _isLoading = false;
        _errorMessage = err ?? 'Username atau sandi salah.';
      });
    } else {
      if (_rememberMe) {
        await LoginPreferencesService.saveLastCredentials(
          pesantrenId,
          username,
          password,
        );
      } else {
        await LoginPreferencesService.clearLastCredentials();
      }
    }
  }

  Future<void> _scanAndLogin() async {
    final rawString = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen(returnRaw: true)),
    );

    if (!mounted || rawString == null || rawString.trim().isEmpty) return;

    if (rawString.startsWith('tahfidzmu:login:')) {
      final parts = rawString.split(':');
      if (parts.length >= 5) {
        final pesantrenId = parts[2];
        final username = parts[3];
        final password = parts[4];

        setState(() {
          _pesantrenIdCtrl.text = pesantrenId;
          _usernameCtrl.text = username;
          _passwordCtrl.text = password;
          _isLoading = true;
          _errorMessage = null;
        });

        final ok = await context.read<AppProvider>().loginWithCredentials(
          pesantrenId.isEmpty ? null : pesantrenId,
          username,
          password,
        );

        if (!mounted) return;
        if (!ok) {
          final err = context.read<AppProvider>().loginError;
          setState(() {
            _isLoading = false;
            _errorMessage = err ?? 'Gagal masuk menggunakan QR Code.';
          });
        } else {
          // QR login does not save credentials
          await LoginPreferencesService.clearLastCredentials();
        }
      } else {
        setState(() {
          _errorMessage = 'Format QR Code tidak valid.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'QR Code ini bukan kartu login resmi TahfidzMU.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9), // Light background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildLoginForm(),
                const SizedBox(height: 32),
                _buildQuickAccess(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Image.asset(
      'assets/icons/logo-tahfidzmu.png',
      width: 180,
      height: 180,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.auto_stories_rounded,
        size: 100,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildLoginForm() {
    final providerError = context.watch<AppProvider>().loginError;
    final displayError = _errorMessage ?? providerError;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text removed to save space
          TextField(
            controller: _pesantrenIdCtrl,
            decoration: const InputDecoration(
              labelText: 'NPSN Pesantren',
              hintText: 'Masukkan NPSN pesantren Anda',
              prefixIcon: Icon(Icons.business_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username / NIP / NIS',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Kata Sandi',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _rememberMe = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
                child: const Text(
                  'Ingat Saya',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (displayError != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                displayError,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _canLogin ? _login : null,
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: AppTheme.primaryGreen.withValues(
                        alpha: 0.3,
                      ),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 54,
                width: 54,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _scanAndLogin,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 1.5,
                    ),
                    foregroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        children: [
          const Text(
            'BELUM PUNYA AKUN?',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Silahkan hubungi Admin atau Ustadz di Pesantren Anda untuk mendapatkan NIS/NIP terdaftar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
