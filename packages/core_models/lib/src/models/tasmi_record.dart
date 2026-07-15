import 'package:cloud_firestore/cloud_firestore.dart';
import 'error_mark.dart';

class TasmiRecord {
  final String id;
  final String santriId;
  final List<int> juzNumbers; // Juz yang diuji (bisa multiple, misal 29 & 30)
  final double finalScore;
  final int fluencyRating; // 1-5
  final List<ErrorMark> errorMarks;
  final DateTime date;
  final String status; // 'lulus' / 'tidak_lulus'
  final String year; // Tahun wisuda, misal '2024'
  final String? note;

  const TasmiRecord({
    required this.id,
    required this.santriId,
    required this.juzNumbers,
    required this.finalScore,
    required this.fluencyRating,
    required this.errorMarks,
    required this.date,
    this.status = 'lulus',
    required this.year,
    this.note,
  });

  bool get isPass => status == 'lulus';

  Map<String, dynamic> toJson() => {
        'id': id,
        'santriId': santriId,
        'juzNumbers': juzNumbers,
        'finalScore': finalScore,
        'fluencyRating': fluencyRating,
        'errorMarks': errorMarks.map((e) => e.toJson()).toList(),
        'date': date.toIso8601String(),
        'status': status,
        'year': year,
        'note': note,
      };

  factory TasmiRecord.fromJson(Map<String, dynamic> json) => TasmiRecord(
        id: json['id'] as String,
        santriId: json['santriId'] as String,
        juzNumbers: (json['juzNumbers'] as List).map((e) => e as int).toList(),
        finalScore: (json['finalScore'] as num).toDouble(),
        fluencyRating: json['fluencyRating'] as int,
        errorMarks: (json['errorMarks'] as List)
            .map((e) => ErrorMark.fromJson(e as Map<String, dynamic>))
            .toList(),
        date: _parseTasmiDate(json['date']),
        status: json['status'] as String,
        year: json['year'] as String,
        note: json['note'] as String?,
      );

  TasmiRecord copyWith({
    String? status,
    String? note,
    double? finalScore,
    int? fluencyRating,
  }) {
    return TasmiRecord(
      id: id,
      santriId: santriId,
      juzNumbers: juzNumbers,
      finalScore: finalScore ?? this.finalScore,
      fluencyRating: fluencyRating ?? this.fluencyRating,
      errorMarks: errorMarks,
      date: date,
      status: status ?? this.status,
      year: year,
      note: note ?? this.note,
    );
  }
}

DateTime _parseTasmiDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.parse(raw);
  return DateTime.now();
}
