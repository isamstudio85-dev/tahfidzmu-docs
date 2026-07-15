import 'package:core_models/core_models.dart';

class GamificationUtils {
  /// Base XP per ayah passed
  static const int xpPerAyah = 10;
  
  /// Bonus XP for specific grades
  static int getGradeBonus(double score) {
    if (score >= 95) return 150; // Mumtaz+
    if (score >= 90) return 100; // Mumtaz
    if (score >= 80) return 50;  // Jayyid Jiddan
    if (score >= 65) return 20;  // Jayyid
    return 0;
  }

  /// Calculate total XP earned from a setoran
  static int calculateXP(SetoranRecord record) {
    int baseXP;
    if (record.calculationMethod == 'baris' && record.totalLines != null) {
      baseXP = record.totalLines! * xpPerAyah;
    } else {
      baseXP = record.passedAyahs.length * xpPerAyah;
    }
    int gradeBonus = getGradeBonus(record.finalScore);
    
    // Ziyadah (new memorization) gives 20% bonus
    double multiplier = record.type == SetoranType.ziyadah ? 1.2 : 1.0;
    
    // Perfect Flow combo gives 1.5x multiplier
    final bool isPerfectFlow = checkPerfectFlow(record);
    if (isPerfectFlow) {
      multiplier *= 1.5;
    }
    
    return ((baseXP + gradeBonus) * multiplier).round();
  }

  /// Check if setoran qualifies for Perfect Flow (no errors, min length)
  static bool checkPerfectFlow(SetoranRecord record) {
    final hasNoErrors = record.errorMarks.isEmpty;
    if (!hasNoErrors) return false;
    
    if (record.calculationMethod == 'baris') {
      final lines = record.totalLines ?? 0;
      return lines >= 15; // 1 halaman mushaf standard = 15 baris
    } else {
      // 5 ayat ke atas tanpa salah dianggap memenuhi kualifikasi panjang halaman rata-rata
      return record.passedAyahs.length >= 5; 
    }
  }

  /// Calculate Coins earned from a setoran
  static int calculateCoins(SetoranRecord record) {
    if (record.finalScore >= 95) return 25; // Platinum
    if (record.finalScore >= 90) return 15; // Gold
    if (record.finalScore >= 80) return 5;  // Silver
    return 2; // Participation
  }

  /// Bonus coins for leveling up
  static int getLevelUpBonus(int newLevel) {
    return newLevel * 50;
  }

  /// Levels are based on a quadratic scale: level = sqrt(xp / 100)
  /// Level 1: 100 XP
  /// Level 2: 400 XP
  /// Level 3: 900 XP
  /// Level 10: 10,000 XP
  static int calculateLevel(int xp) {
    // XP = level * 250
    // Level 1: 0-249 XP
    // Level 2: 250-499 XP
    // ...
    return (xp / 250).floor() + 1;
  }
  
  /// Returns the XP required for the specific level (start of level)
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (level - 1) * 250;
  }
  
  /// Returns progress (0.0 to 1.0) towards the next level
  static double levelProgress(int xp) {
    int currentLevel = calculateLevel(xp);
    int currentLevelXP = xpForLevel(currentLevel);
    int nextLevelXP = xpForLevel(currentLevel + 1);
    
    return ((xp - currentLevelXP) / (nextLevelXP - currentLevelXP)).clamp(0.0, 1.0);
  }

  /// Streak calculation logic
  static int calculateNewStreak(DateTime? lastDate, DateTime currentDate, int currentStreak) {
    if (lastDate == null) return 1;
    
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final now = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final difference = now.difference(last).inDays;
    
    if (difference == 0) return currentStreak; // Already did setoran today
    if (difference == 1) return currentStreak + 1; // Consecutive day
    return 1; // Streak broken
  }

  /// Returns Level Label/Title
  static String getLevelTitle(int level) {
    if (level >= 50) return 'Hafidz Al-Quran';
    if (level >= 40) return 'Mufassir Muda';
    if (level >= 30) return 'Qari\' Senior';
    if (level >= 20) return 'Qari\'';
    if (level >= 10) return 'Tholibul Ilmi Senior';
    if (level >= 5) return 'Tholibul Ilmi';
    return 'Mubtadi\'';
  }
}

