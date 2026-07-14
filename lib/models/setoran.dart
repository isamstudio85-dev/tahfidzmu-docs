import 'error_mark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tahfidz_app/core/utils/quran_juz_utils.dart';

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
  final List<int> passedAyahs;
  final List<int> failedAyahs;
  final List<ErrorMark> errorMarks;
  final int fluencyRating; // 1–5
  final DateTime date;
  final double finalScore;
  final int? totalLines;
  final String calculationMethod;

  const SetoranRecord({
    required this.id,
    required this.santriId,
    required this.type,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.ayahStart,
    required this.ayahEnd,
    this.passedAyahs = const [],
    this.failedAyahs = const [],
    required this.errorMarks,
    required this.fluencyRating,
    required this.date,
    required this.finalScore,
    this.totalLines,
    this.calculationMethod = 'ayat',
  });

  int get tajwidErrorCount =>
      errorMarks.where((e) => e.errorType == ErrorType.tajwid).length;

  int get makhrojErrorCount =>
      errorMarks.where((e) => e.errorType == ErrorType.makhroj).length;

  int get totalErrors => errorMarks.length;

  String get ayahRange => 'Ayat $ayahStart–$ayahEnd';

  /// The first juz number this setoran starts in.
  int get juz => QuranJuzUtils.juzOf(surahNumber, ayahStart);

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
    'passedAyahs': passedAyahs,
    'failedAyahs': failedAyahs,
    'errorMarks': errorMarks.map((e) => e.toJson()).toList(),
    'fluencyRating': fluencyRating,
    'date': date.toIso8601String(),
    'finalScore': finalScore,
    'totalLines': totalLines,
    'calculationMethod': calculationMethod,
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
    passedAyahs: List<int>.from(json['passedAyahs'] ?? []),
    failedAyahs: List<int>.from(json['failedAyahs'] ?? []),
    errorMarks: (json['errorMarks'] as List)
        .map((e) => ErrorMark.fromJson(e as Map<String, dynamic>))
        .toList(),
    fluencyRating: json['fluencyRating'] as int,
    date: _parseDate(json['date']),
    finalScore: (json['finalScore'] as num).toDouble(),
    totalLines: json['totalLines'] as int?,
    calculationMethod: json['calculationMethod'] as String? ?? 'ayat',
  );
}

/// Mendukung dua format: String ISO-8601 dan Firestore Timestamp
DateTime _parseDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.parse(raw);
  return DateTime.now();
}
