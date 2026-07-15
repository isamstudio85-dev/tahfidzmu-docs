import 'setoran.dart';
import 'tasmi_record.dart';
import '../utils/quran_juz_utils.dart';

class Santri {
  final String id;
  final String name;
  final String? nis; // Nomor Induk Santri (login key)
  final String? email;
  final String? jenisKelamin; // 'L' / 'P'
  final String? kelas;
  final String? halaqahId;
  final String? namaOrangTua;
  final String? namaAyah;
  final String? namaIbu;
  final String? nomorHpWali; // No. HP wali (was: nomorOrtu)
  final String? targetHafalan;
  final String? photoPath;
  final String status; // 'aktif' / 'nonaktif'
  final List<SetoranRecord> setoranHistory;
  final List<TasmiRecord> tasmiHistory;
  final String? tanggalLahir;
  
  /// Juz numbers that the student already memorized before using the app.
  final List<int> initialMemorizedJuz;

  // Cached aggregate stats for scalability (Firestore subcollection caching)
  final double? averageScoreField;
  final int? totalSetoranCountField;
  final int? totalErrorsField;
  final int? totalZiyadahAyahsField;
  final int? totalMurojaahAyahsField;
  final int? totalFailedAyahsField;
  final double? estimatedJuzField;
  final List<int>? juzCoveredByZiyadahField;
  final String? lastSetoranAtField;

  // Gamification fields
  final int totalXP;
  final int streakDays;
  final List<String> unlockedBadges;
  
  // Virtual Reward fields
  final int totalCoins;
  final List<String> unlockedItems; // IDs of purchased frames/titles
  final String? activeFrame;      // ID of current profile frame
  final String? activeTitle;      // Custom title shown on leaderboard
  final String? activeTheme;      // ID of current profile card background theme

  // Backward-compat getters so old references still compile
  String? get nik => nis;
  String? get namaOrtu => namaOrangTua ?? namaAyah ?? namaIbu;
  String? get nomorOrtu => nomorHpWali;

  const Santri({
    required this.id,
    required this.name,
    this.nis,
    this.email,
    this.jenisKelamin,
    this.kelas,
    this.halaqahId,
    this.namaOrangTua,
    this.namaAyah,
    this.namaIbu,
    this.nomorHpWali,
    this.targetHafalan,
    this.photoPath,
    this.tanggalLahir,
    this.status = 'aktif',
    this.setoranHistory = const [],
    this.tasmiHistory = const [],
    this.initialMemorizedJuz = const [],
    this.averageScoreField,
    this.totalSetoranCountField,
    this.totalErrorsField,
    this.totalZiyadahAyahsField,
    this.totalMurojaahAyahsField,
    this.totalFailedAyahsField,
    this.estimatedJuzField,
    this.juzCoveredByZiyadahField,
    this.lastSetoranAtField,
    this.totalXP = 0,
    this.streakDays = 0,
    this.unlockedBadges = const [],
    this.totalCoins = 0,
    this.unlockedItems = const [],
    this.activeFrame,
    this.activeTitle,
    this.activeTheme,
  });

  bool get isAktif => status == 'aktif';

  Santri copyWith({
    String? name,
    String? nis,
    String? email,
    String? jenisKelamin,
    String? kelas,
    String? halaqahId,
    String? namaOrangTua,
    String? namaAyah,
    String? namaIbu,
    String? nomorHpWali,
    String? targetHafalan,
    String? photoPath,
    String? tanggalLahir,
    String? status,
    List<SetoranRecord>? setoranHistory,
    List<TasmiRecord>? tasmiHistory,
    List<int>? initialMemorizedJuz,
    double? averageScoreField,
    int? totalSetoranCountField,
    int? totalErrorsField,
    int? totalZiyadahAyahsField,
    int? totalMurojaahAyahsField,
    int? totalFailedAyahsField,
    double? estimatedJuzField,
    List<int>? juzCoveredByZiyadahField,
    String? lastSetoranAtField,
    int? totalXP,
    int? streakDays,
    List<String>? unlockedBadges,
    int? totalCoins,
    List<String>? unlockedItems,
    String? activeFrame,
    String? activeTitle,
    String? activeTheme,
    // old-name aliases
    String? nik,
    String? namaOrtu,
    String? nomorOrtu,
  }) {
    return Santri(
      id: id,
      name: name ?? this.name,
      nis: nis ?? nik ?? this.nis,
      email: email ?? this.email,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      kelas: kelas ?? this.kelas,
      halaqahId: halaqahId ?? this.halaqahId,
      namaOrangTua: namaOrangTua ?? namaOrtu ?? this.namaOrangTua,
      namaAyah: namaAyah ?? this.namaAyah,
      namaIbu: namaIbu ?? this.namaIbu,
      nomorHpWali: nomorHpWali ?? nomorOrtu ?? this.nomorHpWali,
      targetHafalan: targetHafalan ?? this.targetHafalan,
      photoPath: photoPath ?? this.photoPath,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      status: status ?? this.status,
      setoranHistory: setoranHistory ?? this.setoranHistory,
      tasmiHistory: tasmiHistory ?? this.tasmiHistory,
      initialMemorizedJuz: initialMemorizedJuz ?? this.initialMemorizedJuz,
      averageScoreField: averageScoreField ?? this.averageScoreField,
      totalSetoranCountField: totalSetoranCountField ?? this.totalSetoranCountField,
      totalErrorsField: totalErrorsField ?? this.totalErrorsField,
      totalZiyadahAyahsField: totalZiyadahAyahsField ?? this.totalZiyadahAyahsField,
      totalMurojaahAyahsField: totalMurojaahAyahsField ?? this.totalMurojaahAyahsField,
      totalFailedAyahsField: totalFailedAyahsField ?? this.totalFailedAyahsField,
      estimatedJuzField: estimatedJuzField ?? this.estimatedJuzField,
      juzCoveredByZiyadahField: juzCoveredByZiyadahField ?? this.juzCoveredByZiyadahField,
      lastSetoranAtField: lastSetoranAtField ?? this.lastSetoranAtField,
      totalXP: totalXP ?? this.totalXP,
      streakDays: streakDays ?? this.streakDays,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      totalCoins: totalCoins ?? this.totalCoins,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      activeFrame: activeFrame ?? this.activeFrame,
      activeTitle: activeTitle ?? this.activeTitle,
      activeTheme: activeTheme ?? this.activeTheme,
    );
  }

  double get averageScore {
    if (averageScoreField != null) return averageScoreField!;
    if (setoranHistory.isEmpty) return 0;
    final total = setoranHistory.fold<double>(
      0.0,
      (sum, s) => sum + s.finalScore,
    );
    return total / setoranHistory.length;
  }

  double get totalAccumulatedScore {
    if (averageScoreField != null && totalSetoranCountField != null) {
      return averageScoreField! * totalSetoranCountField!;
    }
    return setoranHistory.fold<double>(0.0, (sum, s) => sum + s.finalScore);
  }

  int get overallStarCount {
    final avg = averageScore;
    if (avg >= 90) return 5;
    if (avg >= 80) return 4;
    if (avg >= 65) return 3;
    if (avg >= 50) return 2;
    if (avg > 0) return 1;
    return 0;
  }

  int get totalSetoranCount => totalSetoranCountField ?? setoranHistory.length;

  int get totalErrors => totalErrorsField ?? setoranHistory.fold<int>(0, (sum, s) => sum + s.totalErrors);

  DateTime? get lastSetoranAt {
    if (lastSetoranAtField != null) return DateTime.tryParse(lastSetoranAtField!);
    if (setoranHistory.isEmpty) return null;
    return setoranHistory.first.date;
  }

  // ── Hafalan accumulation ──────────────────────────────────────────────────

  /// Total ayahs covered in ziyadah (new memorisation) sessions.
  int get totalZiyadahAyahs => totalZiyadahAyahsField ?? setoranHistory
      .where((s) => s.type == SetoranType.ziyadah)
      .fold(0, (sum, s) => sum + s.passedAyahs.length);

  /// Total ayahs covered in muroja'ah (review) sessions.
  int get totalMurojaahAyahs => totalMurojaahAyahsField ?? setoranHistory
      .where((s) => s.type == SetoranType.murojaah)
      .fold(0, (sum, s) => sum + s.passedAyahs.length);

  /// Total failed ayahs (needs attention).
  int get totalFailedAyahs => totalFailedAyahsField ?? setoranHistory
      .fold(0, (sum, s) => sum + s.failedAyahs.length);

  /// Number of ziyadah sessions.
  int get totalZiyadahSessions =>
      setoranHistory.where((s) => s.type == SetoranType.ziyadah).length;

  /// Number of muroja'ah sessions.
  int get totalMurojaahSessions =>
      setoranHistory.where((s) => s.type == SetoranType.murojaah).length;

  /// Estimated juz memorised (Initial + Ziyadah).
  /// (1 juz ≈ 604 ayahs).
  double get estimatedJuz => estimatedJuzField ?? (initialMemorizedJuz.length + (totalZiyadahAyahs / 604.0));

  /// Sorted list of distinct juz numbers touched by initial state OR ziyadah sessions.
  List<int> get juzCoveredByZiyadah {
    if (juzCoveredByZiyadahField != null) return juzCoveredByZiyadahField!;
    final result = <int>{...initialMemorizedJuz};
    for (final s in setoranHistory.where(
      (r) => r.type == SetoranType.ziyadah,
    )) {
      final jStart = QuranJuzUtils.juzOf(s.surahNumber, s.ayahStart);
      final jEnd = QuranJuzUtils.juzOf(s.surahNumber, s.ayahEnd);
      for (int j = jStart; j <= jEnd; j++) {
        result.add(j);
      }
    }
    return result.toList()..sort();
  }

  /// Human-readable label, e.g. "Juz 1–3, 5".
  String get juzCoveredText =>
      QuranJuzUtils.juzCoveredText(juzCoveredByZiyadah);

  /// Composite ranking score.
  /// Initial Juz carry massive weight (as they are already completed).
  /// Ziyadah (new memorisation) carries 3× weight over muroja'ah (review),
  /// plus average score as a tie-breaker bonus.
  double get rankScore =>
      (initialMemorizedJuz.length * 604 * 3.0) +
      (totalZiyadahAyahs * 3.0) + (totalMurojaahAyahs * 1.0) + averageScore;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nis': nis,
    'email': email,
    'jenisKelamin': jenisKelamin,
    'kelas': kelas,
    'halaqahId': halaqahId,
    'namaOrangTua': namaOrangTua,
    'namaAyah': namaAyah,
    'namaIbu': namaIbu,
    'nomorHpWali': nomorHpWali,
    'targetHafalan': targetHafalan,
    'photoPath': photoPath,
    'tanggalLahir': tanggalLahir,
    'status': status,
    'initialMemorizedJuz': initialMemorizedJuz,
    // Add cached aggregate stats to json
    'averageScore': averageScore,
    'totalSetoranCount': totalSetoranCount,
    'totalErrors': totalErrors,
    'totalZiyadahAyahs': totalZiyadahAyahs,
    'totalMurojaahAyahs': totalMurojaahAyahs,
    'totalFailedAyahs': totalFailedAyahs,
    'estimatedJuz': estimatedJuz,
    'juzCoveredByZiyadah': juzCoveredByZiyadah,
    'lastSetoranAt': lastSetoranAtField,
    'totalXP': totalXP,
    'streakDays': streakDays,
    'unlockedBadges': unlockedBadges,
    'totalCoins': totalCoins,
    'unlockedItems': unlockedItems,
    'activeFrame': activeFrame,
    'activeTitle': activeTitle,
    'activeTheme': activeTheme,
  };

  factory Santri.fromJson(Map<String, dynamic> json) => Santri(
    id: json['id'] as String,
    name: json['name'] as String,
    nis: (json['nis'] ?? json['nik']) as String?,
    email: json['email'] as String?,
    jenisKelamin: json['jenisKelamin'] as String?,
    kelas: json['kelas'] as String?,
    halaqahId: json['halaqahId'] as String?,
    namaOrangTua: (json['namaOrangTua'] ?? json['namaOrtu']) as String?,
    namaAyah: json['namaAyah'] as String?,
    namaIbu: json['namaIbu'] as String?,
    nomorHpWali: (json['nomorHpWali'] ?? json['nomorOrtu']) as String?,
    targetHafalan: json['targetHafalan'] as String?,
    photoPath: json['photoPath'] as String?,
    tanggalLahir: json['tanggalLahir'] as String?,
    status: (json['status'] as String?) ?? 'aktif',
    setoranHistory:
        (json['setoranHistory'] as List?)
            ?.map((s) => SetoranRecord.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    tasmiHistory:
        (json['tasmiHistory'] as List?)
            ?.map((t) => TasmiRecord.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [],
    initialMemorizedJuz: (json['initialMemorizedJuz'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        [],
    averageScoreField: (json['averageScore'] as num?)?.toDouble(),
    totalSetoranCountField: json['totalSetoranCount'] as int?,
    totalErrorsField: json['totalErrors'] as int?,
    totalZiyadahAyahsField: json['totalZiyadahAyahs'] as int?,
    totalMurojaahAyahsField: json['totalMurojaahAyahs'] as int?,
    totalFailedAyahsField: json['totalFailedAyahs'] as int?,
    estimatedJuzField: (json['estimatedJuz'] as num?)?.toDouble(),
    juzCoveredByZiyadahField: (json['juzCoveredByZiyadah'] as List?)
            ?.map((e) => e as int)
            .toList(),
    lastSetoranAtField: json['lastSetoranAt'] as String?,
    totalXP: json['totalXP'] as int? ?? 0,
    streakDays: json['streakDays'] as int? ?? 0,
    unlockedBadges: (json['unlockedBadges'] as List?)?.map((e) => e as String).toList() ?? [],
    totalCoins: json['totalCoins'] as int? ?? 0,
    unlockedItems: (json['unlockedItems'] as List?)?.map((e) => e as String).toList() ?? [],
    activeFrame: json['activeFrame'] as String?,
    activeTitle: json['activeTitle'] as String?,
    activeTheme: json['activeTheme'] as String?,
  );
}
