import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/surah_model.dart';

/// Loads Quran data exclusively from bundled local assets (assets/data/quran/).
/// Run tools/download_quran.ps1 once to generate the asset files.
class QuranService {
  static const String _assetDir = 'assets/data/quran';

  static final Map<int, SurahDetail> _surahCache = {};
  static List<SurahInfo>? _listCache;

  // Surah list
  static Future<List<SurahInfo>> getSurahList() async {
    if (_listCache != null) return _listCache!;
    final raw = await rootBundle.loadString('$_assetDir/surah_list.json');
    final data = jsonDecode(raw) as List;
    _listCache = data
        .map((s) => SurahInfo.fromJson(s as Map<String, dynamic>))
        .toList();
    return _listCache!;
  }

  // Single surah
  static Future<SurahDetail> getSurah(int number) async {
    if (_surahCache.containsKey(number)) return _surahCache[number]!;
    final padded = number.toString().padLeft(3, '0');
    final raw = await rootBundle.loadString('$_assetDir/surah_$padded.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final surah = SurahDetail.fromLocalJson(json);
    _surahCache[number] = surah;
    return surah;
  }

  static void clearCache() {
    _surahCache.clear();
    _listCache = null;
  }
}
