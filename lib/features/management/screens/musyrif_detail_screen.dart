import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/widgets/app_avatar.dart';
import 'package:tahfidz_app/core/utils/gamification_utils.dart';
import 'package:tahfidz_app/features/management/screens/musyrif_form_screen.dart';
import 'package:tahfidz_app/features/management/widgets/management_shared_widgets.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';

class MusyrifDetailScreen extends StatelessWidget {
  const MusyrifDetailScreen({super.key, required this.musyrifId});
  final String musyrifId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AppProvider>(
      builder: (ctx, provider, _) {
        final musyrif = provider.getMusyrifById(musyrifId);
        if (musyrif == null) {
          return Scaffold(
            backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
            appBar: AppBar(title: const Text('Detail Musyrif')),
            body: const Center(child: Text('Musyrif tidak ditemukan')),
          );
        }

        final isAdmin = provider.isAdmin;
        final mySantri = provider.getSantriByMusyrif(musyrif.id);
        
        // Calculate Team Stats
        int totalTeamXP = mySantri.fold(0, (sum, s) => sum + s.totalXP);
        
        // Find best halaqah rank
        final myHalaqahs = provider.halaqahList.where((h) => h.musyrifId == musyrif.id).toList();
        int bestRank = 99;
        if (myHalaqahs.isNotEmpty) {
           final Map<String, int> guildXpMap = {};
           for (var s in provider.santriList) {
             if (s.halaqahId == null) continue;
             guildXpMap[s.halaqahId!] = (guildXpMap[s.halaqahId] ?? 0) + s.totalXP;
           }
           final allGuilds = provider.halaqahList.map((h) => (id: h.id, xp: guildXpMap[h.id] ?? 0)).toList();
           allGuilds.sort((a, b) => b.xp.compareTo(a.xp));
           
           for (var h in myHalaqahs) {
             int rank = allGuilds.indexWhere((g) => g.id == h.id) + 1;
             if (rank < bestRank && rank > 0) bestRank = rank;
           }
        }

        return Scaffold(
          backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          appBar: AppBar(
            title: Text(
              'PROFIL PENGURUS',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  tooltip: 'Edit Profil',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MusyrifFormScreen(existing: musyrif)),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              _buildMusyrifHeader(musyrif, isDark),
              const SizedBox(height: 16),
              
              // TEAM HUD
              _buildTeamHUD(totalTeamXP, bestRank, mySantri.length, isDark),
              const SizedBox(height: 24),

              // Personal Info
              InfoSectionCard(
                title: 'INFORMASI PERSONAL', 
                children: [
                  InfoSectionRow(icon: Icons.badge_rounded, label: 'NIP', value: musyrif.nip ?? '-'),
                  InfoSectionRow(icon: Icons.email_rounded, label: 'EMAIL', value: musyrif.email ?? '-'),
                  InfoSectionRow(icon: Icons.wc_rounded, label: 'JENIS KELAMIN', value: musyrif.jenisKelamin == 'P' ? 'PEREMPUAN' : 'LAKI-LAKI'),
                  InfoSectionRow(icon: Icons.phone_rounded, label: 'NO. HP / WA', value: musyrif.nomorHp.isNotEmpty ? musyrif.nomorHp : '-'),
                  InfoSectionRow(icon: Icons.business_rounded, label: 'LEMBAGA', value: musyrif.lembaga),
                  InfoSectionRow(icon: Icons.verified_user_rounded, label: 'STATUS', value: musyrif.isAktif ? 'AKTIF' : 'NON-AKTIF', 
                      valueColor: musyrif.isAktif ? Colors.green : Colors.grey),
                ]
              ),
              const SizedBox(height: 24),

              // TEAM MEMBERS LIST
              if (mySantri.isNotEmpty) ...[
                _sectionTitle('TEAM MEMBERS (${mySantri.length})'),
                const SizedBox(height: 12),
                ...mySantri.take(5).map((s) => _teamMemberTile(context, s, isDark)),
                if (mySantri.length > 5)
                  Center(
                    child: TextButton(
                      onPressed: () {}, // Could link to a full list
                      child: const Text('VIEW ALL MEMBERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                const SizedBox(height: 24),
              ],

              // QR ACTION
              _qrActionCard(context, musyrif, isDark),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMusyrifHeader(MusyrifData m, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          AppAvatar(name: m.nama, radius: 36, imagePath: m.photoPath),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nama.toUpperCase(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  m.jabatan.toUpperCase(),
                  style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHUD(int xp, int rank, int members, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(
            'TEAM COMMANDER STATS', 
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 2)
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _hudItem(Icons.groups_rounded, '$members', 'MEMBERS', AppTheme.primaryGreen, isDark),
              _hudItem(Icons.bolt_rounded, '$xp', 'TEAM XP', Colors.blue, isDark),
              _hudItem(Icons.workspace_premium_rounded, rank == 99 ? '-' : '#$rank', 'RANK', AppTheme.gold, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hudItem(IconData icon, String val, String label, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(val, style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  Widget _teamMemberTile(BuildContext context, dynamic s, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SantriDetailScreen(santriId: s.id))),
        dense: true,
        leading: AppAvatar(name: s.name, radius: 16, imagePath: s.photoPath),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('LVL ${GamificationUtils.calculateLevel(s.totalXP)} • ${s.totalXP} XP', style: const TextStyle(fontSize: 10)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
      ),
    );
  }

  Widget _qrActionCard(BuildContext context, MusyrifData m, bool isDark) {
    return InkWell(
      onTap: () => _showQrDialog(context, m),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text('SHOW DIGITAL ID CARD', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title.toUpperCase(), 
        style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.5)
      ),
    );
  }

  void _showQrDialog(BuildContext context, MusyrifData m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID CARD PENGURUS', style: GoogleFonts.poppins(fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 20),
            QrImageView(data: m.nip ?? m.id, size: 200),
            const SizedBox(height: 16),
            Text(m.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(m.jabatan, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
