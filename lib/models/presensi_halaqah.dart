import 'package:cloud_firestore/cloud_firestore.dart';

class PresensiHalaqah {
  final String id; // Format: halaqahId_yyyyMMdd
  final String halaqahId;
  final String halaqahNama;
  final String musyrifId;
  final String musyrifNama;
  final DateTime tanggal;
  final DateTime waktuSubmit;
  final Map<String, String> daftarHadir; // studentId -> status ('setoran' | 'ditunda' | 'sakit' | 'izin' | 'alfa')

  const PresensiHalaqah({
    required this.id,
    required this.halaqahId,
    required this.halaqahNama,
    required this.musyrifId,
    required this.musyrifNama,
    required this.tanggal,
    required this.waktuSubmit,
    required this.daftarHadir,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'halaqahId': halaqahId,
        'halaqahNama': halaqahNama,
        'musyrifId': musyrifId,
        'musyrifNama': musyrifNama,
        'tanggal': Timestamp.fromDate(tanggal),
        'waktuSubmit': Timestamp.fromDate(waktuSubmit),
        'daftarHadir': daftarHadir,
      };

  factory PresensiHalaqah.fromJson(Map<String, dynamic> json) {
    return PresensiHalaqah(
      id: json['id'] as String,
      halaqahId: json['halaqahId'] as String,
      halaqahNama: json['halaqahNama'] as String,
      musyrifId: json['musyrifId'] as String,
      musyrifNama: json['musyrifNama'] as String,
      tanggal: (json['tanggal'] as Timestamp).toDate(),
      waktuSubmit: (json['waktuSubmit'] as Timestamp).toDate(),
      daftarHadir: Map<String, String>.from(json['daftarHadir'] ?? {}),
    );
  }

  PresensiHalaqah copyWith({
    String? halaqahNama,
    String? musyrifNama,
    DateTime? waktuSubmit,
    Map<String, String>? daftarHadir,
  }) {
    return PresensiHalaqah(
      id: id,
      halaqahId: halaqahId,
      halaqahNama: halaqahNama ?? this.halaqahNama,
      musyrifId: musyrifId,
      musyrifNama: musyrifNama ?? this.musyrifNama,
      tanggal: tanggal,
      waktuSubmit: waktuSubmit ?? this.waktuSubmit,
      daftarHadir: daftarHadir ?? this.daftarHadir,
    );
  }
}
