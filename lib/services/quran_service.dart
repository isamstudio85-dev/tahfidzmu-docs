import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/surah_model.dart';

/// Loads Quran data exclusively from bundled local assets (assets/data/quran/).
class QuranService {
  static const String _assetDir = 'assets/data/quran';

  static final Map<int, SurahDetail> _surahCache = {};
  static List<SurahInfo>? _listCache;

  // Surah list
  static Future<List<SurahInfo>> getSurahList() async {
    if (_listCache != null) return _listCache!;
    try {
      final raw = await rootBundle.loadString('$_assetDir/surah_list.json');
      _listCache = await compute(_parseSurahList, raw);
      return _listCache!;
    } catch (e) {
      debugPrint("Error loading surah list: $e");
      return [];
    }
  }

  static List<SurahInfo> _parseSurahList(String raw) {
    final data = jsonDecode(raw) as List;
    return data.map((s) => SurahInfo.fromJson(s as Map<String, dynamic>)).toList();
  }

  // Single surah
  static Future<SurahDetail> getSurah(int number) async {
    if (_surahCache.containsKey(number)) return _surahCache[number]!;
    
    try {
      final padded = number.toString().padLeft(3, '0');
      final raw = await rootBundle.loadString('$_assetDir/surah_$padded.json');
      final surah = await compute(_parseSurahDetail, raw);
      _surahCache[number] = surah;
      return surah;
    } catch (e) {
      debugPrint("Error loading surah $number: $e");
      rethrow;
    }
  }

  static SurahDetail _parseSurahDetail(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return SurahDetail.fromJson(json);
  }

  static void clearCache() {
    _surahCache.clear();
    _listCache = null;
  }
}
