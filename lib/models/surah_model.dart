class SurahInfo {
  final int number;
  final String name;
  final String englishName;
  final int numberOfAyahs;
  final String revelationType;

  const SurahInfo({
    required this.number,
    required this.name,
    required this.englishName,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) => SurahInfo(
    number: json['number'] as int,
    name: json['name'] as String,
    englishName: json['englishName'] as String,
    numberOfAyahs: json['numberOfAyahs'] as int,
    revelationType: json['revelationType'] as String,
  );

  @override
  String toString() => '$number. $englishName ($name)';
}

class AyahModel {
  final int number;
  final int numberInSurah;
  final String text; // Arabic text (Uthmani)
  final String? translation; // Indonesian translation (nullable)

  const AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.text,
    this.translation,
  });

  /// Splits the ayah into clickable word tokens.
  /// Waqf marks (stand-alone non-letter symbols, e.g. ۚ ۖ ۝ ۞) are appended
  /// to the preceding word so they display naturally as a single unit.
  List<String> get words {
    final tokens = text.split(' ').where((w) => w.trim().isNotEmpty).toList();
    final result = <String>[];
    for (final token in tokens) {
      if (_hasArabicBaseLetter(token)) {
        result.add(token);
      } else if (result.isNotEmpty) {
        // Waqf / decoration — append to previous word
        result[result.length - 1] = '${result.last}\u00a0$token';
      }
      // Leading decoration before any word is skipped
    }
    return result.isEmpty ? [text] : result;
  }

  static bool _hasArabicBaseLetter(String s) {
    for (final r in s.runes) {
      if ((r >= 0x0621 && r <= 0x063A) ||
          (r >= 0x0641 && r <= 0x064A) ||
          r == 0x0671) {
        return true;
      }
    }
    return false;
  }

  factory AyahModel.fromJson(Map<String, dynamic> json) => AyahModel(
    number: json['number'] as int,
    numberInSurah: json['numberInSurah'] as int,
    text: json['text'] as String,
  );

  /// Constructs from a local asset JSON where arabic & translation
  /// are stored as separate keys (not the AlQuran Cloud API format).
  factory AyahModel.fromLocalJson(Map<String, dynamic> json, int globalN) =>
      AyahModel(
        number: globalN,
        numberInSurah: json['numberInSurah'] as int,
        text: json['arabic'] as String,
        translation: json['translation'] as String?,
      );
}

class SurahDetail {
  final int number;
  final String name;
  final String englishName;
  final List<AyahModel> ayahs;

  const SurahDetail({
    required this.number,
    required this.name,
    required this.englishName,
    required this.ayahs,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) => SurahDetail(
    number: json['number'] as int,
    name: json['name'] as String,
    englishName: json['englishName'] as String,
    ayahs: (json['ayahs'] as List)
        .map((a) => AyahModel.fromJson(a as Map<String, dynamic>))
        .toList(),
  );

  /// Constructs from local asset format (surah_NNN.json).
  factory SurahDetail.fromLocalJson(Map<String, dynamic> json) {
    int n = 0;
    return SurahDetail(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      ayahs: (json['ayahs'] as List).map((a) {
        n++;
        return AyahModel.fromLocalJson(a as Map<String, dynamic>, n);
      }).toList(),
    );
  }
}
