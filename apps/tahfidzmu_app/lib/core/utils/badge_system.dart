import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';

class BadgeInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class BadgeSystem {
  static const Map<String, BadgeInfo> badges = {
    'first_setoran': BadgeInfo(
      id: 'first_setoran',
      name: 'Langkah Pertama',
      description: 'Melakukan setoran pertama di aplikasi.',
      icon: Icons.directions_walk_rounded,
      color: Colors.blue,
    ),
    'mumtaz_award': BadgeInfo(
      id: 'mumtaz_award',
      name: 'Bintang Mumtaz',
      description: 'Mendapatkan nilai Mumtaz (>= 90).',
      icon: Icons.star_rounded,
      color: Colors.amber,
    ),
    'streak_3': BadgeInfo(
      id: 'streak_3',
      name: 'Pejuang Istiqomah',
      description: 'Setoran 3 hari berturut-turut.',
      icon: Icons.local_fire_department_rounded,
      color: Colors.orange,
    ),
    'juz_30_master': BadgeInfo(
      id: 'juz_30_master',
      name: 'Hafidz Juz 30',
      description: 'Menyelesaikan hafalan seluruh Juz 30.',
      icon: Icons.auto_stories_rounded,
      color: Colors.green,
    ),
    'murojaah_hero': BadgeInfo(
      id: 'murojaah_hero',
      name: 'Pahlawan Murojaah',
      description: 'Melakukan 10 kali setoran Murojaah.',
      icon: Icons.replay_rounded,
      color: Colors.teal,
    ),
  };

  static List<String> checkNewBadges(Santri santri, SetoranRecord record, int newStreak) {
    final List<String> newUnlocked = [];
    final current = santri.unlockedBadges;

    // 1. First Setoran
    if (!current.contains('first_setoran')) {
      newUnlocked.add('first_setoran');
    }

    // 2. Mumtaz Award
    if (record.finalScore >= 90 && !current.contains('mumtaz_award')) {
      newUnlocked.add('mumtaz_award');
    }

    // 3. Streak 3
    if (newStreak >= 3 && !current.contains('streak_3')) {
      newUnlocked.add('streak_3');
    }

    // 4. Juz 30 Master
    if (record.surahNumber == 78 && record.ayahStart == 1 && !current.contains('juz_30_master')) {
        // Simplified check: if they ever setoran An-Naba, we check if they covered Juz 30
        if (santri.juzCoveredByZiyadah.contains(30)) {
           newUnlocked.add('juz_30_master');
        }
    } else if (santri.juzCoveredByZiyadah.contains(30) && !current.contains('juz_30_master')) {
       newUnlocked.add('juz_30_master');
    }

    // 5. Murojaah Hero
    final murojaahCount = santri.setoranHistory.where((s) => s.type == SetoranType.murojaah).length;
    if (murojaahCount >= 9 && record.type == SetoranType.murojaah && !current.contains('murojaah_hero')) {
      newUnlocked.add('murojaah_hero');
    }

    return newUnlocked;
  }
}
