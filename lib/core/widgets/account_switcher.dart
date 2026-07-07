import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/services/login_preferences_service.dart';

class AccountSwitcher {
  static void show(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final allSaved = await LoginPreferencesService.getSavedAccounts();
    final savedAccounts = allSaved.where((acc) => acc.role == 'orangTua').toList();
    
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hubungkan & Ganti Akun',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const Icon(Icons.people_outline_rounded, color: AppTheme.primaryGreen, size: 22),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bagi orang tua yang memiliki lebih dari satu anak di pesantren, hubungkan akun mereka untuk beralih instan.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 20),
                if (savedAccounts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Belum ada akun lain yang tersimpan.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: savedAccounts.length,
                      itemBuilder: (ctx, idx) {
                        final acc = savedAccounts[idx];
                        
                        // Check if active account matches
                        final bool isCurrentActive = provider.linkedSantriId == acc.linkedId ||
                            provider.linkedMusyrifId == acc.linkedId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrentActive ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentActive ? AppTheme.primaryGreen.withValues(alpha: 0.2) : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            onTap: isCurrentActive
                                ? null
                                : () async {
                                    Navigator.pop(ctx);
                                    final success = await provider.switchAccount(acc);
                                    if (!success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Gagal beralih akun. Silakan coba lagi.')),
                                      );
                                    }
                                  },
                            leading: AppAvatar(
                              name: acc.displayName,
                              radius: 20,
                              imagePath: acc.photoPath,
                              backgroundColor: isCurrentActive ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey.shade100,
                              foregroundColor: isCurrentActive ? AppTheme.primaryGreen : Colors.grey.shade700,
                            ),
                            title: Text(
                              acc.displayName,
                              style: TextStyle(
                                fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentActive ? AppTheme.primaryGreen : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              acc.role == 'orangTua' 
                                  ? 'Wali Santri (${acc.username})' 
                                  : '${acc.role} (${acc.username})',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            trailing: isCurrentActive
                                ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 20)
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      await LoginPreferencesService.removeAccount(acc.username, acc.pesantrenId);
                                      savedAccounts.removeAt(idx);
                                      setModalState(() {});
                                    },
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Show confirmation dialog before logging out to add account
                      _showAddAccountConfirm(context, provider);
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text('HUBUNGKAN AKUN ANAK LAIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showAddAccountConfirm(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hubungkan Akun Baru'),
        content: const Text(
          'Untuk menghubungkan akun baru, Anda akan diarahkan ke halaman Login.\n\n'
          'Silakan masukkan NIS dan password anak Anda yang lain. Akun lama Anda akan tetap tersimpan di aplikasi ini.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.logout();
            },
            child: const Text('Lanjutkan ke Login'),
          ),
        ],
      ),
    );
  }
}
