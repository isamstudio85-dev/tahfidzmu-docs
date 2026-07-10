import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;
  List<SavedAccount> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    final list = await LoginPreferencesService.getSavedAccounts();
    if (!mounted) return;
    setState(() {
      _savedAccounts = list;
    });
  }

  List<Widget> _buildSuggestions() {
    final userQuery = _usernameCtrl.text.toLowerCase();
    final npsnQuery = _pesantrenIdCtrl.text.toLowerCase();

    if (userQuery.isEmpty && npsnQuery.isEmpty) {
      return [];
    }

    final filtered = _savedAccounts.where((account) {
      bool matchesUser = true;
      if (userQuery.isNotEmpty) {
        matchesUser =
            account.username.toLowerCase().contains(userQuery) ||
            account.displayName.toLowerCase().contains(userQuery);
      }
      bool matchesNpsn = true;
      if (npsnQuery.isNotEmpty) {
        matchesNpsn = (account.pesantrenId ?? '').toLowerCase().contains(
          npsnQuery,
        );
      }
      return matchesUser && matchesNpsn;
    }).toList();

    if (filtered.isEmpty) {
      return [];
    }

    return [
      const SizedBox(height: 8),
      Container(
        constraints: const BoxConstraints(maxHeight: 140),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final account = filtered[index];
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                foregroundImage: account.photoPath != null
                    ? NetworkImage(account.photoPath!)
                    : null,
                child: Text(
                  account.displayName.isNotEmpty
                      ? account.displayName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              title: Text(
                account.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                '${account.username}${account.pesantrenId != null ? ' @ ${account.pesantrenId}' : ''}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  await LoginPreferencesService.removeAccount(
                    account.username,
                    account.pesantrenId,
                  );
                  _loadSavedAccounts();
                },
              ),
              onTap: () {
                setState(() {
                  _pesantrenIdCtrl.text = account.pesantrenId ?? '';
                  _usernameCtrl.text = account.username;
                  _passwordCtrl.clear();
                  _errorMessage = null;
                });
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            );
          },
        ),
      ),
    ];
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
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
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final String pesantrenId = _pesantrenIdCtrl.text.trim();
    final String username = _usernameCtrl.text.trim();
    final String password = _passwordCtrl.text;

    if (pesantrenId.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'NPSN, Username, dan Kata Sandi wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ok = await context.read<AppProvider>().loginWithCredentials(
      pesantrenId,
      username,
      password,
    );

    if (!mounted) return;
    if (!ok) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Username atau sandi salah.';
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
    if (_isLoading) return;

    final rawString = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen(returnRaw: true)),
    );

    if (!mounted || rawString == null || rawString.trim().isEmpty) return;

    if (rawString.startsWith('tahfidzmu:login:')) {
      final parts = rawString.split(':');
      if (parts.length >= 4) {
        final pesantrenId = parts[2];
        final username = parts[3];
        final password = parts.length >= 5 ? parts[4] : username;

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
          qrLogin: true,
        );

        if (!mounted) return;
        if (!ok) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Username atau sandi salah.';
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
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _errorMessage = null;
              context.read<AppProvider>().clearLoginError();
            });
            await context.read<AppProvider>().initialize();
          },
          child: Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildLoginForm(),
                  const SizedBox(
                    height: 28,
                  ), // Beri jarak lebih longgar ke bawah
                  _buildQuickAccess(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Image.asset(
      'assets/icons/logo-tahfidzmu.png',
      width: 130,
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.auto_stories_rounded,
        size: 70,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildLoginForm() {
    final providerError = context.watch<AppProvider>().loginError;
    final displayError =
        _errorMessage ??
        (providerError != null ? 'Username atau sandi salah.' : null);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          TextField(
            controller: _pesantrenIdCtrl,
            onChanged: (val) {
              setState(() {
                _errorMessage = null;
                context.read<AppProvider>().clearLoginError();
              });
            },
            decoration: const InputDecoration(
              labelText: 'NPSN Pesantren',
              hintText: 'Masukkan NPSN pesantren Anda',
              prefixIcon: Icon(Icons.business_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameCtrl,
            onChanged: (val) {
              setState(() {
                _errorMessage = null;
                context.read<AppProvider>().clearLoginError();
              });
            },
            decoration: const InputDecoration(
              labelText: 'Username / NIP / NIS',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          ..._buildSuggestions(),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            onChanged: (val) {
              setState(() {
                _errorMessage = null;
                context.read<AppProvider>().clearLoginError();
              });
            },
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _login,
                    style:
                        FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppTheme.primaryGreen.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white.withValues(alpha: 0.15);
                              }
                              return null;
                            },
                          ),
                        ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                  onPressed: _scanAndLogin,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(
                      color: _isLoading ? Colors.grey.shade300 : AppTheme.primaryGreen,
                      width: 1.5,
                    ),
                    foregroundColor: _isLoading ? Colors.grey.shade400 : AppTheme.primaryGreen,
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
    final textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade600,
      letterSpacing: 1.5,
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      child: Column(
        children: [
          Text('BELUM PUNYA AKUN?', style: textStyle),
          const SizedBox(height: 6),
          Text(
            'Silahkan hubungi admin pesantren Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _launchURL(
                  'https://isamstudio85-dev.github.io/tahfidzmu-docs/help.html',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Bantuan',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                '•',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
              InkWell(
                onTap: () => _launchURL(
                  'https://isamstudio85-dev.github.io/tahfidzmu-docs/',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Privasi',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                '•',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
              ),
              InkWell(
                onTap: () => _launchURL(
                  'https://isamstudio85-dev.github.io/tahfidzmu-docs/terms-of-service.html',
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Persyaratan',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Jarak aman di bagian paling bawah
        ],
      ),
    );
  }
}
