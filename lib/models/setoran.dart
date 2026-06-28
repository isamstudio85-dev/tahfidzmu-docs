import 'error_mark.dart';
import '../utils/quran_juz_utils.dart';

enum SetoranType {
  ziyadah,
  murojaah;

  String get label {
    switch (this) {
      case SetoranType.ziyadah:
        return 'Ziyadah';
      case SetoranType.murojaah:
        return "Muroja'ah";
    }
  }
}

class SetoranRecord {
  final String id;
  final String santriId;
  final SetoranType type;
  final int surahNumber;
  final String surahName;
  final String surahEnglishName;
  final int ayahStart;
  final int ayahEnd;
  final List<ErrorMark> errorMarks;
  final int fluencyRating; // 1–5
  final DateTime date;
  final double finalScore;

  const SetoranRecord({
    required this.id,
    required this.santriId,
    required this.type,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.ayahStart,
    required this.ayahEnd,
    required this.errorMarks,
    required this.fluencyRating,
    required this.date,
    required this.finalScore,
  });

  int get tajwidErrorCount =>
      errorMarks.where((e) => e.errorType == ErrorType.tajwid).length;

  int get makhrojErrorCount =>
      errorMarks.where((e) => e.errorType == ErrorType.makhroj).length;

  int get totalErrors => errorMarks.length;

  String get ayahRange => 'Ayat $ayahStart–$ayahEnd';

  /// Juz range this setoran covers, e.g. "Juz 2" or "Juz 2–3".
  String get juzLabel =>
      QuranJuzUtils.juzLabel(surahNumber, ayahStart, ayahEnd);

  int get starCount {
    if (finalScore >= 90) return 5;
    if (finalScore >= 80) return 4;
    if (finalScore >= 65) return 3;
    if (finalScore >= 50) return 2;
    if (finalScore > 0) return 1;
    return 0;
  }

  String get gradeName {
    if (finalScore >= 90) return 'Mumtaz';
    if (finalScore >= 80) return 'Jayyid Jiddan';
    if (finalScore >= 65) return 'Jayyid';
    if (finalScore >= 50) return 'Maqbul';
    return 'Perlu Perbaikan';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'santriId': santriId,
    'type': type.name,
    'surahNumber': surahNumber,
    'surahName': surahName,
    'surahEnglishName': surahEnglishName,
    'ayahStart': ayahStart,
    'ayahEnd': ayahEnd,
    'errorMarks': errorMarks.map((e) => e.toJson()).toList(),
    'fluencyRating': fluencyRating,
    'date': date.toIso8601String(),
    'finalScore': finalScore,
  };

  factory SetoranRecord.fromJson(Map<String, dynamic> json) => SetoranRecord(
    id: json['id'] as String,
    santriId: json['santriId'] as String,
    type: SetoranType.values.byName(json['type'] as String),
    surahNumber: json['surahNumber'] as int,
    surahName: json['surahName'] as String,
    surahEnglishName: json['surahEnglishName'] as String,
    ayahStart: json['ayahStart'] as int,
    ayahEnd: json['ayahEnd'] as int,
    errorMarks: (json['errorMarks'] as List)
        .map((e) => ErrorMark.fromJson(e as Map<String, dynamic>))
        .toList(),
    fluencyRating: json['fluencyRating'] as int,
    date: DateTime.parse(json['date'] as String),
    finalScore: (json['finalScore'] as num).toDouble(),
  );
}
