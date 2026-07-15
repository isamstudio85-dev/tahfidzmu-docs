import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:core_models/core_models.dart';

/// Loads Quran data exclusively from bundled local assets (assets/data/quran/).
class QuranService {
  static const String _assetDir = 'assets/data/quran';

  static final Map<int, SurahDetail> _surahCache = {};
  static List<SurahInfo>? _listCache;
  static Map<String, List<dynamic>>? _lineMapping;

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

  static Future<Map<String, List<dynamic>>> _getLineMapping() async {
    if (_lineMapping != null) return _lineMapping!;
    try {
      final raw = await rootBundle.loadString('$_assetDir/quran_line_mapping.json');
      _lineMapping = Map<String, List<dynamic>>.from(jsonDecode(raw) as Map);
      return _lineMapping!;
    } catch (e) {
      debugPrint("Error loading quran line mapping: $e");
      return {};
    }
  }

  // Single surah
  static Future<SurahDetail> getSurah(int number) async {
    if (_surahCache.containsKey(number)) return _surahCache[number]!;
    
    try {
      final padded = number.toString().padLeft(3, '0');
      final raw = await rootBundle.loadString('$_assetDir/surah_$padded.json');
      final surah = await compute(_parseSurahDetail, raw);
      
      final mapping = await _getLineMapping();
      final updatedAyahs = surah.ayahs.map((ayah) {
        final key = '${surah.number}:${ayah.numberInSurah}';
        final mapData = mapping[key];
        if (mapData != null && mapData.length == 3) {
          return ayah.copyWith(
            pageNumber: mapData[0] as int,
            startLine: mapData[1] as int,
            endLine: mapData[2] as int,
          );
        }
        return ayah;
      }).toList();

      final updatedSurah = SurahDetail(
        number: surah.number,
        name: surah.name,
        englishName: surah.englishName,
        ayahs: updatedAyahs,
      );

      _surahCache[number] = updatedSurah;
      return updatedSurah;
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
    _lineMapping = null;
  }
}
