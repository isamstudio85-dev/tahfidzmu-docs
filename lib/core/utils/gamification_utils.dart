import '../../models/setoran.dart';

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
    
    return ((baseXP + gradeBonus) * multiplier).round();
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

extension LevelCalculation on double {
  int get asLevel {
    // Simple square root based level
    // xp = 100 -> lvl 1
    // xp = 400 -> lvl 2
    // xp = 900 -> lvl 3
    // Using a more generous linear-quadratic hybrid
    // Let's use: xp = 50 * L * (L + 1)
    // L=1 -> 100 XP
    // L=2 -> 300 XP
    // L=3 -> 600 XP
    // L=10 -> 5500 XP
    
    // Let's stick to the simplest one for now
    // XP = level * 200
    // L=1 -> 200
    // L=2 -> 400
    // L=3 -> 600
    return (this / 2).floor().clamp(1, 99);
  }
}
