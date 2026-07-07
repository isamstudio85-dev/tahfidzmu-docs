import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/models/pengawas_data.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/features/education/screens/hadits_screen.dart';
import 'package:tahfidz_app/features/profile/screens/musyrif_profil_edit_screen.dart';
import 'package:tahfidz_app/features/profile/screens/ortu_profil_edit_screen.dart';
import 'package:tahfidz_app/features/education/screens/quran_tadarus_screen.dart';
import 'package:tahfidz_app/features/education/screens/educational_list_screen.dart';
import 'package:tahfidz_app/core/widgets/account_switcher.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          if (provider.isAdmin) {
            return _AdminProfilView(
              provider: provider,
              onLogout: () => _showLogoutConfirm(context, provider),
              onPhotoTap: () => _showAdminPhotoOptions(context, provider),
            );
          } else if (provider.isOrangTua) {
            return _OrangTuaProfilView(
              provider: provider,
              onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrangTuaProfilEditScreen())),
              onPhotoTap: () => _showSantriPhotoOptions(context, provider),
              onLogout: () => _showLogoutConfirm(context, provider),
            );
          } else if (provider.isPengawas) {
            return _PengawasProfilView(
              provider: provider,
              onPhotoTap: () => _showPengawasPhotoOptions(context, provider),
              onLogout: () => _showLogoutConfirm(context, provider),
            );
          } else {
            return _MusyrifProfilView(
              provider: provider,
              onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MusyrifProfilEditScreen())),
              onPhotoTap: () => _showMusyrifPhotoOptions(context, provider),
              onLogout: () => _showLogoutConfirm(context, provider),
            );
          }
        },
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan kembali ke halaman login.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () { Navigator.pop(ctx); provider.logout(); }, child: const Text('Keluar')),
        ],
      ),
    );
  }

  static Future<void> _showAdminPhotoOptions(BuildContext context, AppProvider provider) async {
    final source = await _pickImageSource(context);
    if (source != null) {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (file != null) provider.updateAdminPhoto(file.path);
    }
  }

  static Future<void> _showSantriPhotoOptions(BuildContext context, AppProvider provider) async {
    final santri = provider.linkedSantri;
    if (santri == null) return;
    final source = await _pickImageSource(context);
    if (source != null) {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (file != null) provider.updateSantriPhoto(santri.id, file.path);
    }
  }

  static Future<void> _showMusyrifPhotoOptions(BuildContext context, AppProvider provider) async {
    final source = await _pickImageSource(context);
    if (source != null) {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (file != null) {
        provider.updateMusyrifPhoto(file.path);
      }
    }
  }

  static Future<void> _showPengawasPhotoOptions(BuildContext context, AppProvider provider) async {
    final source = await _pickImageSource(context);
    if (source != null) {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (file != null) {
        provider.updatePengawasPhoto(file.path);
      }
    }
  }

  static Future<ImageSource?> _pickImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.camera_alt_rounded), title: const Text('Kamera'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Galeri'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ],
        ),
      ),
    );
  }
}

class _AdminProfilView extends StatelessWidget {
  const _AdminProfilView({required this.provider, required this.onLogout, required this.onPhotoTap});
  final AppProvider provider; final VoidCallback onLogout; final VoidCallback onPhotoTap;
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildHeader('Administrator', 'Admin Utama', provider.adminPhoto, Colors.blue, onPhotoTap: onPhotoTap),
      const SizedBox(height: 24),
      _HafalanFiturList(provider: provider),
      const SizedBox(height: 16),
      _buildSection('AKUN & KEAMANAN', [
        _buildTile(Icons.lock_outline_rounded, 'Ganti Password', Colors.blueGrey, () => _showChangePasswordDialog(context)),
        _buildTile(Icons.logout_rounded, 'Keluar', Colors.red, onLogout),
      ]),
      const SizedBox(height: 24),
      const _AboutCard(),
    ]);
  }
}

class _MusyrifProfilView extends StatelessWidget {
  const _MusyrifProfilView({required this.provider, required this.onEdit, required this.onPhotoTap, required this.onLogout});
  final AppProvider provider; final VoidCallback onEdit; final VoidCallback onPhotoTap; final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final linked = provider.linkedMusyrif;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildHeader(linked?.nama ?? provider.musyrif, linked?.jabatan ?? provider.jabatan, linked?.photoPath ?? provider.musyrifPhoto, AppTheme.primaryGreen, onEdit: onEdit, onPhotoTap: onPhotoTap),
      const SizedBox(height: 24),
      _HafalanFiturList(provider: provider),
      const SizedBox(height: 16),
      _buildSection('PENGATURAN', [
        _buildTile(Icons.lock_outline_rounded, 'Ganti Password', Colors.blueGrey, () => _showChangePasswordDialog(context)),
        _buildTile(Icons.logout_rounded, 'Keluar', Colors.red, onLogout),
      ]),
      const SizedBox(height: 24),
      const _AboutCard(),
    ]);
  }
}

class _OrangTuaProfilView extends StatelessWidget {
  const _OrangTuaProfilView({required this.provider, required this.onEdit, required this.onPhotoTap, required this.onLogout});
  final AppProvider provider; final VoidCallback onEdit; final VoidCallback onPhotoTap; final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final santri = provider.linkedSantri;
    final name = santri?.name ?? 'Wali Santri';
    final photo = santri?.photoPath;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildHeader(name, 'Wali Santri (Orang Tua)', photo, Colors.purple, onEdit: onEdit, onPhotoTap: onPhotoTap),
      const SizedBox(height: 24),
      _HafalanFiturList(provider: provider),
      const SizedBox(height: 16),
      _buildSection('PENGATURAN AKUN', [
        _buildTile(Icons.swap_horiz_rounded, 'Hubungkan Anak', Colors.purple, () => AccountSwitcher.show(context)),
        _buildTile(Icons.lock_outline_rounded, 'Ganti Password', Colors.blueGrey, () => _showChangePasswordDialog(context)),
        _buildTile(Icons.logout_rounded, 'Keluar', Colors.red, onLogout),
      ]),
      const SizedBox(height: 24),
      const _AboutCard(),
    ]);
  }
}

class _HafalanFiturList extends StatelessWidget {
  const _HafalanFiturList({required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    return _buildSection('FITUR HAFALAN', [
      _buildTile(Icons.menu_book_rounded, 'Al-Quran Digital', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranTadarusScreen()))),
      if (provider.isModuleActive('hadits'))
        _buildTile(Icons.import_contacts_rounded, 'Hadits Pilihan', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HaditsScreen()))),
      if (provider.isModuleActive('tajwid'))
        _buildTile(Icons.auto_stories_rounded, 'Ilmu Tajwid', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationalListScreen(type: 'tajwid')))),
      if (provider.isModuleActive('tahsin'))
        _buildTile(Icons.record_voice_over_rounded, 'Ilmu Tahsin', Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EducationalListScreen(type: 'tahsin')))),
    ]);
  }
}

Widget _buildHeader(String name, String subtitle, String? photo, Color color, {VoidCallback? onEdit, VoidCallback? onPhotoTap}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))]),
    child: Row(children: [
      GestureDetector(
        onTap: onPhotoTap,
        child: Stack(children: [
          AppAvatar(name: name, radius: 32, imagePath: photo?.isNotEmpty == true ? photo : null, backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color),
          if (onPhotoTap != null) Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white))),
        ]),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ])),
      if (onEdit != null) IconButton(icon: Icon(Icons.edit_note_rounded, color: color), onPressed: onEdit),
    ]),
  );
}

Widget _buildSection(String title, List<Widget> tiles) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8))),
    Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: tiles)),
  ]);
}

Widget _buildTile(IconData icon, String label, Color color, VoidCallback onTap) {
  return ListTile(leading: Icon(icon, color: color, size: 22), title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey), onTap: onTap);
}

void _showChangePasswordDialog(BuildContext context) {
  final oldCtrl = TextEditingController(); final newCtrl = TextEditingController(); final confirmCtrl = TextEditingController(); String? error;
  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
    title: const Text('Ganti Password'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: oldCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Lama')),
      const SizedBox(height: 12), TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password Baru')),
      const SizedBox(height: 12), TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Password')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
      FilledButton(onPressed: () async {
        if (newCtrl.text != confirmCtrl.text) { setSt(() => error = 'Konfirmasi tidak cocok'); return; }
        final ok = await context.read<AppProvider>().changeOwnPassword(oldCtrl.text, newCtrl.text);
        if (!ctx.mounted) return;
        if (ok) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
        }
        else { setSt(() => error = 'Password lama salah'); }
      }, child: const Text('Simpan')),
    ],
  )));
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(children: [const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryGreen), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TahfidzMU', style: TextStyle(fontWeight: FontWeight.bold)), Text('Versi 1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ])]),
        const SizedBox(height: 12),
        const Text(
          'TahfidzMU adalah aplikasi manajemen Tahfidz mudah dan praktis.\nDibuat oleh Dasam Samsudin.',
          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
        ),
      ]),
    );
  }
}

class _PengawasProfilView extends StatelessWidget {
  const _PengawasProfilView({required this.provider, required this.onPhotoTap, required this.onLogout});
  final AppProvider provider; final VoidCallback onPhotoTap; final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final PengawasData? linked = provider.linkedPengawas;
    final name = linked?.nama ?? 'Pengawas';
    final title = linked?.jabatan ?? 'Pengawas';
    final photo = linked?.photoPath;
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildHeader(name, title, photo, AppTheme.primaryGreen, onPhotoTap: onPhotoTap),
      const SizedBox(height: 24),
      _HafalanFiturList(provider: provider),
      const SizedBox(height: 16),
      _buildSection('PENGATURAN', [
        _buildTile(Icons.lock_outline_rounded, 'Ganti Password', Colors.blueGrey, () => _showChangePasswordDialog(context)),
        _buildTile(Icons.logout_rounded, 'Keluar', Colors.red, onLogout),
      ]),
      const SizedBox(height: 24),
      const _AboutCard(),
    ]);
  }
}
