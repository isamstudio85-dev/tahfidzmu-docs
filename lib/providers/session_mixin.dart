import 'package:flutter/foundation.dart';
import '../models/santri.dart';
import '../models/setoran.dart';
import '../models/surah_model.dart';
import '../models/error_mark.dart';
import 'package:tahfidz_app/core/utils/quran_juz_utils.dart';

mixin SessionMixin on ChangeNotifier {
  List<SurahInfo> _surahList = [];
  List<SurahInfo> get surahList => List.unmodifiable(_surahList);
  set surahList(List<SurahInfo> list) {
    _surahList = list;
    notifyListeners();
  }

  Santri? activeSetoranSantri;
  SetoranType activeSetoranType = SetoranType.ziyadah;
  int activeSetoranSurahNumber = 1;
  String activeSetoranSurahName = '';
  String activeSetoranSurahEnglishName = '';
  int activeSetoranAyahStart = 1;
  int activeSetoranAyahEnd = 7;
  int defaultSetoranAyahEnd = 7; // Store initial session end to allow toggle-back
  String activeSetoranCalculationMethod = 'ayat';
  bool isTasmiSession = false;
  List<int> activeTasmiJuz = [];
  String activeTasmiYear = '';
  bool isFlagChanged = false;
  
  final Map<String, ErrorMark> sessionErrors = {};
  final Set<int> sessionPassedAyahs = {};
  final Set<int> sessionFailedAyahs = {};

  int get sessionTajwidCount => sessionErrors.values.where((e) => e.errorType == ErrorType.tajwid).length;
  int get sessionMakhrojCount => sessionErrors.values.where((e) => e.errorType == ErrorType.makhroj).length;

  void startSetoranSession({
    required Santri santri,
    required SetoranType type,
    required SurahInfo surah,
    required int ayahStart,
    required int ayahEnd,
    String calculationMethod = 'ayat',
  }) {
    activeSetoranSantri = santri;
    activeSetoranType = type;
    activeSetoranSurahNumber = surah.number;
    activeSetoranSurahName = surah.name;
    activeSetoranSurahEnglishName = surah.englishName;
    activeSetoranAyahStart = ayahStart;
    activeSetoranCalculationMethod = calculationMethod;
    
    // Clamp ayahEnd to surah length
    final maxAyah = surah.numberOfAyahs;
    final clampedAyahEnd = ayahEnd.clamp(ayahStart, maxAyah);
    activeSetoranAyahEnd = clampedAyahEnd;
    defaultSetoranAyahEnd = clampedAyahEnd;
    
    isTasmiSession = false;
    isFlagChanged = false;
    sessionErrors.clear();
    sessionPassedAyahs.clear();
    sessionFailedAyahs.clear();
    
    notifyListeners();
  }

  void startTasmiSession({required Santri santri, required List<int> juzNumbers, required String year}) {
    activeSetoranSantri = santri;
    activeSetoranType = SetoranType.ziyadah;
    isTasmiSession = true;
    activeTasmiJuz = juzNumbers;
    activeTasmiYear = year;
    
    final firstJuz = juzNumbers.isEmpty ? 1 : juzNumbers.reduce((a, b) => a < b ? a : b);
    final juzRange = QuranJuzUtils.getJuzRange(firstJuz);
    activeSetoranSurahNumber = juzRange.startSurah;
    activeSetoranAyahStart = juzRange.startAyah;
    
    final surah = _surahList.firstWhere((s) => s.number == activeSetoranSurahNumber, orElse: () => _surahList.first);
    activeSetoranSurahName = surah.name;
    activeSetoranSurahEnglishName = surah.englishName;
    
    // Clamp ayahEnd to surah length
    final clampedAyahEnd = (juzRange.startAyah + 20).clamp(activeSetoranAyahStart, surah.numberOfAyahs);
    activeSetoranAyahEnd = clampedAyahEnd;
    defaultSetoranAyahEnd = clampedAyahEnd;
    
    isFlagChanged = false;
    sessionErrors.clear();
    sessionPassedAyahs.clear();
    sessionFailedAyahs.clear();

    notifyListeners();
  }

  void setSessionEndAyah(int ayahNumber) {
    if (ayahNumber < activeSetoranAyahStart) return;
    
    if (activeSetoranAyahEnd == ayahNumber) {
      // Tap-back cancels the custom end-session marker and restores default
      activeSetoranAyahEnd = defaultSetoranAyahEnd;
    } else {
      activeSetoranAyahEnd = ayahNumber;
    }
    
    isFlagChanged = true;
    
    // Hapus status lulus/gagal untuk semua ayat setelah batas akhir baru
    sessionPassedAyahs.removeWhere((a) => a > activeSetoranAyahEnd);
    sessionFailedAyahs.removeWhere((a) => a > activeSetoranAyahEnd);
    
    notifyListeners();
  }

  void toggleAyahPassed(int ayahNumber) {
    if (sessionPassedAyahs.contains(ayahNumber)) {
      sessionPassedAyahs.remove(ayahNumber);
    } else {
      sessionPassedAyahs.add(ayahNumber);
      sessionFailedAyahs.remove(ayahNumber);
    }
    notifyListeners();
  }

  void toggleAyahFailed(int ayahNumber) {
    if (sessionFailedAyahs.contains(ayahNumber)) {
      sessionFailedAyahs.remove(ayahNumber);
    } else {
      sessionFailedAyahs.add(ayahNumber);
      sessionPassedAyahs.remove(ayahNumber);
    }
    notifyListeners();
  }

  void toggleError({
    required int surahNumber,
    required int ayahNumber,
    required int wordIndex,
    required String word,
    required ErrorType errorType,
    String? tajwidRuleName,
  }) {
    final key = ErrorMark.generateKey(surahNumber, ayahNumber, wordIndex);
    if (sessionErrors.containsKey(key) && sessionErrors[key]!.errorType == errorType) {
      sessionErrors.remove(key);
    } else {
      sessionErrors[key] = ErrorMark(
        wordKey: key,
        errorType: errorType,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        wordIndex: wordIndex,
        word: word,
        tajwidRuleName: tajwidRuleName,
      );
    }
    notifyListeners();
  }

  void removeError(String wordKey) {
    sessionErrors.remove(wordKey);
    notifyListeners();
  }

  void clearErrors() {
    sessionErrors.clear();
    sessionPassedAyahs.clear();
    sessionFailedAyahs.clear();
    notifyListeners();
  }

  void stopSetoranSession() {
    activeSetoranSantri = null;
    isTasmiSession = false;
    activeTasmiJuz = [];
    sessionErrors.clear();
    sessionPassedAyahs.clear();
    sessionFailedAyahs.clear();
    notifyListeners();
  }
}
