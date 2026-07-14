import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/core/theme/app_theme.dart';
import 'package:tahfidz_app/core/utils/reward_system.dart';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class RewardStoreScreen extends StatefulWidget {
  const RewardStoreScreen({super.key, required this.santri});
  final Santri santri;

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen> {
  int _activeBannerIndex = 0;
  
  final List<String> _bannerPaths = [
    'assets/images/reward_store_banner.jpg',
    'assets/images/banner_store_ramadan.jpg',
    'assets/images/banner_store_desert.jpg',
  ];

  final List<String> _bannerNames = [
    'Default (Pasar Rakyat)',
    'Fajar Ramadhan',
    'Gurun Emas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Reward'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.santri.totalCoins}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game UI Style Banner from AI dengan selector gambar dinamis
            Stack(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage(_bannerPaths[_activeBannerIndex]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.palette_rounded, color: Colors.white, size: 20),
                      tooltip: 'Ganti Gambar Toko',
                      onPressed: () {
                        setState(() {
                          _activeBannerIndex = (_activeBannerIndex + 1) % _bannerPaths.length;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tema Toko diubah ke: ${_bannerNames[_activeBannerIndex]}'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            _sectionHeader('Bingkai Profil', Icons.account_circle_outlined),
            const SizedBox(height: 12),
            _RewardList(
              rewards: RewardSystem.getRewardsByType(RewardType.frame),
              santri: widget.santri,
            ),
            const SizedBox(height: 32),
            _sectionHeader('Gelar Kehormatan', Icons.workspace_premium_outlined),
            const SizedBox(height: 12),
            _RewardList(
              rewards: RewardSystem.getRewardsByType(RewardType.title),
              santri: widget.santri,
            ),
            const SizedBox(height: 32),
            _sectionHeader('Tema Kartu Profil', Icons.style_rounded),
            const SizedBox(height: 12),
            _RewardList(
              rewards: RewardSystem.getRewardsByType(RewardType.theme),
              santri: widget.santri,
            ),
            const SizedBox(height: 32),
            _sectionHeader('Voucher & Hadiah Fisik', Icons.card_giftcard_rounded),
            const SizedBox(height: 12),
            _RewardList(
              rewards: RewardSystem.getRewardsByType(RewardType.physical),
              santri: widget.santri,
              isPhysical: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _RewardList extends StatelessWidget {
  const _RewardList({required this.rewards, required this.santri, this.isPhysical = false});
  final List<VirtualReward> rewards;
  final Santri santri;
  final bool isPhysical;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final isUnlocked = !isPhysical && santri.unlockedItems.contains(reward.id);
        final isActive = !isPhysical && (santri.activeFrame == reward.id || santri.activeTitle == reward.value || santri.activeTheme == reward.id);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isActive ? AppTheme.primaryGreen : Colors.grey.shade200,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Ikon gambar AI atau default Icon
                 Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: reward.type == RewardType.frame 
                      ? Color(reward.value as int).withValues(alpha: 0.1)
                      : (reward.type == RewardType.physical 
                          ? Colors.orange.withValues(alpha: 0.1) 
                          : (reward.type == RewardType.theme ? Colors.blue.withValues(alpha: 0.1) : AppTheme.gold.withValues(alpha: 0.1))),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: reward.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            reward.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              reward.type == RewardType.frame 
                                ? Icons.portrait_rounded 
                                : (reward.type == RewardType.theme 
                                    ? Icons.style_rounded 
                                    : (reward.type == RewardType.physical ? (reward.icon ?? Icons.confirmation_number_rounded) : Icons.military_tech_rounded)),
                              color: reward.type == RewardType.frame 
                                ? Color(reward.value as int) 
                                : (reward.type == RewardType.theme 
                                    ? Colors.blue 
                                    : (reward.type == RewardType.physical ? Colors.orange : AppTheme.gold)),
                              size: 32,
                            ),
                          ),
                        )
                      : Icon(
                          reward.type == RewardType.frame 
                            ? Icons.portrait_rounded 
                            : (reward.type == RewardType.theme 
                                ? Icons.style_rounded 
                                : (reward.type == RewardType.physical ? (reward.icon ?? Icons.confirmation_number_rounded) : Icons.military_tech_rounded)),
                          color: reward.type == RewardType.frame 
                            ? Color(reward.value as int) 
                            : (reward.type == RewardType.theme 
                                ? Colors.blue 
                                : (reward.type == RewardType.physical ? Colors.orange : AppTheme.gold)),
                          size: 32,
                        ),
                ),
                const SizedBox(width: 14),
                // Informasi Detail Reward
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Aksi (Pasang/Beli)
                if (!isPhysical && isUnlocked)
                  SizedBox(
                    height: 36,
                    child: TextButton(
                      onPressed: isActive ? null : () => context.read<AppProvider>().equipReward(santri.id, reward),
                      child: Text(
                        isActive ? 'AKTIF' : 'PASANG',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  FilledButton(
                    onPressed: santri.totalCoins >= reward.cost 
                      ? () => _confirmPurchase(context, reward, isPhysical)
                      : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(80, 36),
                      backgroundColor: isPhysical ? Colors.orange : AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppTheme.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.cost}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPurchase(BuildContext context, VirtualReward reward, bool isPhysical) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPhysical ? 'Tukar Voucher' : 'Konfirmasi Pembelian'),
        content: Text(
          isPhysical 
            ? 'Apakah kamu yakin ingin menukar ${reward.cost} koin dengan ${reward.name}? \n\nKamu akan mendapatkan tiket digital untuk dicairkan ke pengurus.'
            : 'Apakah kamu yakin ingin membeli ${reward.name} seharga ${reward.cost} koin?'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BATAL')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<AppProvider>();
              bool success;
              if (isPhysical) {
                success = await provider.purchasePhysicalReward(santri.id, reward);
              } else {
                success = await provider.purchaseReward(santri.id, reward);
              }

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isPhysical ? '${reward.name} berhasil ditukar! Cek menu "Voucher Saya".' : '${reward.name} berhasil dibeli!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(isPhysical ? 'TUKAR' : 'BELI'),
          ),
        ],
      ),
    );
  }
}
