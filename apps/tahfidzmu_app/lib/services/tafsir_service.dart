import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sumber tafsir yang tersedia.
enum TafsirSource {
  quraish,
  kemenag,
  jalalayn,
}

/// Menyediakan label tampilan untuk enum TafsirSource.
extension TafsirSourceExt on TafsirSource {
  String get label {
    switch (this) {
      case TafsirSource.quraish:
        return 'Quraish Shihab';
      case TafsirSource.kemenag:
        return 'Kemenag RI';
      case TafsirSource.jalalayn:
        return 'Al-Jalalain';
    }
  }

  String get assetPath {
    switch (this) {
      case TafsirSource.quraish:
        return 'assets/data/tafsir/tafsir_quraish.json';
      case TafsirSource.kemenag:
        return 'assets/data/tafsir/tafsir_kemenag.json';
      case TafsirSource.jalalayn:
        return 'assets/data/tafsir/tafsir_jalalayn.json';
    }
  }
}

/// Data tafsir untuk satu ayat.
class TafsirEntry {
  final String text;

  const TafsirEntry({required this.text});
}

/// Service untuk memuat tafsir dari local assets.
class TafsirService {
  // Cache per-source agar tidak reload file besar berulang kali.
  static final Map<TafsirSource, Map<String, TafsirEntry>> _cache = {};

  /// Memuat seluruh data tafsir untuk satu sumber.
  /// Hasilnya di-cache sehingga pemanggilan berikutnya instan.
  static Future<Map<String, TafsirEntry>> _loadSource(TafsirSource source) async {
    if (_cache.containsKey(source)) return _cache[source]!;

    final raw = await rootBundle.loadString(source.assetPath);
    final result = await compute(_parseInIsolate, _ParseArgs(raw, source));
    _cache[source] = result;
    return result;
  }

  /// Mendapatkan tafsir untuk ayat tertentu.
  /// Key: "surahNumber.ayahNumber", misalnya "1.1", "2.255".
  static Future<TafsirEntry?> getTafsir(
    TafsirSource source,
    int surahNumber,
    int ayahNumber,
  ) async {
    final data = await _loadSource(source);
    return data['$surahNumber.$ayahNumber'];
  }

  /// Mendapatkan semua tafsir untuk satu surah sekaligus.
  /// Mengembalikan Map dengan key ayahNumber dan value TafsirEntry.
  static Future<Map<int, TafsirEntry>> getTafsirForSurah(
    TafsirSource source,
    int surahNumber,
  ) async {
    final data = await _loadSource(source);
    final result = <int, TafsirEntry>{};

    for (final entry in data.entries) {
      final parts = entry.key.split('.');
      if (parts.length == 2 && int.tryParse(parts[0]) == surahNumber) {
        final ayahNum = int.tryParse(parts[1]);
        if (ayahNum != null) {
          result[ayahNum] = entry.value;
        }
      }
    }
    return result;
  }

  static void clearCache() {
    _cache.clear();
  }
}

// ── Isolate parsing ────────────────────────────────────────────────────────────

class _ParseArgs {
  final String raw;
  final TafsirSource source;
  const _ParseArgs(this.raw, this.source);
}

/// Dijalankan di isolate terpisah via compute() agar UI tidak lag
/// (terutama untuk Kemenag ~14 MB).
Map<String, TafsirEntry> _parseInIsolate(_ParseArgs args) {
  if (args.source == TafsirSource.kemenag) {
    return _parseKemenag(args.raw);
  }
  return _parseSimple(args.raw);
}

/// Parser untuk Quraish Shihab & Al-Jalalain.
/// Format: { "1.1": "teks tafsir...", "1.2": "...", ... }
Map<String, TafsirEntry> _parseSimple(String raw) {
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return json.map((key, value) => MapEntry(
    key,
    TafsirEntry(text: (value as String).trim()),
  ));
}

/// Parser untuk Kemenag.
/// Format: [ { "short": { "aya_name": "1:1", "text": "<p>..." } }, ... ]
Map<String, TafsirEntry> _parseKemenag(String raw) {
  final list = jsonDecode(raw) as List;
  final result = <String, TafsirEntry>{};

  for (final item in list) {
    final map = item as Map<String, dynamic>;
    final shortObj = map['short'] as Map<String, dynamic>?;

    if (shortObj == null) continue;

    // Key bisa dari "aya_name" (format "1:1") atau dari posisi index
    final ayaName = shortObj['aya_name'] as String?;
    if (ayaName == null) continue;

    // Ubah "1:1" → "1.1"
    final key = ayaName.replaceAll(':', '.');

    final shortText = _stripHtml(shortObj['text'] as String? ?? '');

    result[key] = TafsirEntry(
      text: shortText,
    );
  }
  return result;
}

/// Menghapus HTML tags dari teks tafsir Kemenag.
String _stripHtml(String html) {
  // Hapus semua HTML tags
  return html
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
