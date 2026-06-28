import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import 'hadits_screen.dart';
import 'musyrif_profil_edit_screen.dart';
import 'ortu_profil_edit_screen.dart';
import 'pesantren_screen.dart';
import 'quran_tadarus_screen.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Consumer<AppProvider>(
        builder: (ctx, provider, _) {
          if (provider.isOrangTua) {
            return _OrangTuaProfilView(
              provider: provider,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrangTuaProfilEditScreen(),
                ),
              ),
              onPhotoTap: () => _showSantriPhotoOptions(context, provider),
              onLogout: () => _showLogoutConfirm(context, provider),
            );
          }
          return _MusyrifProfilView(
            provider: provider,
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MusyrifProfilEditScreen(),
              ),
            ),
            onPhotoTap: () => _showPhotoOptions(context, provider),
            onReset: () => _showResetConfirm(context, provider),
            onPesantren: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PesantrenScreen()),
            ),
            onLogout: () => _showLogoutConfirm(context, provider),
          );
        },
      ),
    );
  }

  static Future<void> _showSantriPhotoOptions(
    BuildContext context,
    AppProvider provider,
  ) async {
    final santri = provider.linkedSantri;
    if (santri == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto Santri',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (santri.photoPath?.isNotEmpty ?? false)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.updateSantriPhoto(santri.id, '');
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 600,
    );
    if (file != null && context.mounted) {
      provider.updateSantriPhoto(santri.id, file.path);
    }
  }

  static Future<void> _showPhotoOptions(
    BuildContext context,
    AppProvider provider,
  ) async {
    final linked = provider.linkedMusyrif;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto Profil Musyrif',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if ((linked?.photoPath?.isNotEmpty ?? false) ||
                  provider.musyrifPhoto.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Hapus Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (linked != null) {
                      provider.updateMusyrifData(
                        linked.id,
                        linked.copyWith(photoPath: ''),
                      );
                    } else {
                      provider.updateMusyrifPhoto('');
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 600,
    );
    if (file != null && context.mounted) {
      if (linked != null) {
        provider.updateMusyrifData(
          linked.id,
          linked.copyWith(photoPath: file.path),
        );
      } else {
        provider.updateMusyrifPhoto(file.path);
      }
    }
  }

  void _showLogoutConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Anda akan kembali ke halaman pemilihan peran.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              provider.logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Data Santri?'),
        content: const Text(
          'Semua data santri dan riwayat setoran akan dihapus permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.resetAllData();
              Navigator.pop(ctx);
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }
}

// ── _MusyrifProfilView ─────────────────────────────────────────────────────────

class _MusyrifProfilView extends StatelessWidget {
  const _MusyrifProfilView({
    required this.provider,
    required this.onEdit,
    required this.onPhotoTap,
    required this.onReset,
    required this.onPesantren,
    required this.onLogout,
  });

  final AppProvider provider;
  final VoidCallback onEdit;
  final VoidCallback onPhotoTap;
  final VoidCallback onReset;
  final VoidCallback onPesantren;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final linked = provider.linkedMusyrif;
    // Admin: show role only — no jabatan/lembaga/HP
    final isAdmin = provider.isAdmin;
    final displayName =
        linked?.nama ?? (isAdmin ? 'Kang Admin' : provider.musyrif);
    final displayJabatan = isAdmin
        ? 'Administrator'
        : (linked?.jabatan ?? provider.jabatan);
    final displayLembaga = isAdmin ? '' : (linked?.lembaga ?? provider.lembaga);
    final displayNomorHp = isAdmin ? '' : (linked?.nomorHp ?? provider.nomorHp);
    final displayPhoto = linked?.photoPath ?? provider.musyrifPhoto;

    final mySetorans = linked != null
        ? provider
              .getSantriByMusyrif(linked.id)
              .expand((s) => s.setoranHistory)
              .toList()
        : provider.santriList.expand((s) => s.setoranHistory).toList();
    final now = DateTime.now();
    final todayCount = mySetorans
        .where(
          (s) =>
              s.date.year == now.year &&
              s.date.month == now.month &&
              s.date.day == now.day,
        )
        .length;
    final mySantriCount = linked != null
        ? provider.getSantriByMusyrif(linked.id).length
        : provider.santriList.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Profile header ────────────────────────────────────────────────
        _ProfileHeader(
          musyrif: displayName,
          jabatan: displayJabatan,
          lembaga: displayLembaga,
          nomorHp: displayNomorHp,
          photoPath: displayPhoto,
          onEdit: onEdit,
          onPhotoTap: onPhotoTap,
        ),
        const SizedBox(height: 20),

        // ── Quick stats ───────────────────────────────────────────────────
        Row(
          children: [
            _StatCard(
              icon: Icons.people_alt_rounded,
              label: 'Santri',
              value: '$mySantriCount',
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.list_alt_rounded,
              label: 'Total Setoran',
              value: '${mySetorans.length}',
              color: AppTheme.gold,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.today_rounded,
              label: 'Hari Ini',
              value: '$todayCount',
              color: const Color(0xFF7B1FA2),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Bacaan ─────────────────────────────────────────────────────────
        _Section(
          title: 'Bacaan',
          children: [
            _SettingsTile(
              icon: Icons.menu_book_rounded,
              label: 'Baca Al-Quran',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuranTadarusScreen()),
              ),
            ),
            if (provider.isModuleActive('hadits')) ...[
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.import_contacts_rounded,
                label: 'Hadits Pilihan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HaditsScreen()),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── Settings ──────────────────────────────────────────────────────
        _Section(
          title: 'Pengaturan',
          children: [
            _SettingsTile(
              icon: Icons.edit_rounded,
              label: 'Edit Profil Musyrif',
              onTap: onEdit,
            ),
            const Divider(height: 1, indent: 56),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Ganti Password',
              onTap: () => _showChangePasswordDialog(context),
            ),
            const Divider(height: 1, indent: 56),
            if (provider.isAdmin) ...[
              _SettingsTile(
                icon: Icons.school_rounded,
                label: 'Informasi Pesantren',
                onTap: onPesantren,
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.delete_sweep_rounded,
                label: 'Reset Semua Data Santri',
                color: Colors.red,
                onTap: onReset,
              ),
              const Divider(height: 1, indent: 56),
            ],
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              color: Colors.red,
              onTap: onLogout,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── About ─────────────────────────────────────────────────────────
        _AboutCard(),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'TahfidzMU v1.0.0 · Dibuat oleh Dasam Samsudin',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── _OrangTuaProfilView ────────────────────────────────────────────────────────

class _OrangTuaProfilView extends StatelessWidget {
  const _OrangTuaProfilView({
    required this.provider,
    required this.onEdit,
    required this.onPhotoTap,
    required this.onLogout,
  });

  final AppProvider provider;
  final VoidCallback onEdit;
  final VoidCallback onPhotoTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final santri = provider.linkedSantri;
    if (santri == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Data anak tidak ditemukan.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onLogout,
              child: const Text('Pilih Ulang'),
            ),
          ],
        ),
      );
    }

    final setorans = santri.setoranHistory;
    final avg = santri.averageScore;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Child profile card ────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onPhotoTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AppAvatar(
                          name: santri.name,
                          radius: 32,
                          imagePath: (santri.photoPath?.isNotEmpty ?? false)
                              ? santri.photoPath
                              : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF9C27B0),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: Color(0xFF9C27B0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          santri.name,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (santri.kelas != null)
                          Text(
                            santri.kelas!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        if (santri.nis != null)
                          Text(
                            'NIS: ${santri.nis!}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (santri.targetHafalan != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Target: ${santri.targetHafalan}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Stats ─────────────────────────────────────────────────────────
        Row(
          children: [
            _StatCard(
              icon: Icons.list_alt_rounded,
              label: 'Total Setoran',
              value: '${setorans.length}',
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.star_rounded,
              label: 'Rata-rata Skor',
              value: avg > 0 ? avg.toStringAsFixed(1) : '-',
              color: AppTheme.gold,
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Icons.menu_book_rounded,
              label: 'Juz Hafalan',
              value: santri.estimatedJuz >= 1
                  ? '≈ ${santri.estimatedJuz.toStringAsFixed(1)}'
                  : '< 1',
              color: const Color(0xFF7B1FA2),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Parent info ───────────────────────────────────────────────────
        _Section(
          title: 'Informasi Wali',
          children: [
            _InfoRow(label: 'Nama Ayah', value: santri.namaAyah ?? '-'),
            const Divider(height: 1, indent: 16),
            _InfoRow(label: 'Nama Ibu', value: santri.namaIbu ?? '-'),
            const Divider(height: 1, indent: 16),
            _InfoRow(label: 'Nomor HP Wali', value: santri.nomorHpWali ?? '-'),
            const Divider(height: 1, indent: 56),
            _SettingsTile(
              icon: Icons.edit_rounded,
              label: 'Edit Informasi Wali',
              onTap: onEdit,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Account ───────────────────────────────────────────────────────
        _Section(
          title: 'Al-Quran',
          children: [
            _SettingsTile(
              icon: Icons.menu_book_rounded,
              label: 'Baca Al-Quran',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuranTadarusScreen()),
              ),
            ),
            if (provider.isModuleActive('hadits')) ...[
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.import_contacts_rounded,
                label: 'Hadits Pilihan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HaditsScreen()),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── Account ──────────────────────────────────────────────────────
        _Section(
          title: 'Akun',
          children: [
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Ganti Password',
              onTap: () => _showChangePasswordDialog(context),
            ),
            const Divider(height: 1, indent: 56),
            _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              color: Colors.red,
              onTap: onLogout,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'TahfidzMU v1.0.0 · Dibuat oleh Dasam Samsudin',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Change Password dialog ─────────────────────────────────────────────────────
void _showChangePasswordDialog(BuildContext context) {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String? error;
  bool obscureOld = true;
  bool obscureNew = true;

  showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Ganti Password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: obscureOld,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureOld
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setSt(() => obscureOld = !obscureOld),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: obscureNew,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureNew
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setSt(() => obscureNew = !obscureNew),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password Baru',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text.length < 4) {
                setSt(() => error = 'Password minimal 4 karakter.');
                return;
              }
              if (newCtrl.text != confirmCtrl.text) {
                setSt(() => error = 'Konfirmasi password tidak cocok.');
                return;
              }
              final ok = await context.read<AppProvider>().changeOwnPassword(
                oldCtrl.text,
                newCtrl.text,
              );
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password berhasil diubah.')),
                );
              } else {
                setSt(() => error = 'Password lama salah.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.musyrif,
    required this.jabatan,
    required this.lembaga,
    required this.nomorHp,
    required this.photoPath,
    required this.onEdit,
    required this.onPhotoTap,
  });

  final String musyrif;
  final String jabatan;
  final String lembaga;
  final String nomorHp;
  final String photoPath;
  final VoidCallback onEdit;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppAvatar(
                  name: musyrif,
                  radius: 32,
                  imagePath: photoPath.isNotEmpty ? photoPath : null,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  foregroundColor: Colors.white,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  musyrif,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jabatan,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                if (lembaga.isNotEmpty)
                  Text(
                    lembaga,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                if (nomorHp.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        color: Colors.white60,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        nomorHp,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            tooltip: 'Edit profil',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryGreen;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ── About card ──────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TahfidzMU',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Description
          Text(
            'TahfidzMU adalah aplikasi untuk membantu mengelola hafalan '
            'santri dengan cara yang mudah dan praktis. Mencakup pencatatan '
            'setoran, penilaian bacaan, pemantauan perkembangan hafalan, '
            'serta peringkat dan statistik santri dalam satu sistem terpadu.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Meta
          Text(
            'Dibuat oleh Dasam Samsudin  ·  Android & iOS',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
