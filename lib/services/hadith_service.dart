import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/hadith.dart';

class HadithService {
  static List<Hadith>? _cache;

  static Future<List<Hadith>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(
      'assets/data/hadits/hadits_list.json',
    );
    final list = jsonDecode(raw) as List;
    _cache = list
        .map((h) => Hadith.fromJson(h as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  static Future<List<Hadith>> getArbain() async {
    final all = await loadAll();
    return all.where((h) => h.isArbain).toList()
      ..sort((a, b) => (a.arbainNo ?? 0).compareTo(b.arbainNo ?? 0));
  }

  static Future<Map<String, List<Hadith>>> getByTema() async {
    final all = await loadAll();
    final map = <String, List<Hadith>>{};
    for (final tema in Hadith.allTemas) {
      final items = all.where((h) => h.tema == tema).toList();
      if (items.isNotEmpty) map[tema] = items;
    }
    return map;
  }
}
