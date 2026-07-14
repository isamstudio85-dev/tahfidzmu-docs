import 'package:flutter/material.dart';

enum RewardType { frame, title, theme, physical }

class VirtualReward {
  final String id;
  final String name;
  final String description;
  final int cost;
  final RewardType type;
  final dynamic value; // Hex color for frames, string for titles, etc.
  final IconData? icon;
  final String? imagePath;

  const VirtualReward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.type,
    required this.value,
    this.icon,
    this.imagePath,
  });
}

class RewardSystem {
  static const List<VirtualReward> rewards = [
    // --- FRAMES ---
    VirtualReward(
      id: 'frame_gold',
      name: 'Bingkai Emas',
      description: 'Bingkai profil elegan berwarna emas.',
      cost: 500,
      type: RewardType.frame,
      value: 0xFFFFD700,
      imagePath: 'assets/images/icon_gold_frame.jpg',
    ),
    VirtualReward(
      id: 'frame_emerald',
      name: 'Bingkai Zamrud',
      description: 'Bingkai profil hijau zamrud yang sejuk.',
      cost: 300,
      type: RewardType.frame,
      value: 0xFF50C878,
      imagePath: 'assets/images/icon_emerald_frame.jpg',
    ),
    VirtualReward(
      id: 'frame_neon',
      name: 'Bingkai Cyber-Tahfidz',
      description: 'Bingkai profil bercahaya biru neon.',
      cost: 1000,
      type: RewardType.frame,
      value: 0xFF00FFFF,
      imagePath: 'assets/images/icon_neon_frame.jpg',
    ),
    VirtualReward(
      id: 'frame_pink',
      name: 'Bingkai Mutiara Hijab',
      description: 'Bingkai profil merah muda anggun (Khusus Santri Putri).',
      cost: 400,
      type: RewardType.frame,
      value: 0xFFFFB6C1,
      imagePath: 'assets/images/icon_pink_frame.jpg',
    ),
    VirtualReward(
      id: 'frame_orchid',
      name: 'Bingkai Orchid Syafiah',
      description: 'Bingkai profil ungu anggun dan menenangkan.',
      cost: 600,
      type: RewardType.frame,
      value: 0xFFBA55D3,
      imagePath: 'assets/images/icon_orchid_frame.jpg',
    ),
    
    // --- TITLES ---
    VirtualReward(
      id: 'title_guardian',
      name: 'Gelar: Penjaga Wahyu',
      description: 'Gelar kehormatan "Penjaga Wahyu" di profil.',
      cost: 1500,
      type: RewardType.title,
      value: 'Penjaga Wahyu',
      imagePath: 'assets/images/icon_scroll_title.jpg',
    ),
    VirtualReward(
      id: 'title_expert',
      name: 'Gelar: Ahli Tajwid',
      description: 'Gelar kehormatan "Ahli Tajwid" di profil.',
      cost: 800,
      type: RewardType.title,
      value: 'Ahli Tajwid',
      imagePath: 'assets/images/icon_scroll_title.jpg',
    ),
    VirtualReward(
      id: 'title_sultan',
      name: 'Gelar: Sultan Hafidz',
      description: 'Gelar kehormatan "Sultan Hafidz" di profil.',
      cost: 5000,
      type: RewardType.title,
      value: 'Sultan Hafidz',
      imagePath: 'assets/images/icon_scroll_title.jpg',
    ),
    VirtualReward(
      id: 'title_queen',
      name: 'Gelar: Sayyidah Hafizhah',
      description: 'Gelar kehormatan "Sayyidah Hafizhah" untuk putri.',
      cost: 5000,
      type: RewardType.title,
      value: 'Sayyidah Hafizhah',
      imagePath: 'assets/images/icon_scroll_title.jpg',
    ),
    VirtualReward(
      id: 'title_expert_female',
      name: 'Gelar: Mutiara Tajwid',
      description: 'Gelar kehormatan "Mutiara Tajwid" untuk putri.',
      cost: 800,
      type: RewardType.title,
      value: 'Mutiara Tajwid',
      imagePath: 'assets/images/icon_scroll_title.jpg',
    ),

    // --- PHYSICAL REWARDS / VOUCHERS ---
    VirtualReward(
      id: 'voucher_kantin_1',
      name: 'Voucher Makan Kantin Pondok',
      description: 'Tukar dengan 1 porsi makan gratis di Kantin Utama Pesantren.',
      cost: 2000,
      type: RewardType.physical,
      value: 'physical',
      icon: Icons.fastfood_rounded,
    ),
    VirtualReward(
      id: 'voucher_koperasi_1',
      name: 'Voucher Jajan Koperasi',
      description: 'Tukar dengan snack/minuman dingin senilai Rp 5.000 di Koperasi.',
      cost: 500,
      type: RewardType.physical,
      value: 'physical',
      icon: Icons.storefront_rounded,
    ),
    VirtualReward(
      id: 'voucher_warung_kopi',
      name: 'Voucher Kopi & Gorengan Warung Pondok',
      description: 'Tukar dengan 1 gelas kopi hangat dan 2 buah gorengan di Warung Santri.',
      cost: 800,
      type: RewardType.physical,
      value: 'physical',
      icon: Icons.coffee_rounded,
    ),
    VirtualReward(
      id: 'voucher_laundry_1',
      name: 'Voucher Laundry Kilat Pondok',
      description: 'Tukar dengan 1 slot cuci-setrika laundry gratis di Laundry Pesantren.',
      cost: 1200,
      type: RewardType.physical,
      value: 'physical',
      icon: Icons.local_laundry_service_rounded,
    ),
    VirtualReward(
      id: 'voucher_izin_1',
      name: 'Tiket Bebas Piket / Izin Halaqah',
      description: 'Izin 1 hari tidak piket pondok atau bebas halaqah sore (izin resmi Musyrif).',
      cost: 3000,
      type: RewardType.physical,
      value: 'physical',
      icon: Icons.card_membership_rounded,
    ),
    
    // --- CARD BACKGROUND THEMES ---
    VirtualReward(
      id: 'theme_ramadan',
      name: 'Tema Kartu: Fajar Ramadhan',
      description: 'Latar belakang kartu profil bertema fajar masjid emas yang premium.',
      cost: 1200,
      type: RewardType.theme,
      value: 'assets/images/banner_store_ramadan.jpg',
      imagePath: 'assets/images/banner_store_ramadan.jpg',
    ),
    VirtualReward(
      id: 'theme_desert',
      name: 'Tema Kartu: Gurun Emas',
      description: 'Latar belakang kartu profil bertema gurun pasir malam bertabur bintang.',
      cost: 1500,
      type: RewardType.theme,
      value: 'assets/images/banner_store_desert.jpg',
      imagePath: 'assets/images/banner_store_desert.jpg',
    ),
  ];

  static List<VirtualReward> getRewardsByType(RewardType type) {
    return rewards.where((r) => r.type == type).toList();
  }
  
  static Color? getFrameColor(String? frameId) {
    if (frameId == null) return null;
    try {
      final reward = rewards.firstWhere((r) => r.id == frameId);
      return Color(reward.value as int);
    } catch (_) {
      return null;
    }
  }
}
