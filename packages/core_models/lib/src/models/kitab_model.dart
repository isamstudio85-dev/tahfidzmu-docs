import 'package:cloud_firestore/cloud_firestore.dart';

class Kitab {
  final String id;
  final String nama;
  final String deskripsi;
  final String tipeUnit; // 'bait' | 'hadits' | 'halaman' | 'nomor'
  final int totalUnit;
  final DateTime createdAt;

  const Kitab({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.tipeUnit,
    required this.totalUnit,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'deskripsi': deskripsi,
    'tipeUnit': tipeUnit,
    'totalUnit': totalUnit,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Kitab.fromJson(Map<String, dynamic> json) => Kitab(
    id: json['id'] as String,
    nama: json['nama'] as String,
    deskripsi: json['deskripsi'] as String? ?? '',
    tipeUnit: json['tipeUnit'] as String? ?? 'nomor',
    totalUnit: json['totalUnit'] as int? ?? 0,
    createdAt: _parseDate(json['createdAt']),
  );
}

class KitabSetoranRecord {
  final String id;
  final String santriId;
  final String kitabId;
  final String namaKitab;
  final String tipeUnit;
  final int startUnit;
  final int endUnit;
  final String type; // 'ziyadah' | 'murojaah'
  final double score;
  final String notes;
  final DateTime date;
  final String musyrifId;

  const KitabSetoranRecord({
    required this.id,
    required this.santriId,
    required this.kitabId,
    required this.namaKitab,
    required this.tipeUnit,
    required this.startUnit,
    required this.endUnit,
    required this.type,
    required this.score,
    this.notes = '',
    required this.date,
    required this.musyrifId,
  });

  String get rangeLabel {
    final String unitLabel = tipeUnit == 'bait'
        ? 'Bait'
        : tipeUnit == 'hadits'
            ? 'Hadits'
            : tipeUnit == 'halaman'
                ? 'Hal.'
                : 'No.';
    return '$unitLabel $startUnit–$endUnit';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'santriId': santriId,
    'kitabId': kitabId,
    'namaKitab': namaKitab,
    'tipeUnit': tipeUnit,
    'startUnit': startUnit,
    'endUnit': endUnit,
    'type': type,
    'score': score,
    'notes': notes,
    'date': date.toIso8601String(),
    'musyrifId': musyrifId,
  };

  factory KitabSetoranRecord.fromJson(Map<String, dynamic> json) => KitabSetoranRecord(
    id: json['id'] as String? ?? '',
    santriId: json['santriId'] as String? ?? '',
    kitabId: json['kitabId'] as String? ?? '',
    namaKitab: json['namaKitab'] as String? ?? '',
    tipeUnit: json['tipeUnit'] as String? ?? 'nomor',
    startUnit: json['startUnit'] as int? ?? 1,
    endUnit: json['endUnit'] as int? ?? (json['lastUnit'] as int? ?? 1),
    type: json['type'] as String? ?? 'ziyadah',
    score: (json['score'] as num? ?? 100.0).toDouble(),
    notes: json['notes'] as String? ?? '',
    date: _parseDate(json['date']),
    musyrifId: json['musyrifId'] as String? ?? '',
  );
}

DateTime _parseDate(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.parse(raw);
  return DateTime.now();
}
