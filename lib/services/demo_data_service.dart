import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/halaqah_data.dart';
import '../models/kelas_data.dart';
import '../models/musyrif_data.dart';
import '../models/santri.dart';

class DemoDataBundle {
  final List<MusyrifData> musyrifList;
  final List<HalaqahData> halaqahList;
  final List<KelasData> kelasList;
  final List<Santri> santriList;

  const DemoDataBundle({
    required this.musyrifList,
    required this.halaqahList,
    required this.kelasList,
    required this.santriList,
  });
}

class DemoDataService {
  static const String _assetDir = 'assets/data/demo';

  static Future<DemoDataBundle> loadDemoData() async {
    final musyrifRaw = await rootBundle.loadString('$_assetDir/musyrif.json');
    final halaqahRaw = await rootBundle.loadString('$_assetDir/halaqah.json');
    final kelasRaw = await rootBundle.loadString('$_assetDir/kelas.json');
    final santriRaw = await rootBundle.loadString('$_assetDir/santri.json');

    final musyrifList = (jsonDecode(musyrifRaw) as List)
        .map((e) => MusyrifData.fromJson(e as Map<String, dynamic>))
        .toList();
    final halaqahList = (jsonDecode(halaqahRaw) as List)
        .map((e) => HalaqahData.fromJson(e as Map<String, dynamic>))
        .toList();
    final kelasList = (jsonDecode(kelasRaw) as List)
        .map((e) => KelasData.fromJson(e as Map<String, dynamic>))
        .toList();
    final santriList = (jsonDecode(santriRaw) as List)
        .map((e) => Santri.fromJson(e as Map<String, dynamic>))
        .toList();

    return DemoDataBundle(
      musyrifList: musyrifList,
      halaqahList: halaqahList,
      kelasList: kelasList,
      santriList: santriList,
    );
  }
}
