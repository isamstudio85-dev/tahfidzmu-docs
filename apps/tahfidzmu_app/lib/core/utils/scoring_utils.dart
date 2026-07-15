import 'package:core_models/core_models.dart';

class ScoringUtils {
  /// Calculates final score based on errors and fluency.
  /// errorScore = max(0, 100 - tajwidErrors*3 - makhrojErrors*2)   → 60%
  /// fluencyScore = fluencyRating * 20                               → 40%
  static double calculateScore({
    required List<ErrorMark> errorMarks,
    required int fluencyRating,
  }) {
    final tajwidErrors = errorMarks
        .where((e) => e.errorType == ErrorType.tajwid)
        .length;
    final makhrojErrors = errorMarks
        .where((e) => e.errorType == ErrorType.makhroj)
        .length;

    final deduction = tajwidErrors * 3 + makhrojErrors * 2;
    final errorScore = (100 - deduction).clamp(0, 100).toDouble();

    final fluencyScore = (fluencyRating * 20).toDouble();

    final finalScore = (errorScore * 0.6) + (fluencyScore * 0.4);
    return finalScore.clamp(0.0, 100.0);
  }

  static int scoreToStars(double score) {
    if (score >= 90) return 5;
    if (score >= 80) return 4;
    if (score >= 65) return 3;
    if (score >= 50) return 2;
    if (score > 0) return 1;
    return 0;
  }

  static String scoreToGrade(double score) {
    if (score >= 90) return 'Mumtaz';
    if (score >= 80) return 'Jayyid Jiddan';
    if (score >= 65) return 'Jayyid';
    if (score >= 50) return 'Maqbul';
    return 'Perlu Perbaikan';
  }
}

/// Convert integer to Arabic-Indic numeral string
String toArabicNumeral(int number) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((c) => arabic[int.parse(c)]).join();
}
