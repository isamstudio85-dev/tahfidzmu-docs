/// Static utility for precise Quran juz boundary lookups.
///
/// Data is based on the standard Hafs 'an 'Asim recitation (Madinah mushaf)
/// with 6236 total ayahs across 114 surahs in 30 juz.
class QuranJuzUtils {
  QuranJuzUtils._(); // not instantiable

  // ── Surah start table ──────────────────────────────────────────────────────
  // _surahStart[i] = global ayah number (1-based) of the first ayah of surah i+1.
  // 114 entries, one per surah.
  static const List<int> _surahStart = [
    1, 8, 294, 494, 670, 790, 955, 1161, 1236, 1365, // 1–10
    1474, 1597, 1708, 1751, 1803, 1902, 2030, 2141, 2251, 2349, // 11–20
    2484, 2596, 2674, 2792, 2856, 2933, 3160, 3253, 3341, 3410, // 21–30
    3470, 3504, 3534, 3607, 3661, 3706, 3789, 3971, 4059, 4134, // 31–40
    4219, 4273, 4326, 4415, 4474, 4511, 4546, 4584, 4613, 4631, // 41–50
    4676, 4736, 4785, 4847, 4902, 4980, 5076, 5105, 5127, 5151, // 51–60
    5164, 5178, 5189, 5200, 5218, 5230, 5242, 5272, 5324, 5376, // 61–70
    5420, 5448, 5476, 5496, 5552, 5592, 5623, 5673, 5713, 5759, // 71–80
    5801, 5830, 5849, 5885, 5910, 5932, 5949, 5968, 5994, 6024, // 81–90
    6044, 6059, 6080, 6091, 6099, 6107, 6126, 6131, 6139, 6147, // 91–100
    6158, 6169, 6177, 6180, 6189, 6194, 6198, 6205, 6208, 6214, // 101–110
    6217, 6222, 6226, 6231, // 111–114
  ];

  // ── Juz start table ────────────────────────────────────────────────────────
  // _juzStart[i] = global ayah number where juz i+1 begins.
  // 30 entries, one per juz.
  static const List<int> _juzStart = [
    1, // Juz  1 – Al-Fatihah 1:1
    149, // Juz  2 – Al-Baqarah 2:142
    260, // Juz  3 – Al-Baqarah 2:253
    386, // Juz  4 – Aal-Imran 3:93
    517, // Juz  5 – An-Nisa 4:24
    641, // Juz  6 – An-Nisa 4:148
    751, // Juz  7 – Al-Ma'idah 5:82
    900, // Juz  8 – Al-An'am 6:111
    1042, // Juz  9 – Al-A'raf 7:88
    1201, // Juz 10 – Al-Anfal 8:41
    1328, // Juz 11 – At-Tawbah 9:93
    1479, // Juz 12 – Hud 11:6
    1649, // Juz 13 – Yusuf 12:53
    1803, // Juz 14 – Al-Hijr 15:1
    2030, // Juz 15 – Al-Isra 17:1
    2215, // Juz 16 – Al-Kahf 18:75
    2484, // Juz 17 – Al-Anbiya 21:1
    2674, // Juz 18 – Al-Mu'minun 23:1
    2876, // Juz 19 – Al-Furqan 25:21
    3215, // Juz 20 – An-Naml 27:56
    3386, // Juz 21 – Al-Ankabut 29:46
    3564, // Juz 22 – Al-Ahzab 33:31
    3733, // Juz 23 – Ya-Sin 36:28
    4090, // Juz 24 – Az-Zumar 39:32
    4265, // Juz 25 – Fussilat 41:47
    4511, // Juz 26 – Al-Ahqaf 46:1
    4706, // Juz 27 – Adh-Dhariyat 51:31
    5105, // Juz 28 – Al-Mujadila 58:1
    5242, // Juz 29 – Al-Mulk 67:1
    5673, // Juz 30 – An-Naba 78:1
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Global ayah number (1–6236) for [surahNumber] : [ayahNumber].
  static int globalAyah(int surahNumber, int ayahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return 1;
    return _surahStart[surahNumber - 1] + ayahNumber - 1;
  }

  /// Juz number (1–30) that [surahNumber]:[ayahNumber] belongs to.
  static int juzOf(int surahNumber, int ayahNumber) {
    final g = globalAyah(surahNumber, ayahNumber);
    for (int i = 29; i >= 0; i--) {
      if (g >= _juzStart[i]) return i + 1;
    }
    return 1;
  }

  /// Short label for the juz range of a setoran.
  /// e.g. "Juz 2"  or  "Juz 2–3"
  static String juzLabel(int surahNumber, int ayahStart, int ayahEnd) {
    final jStart = juzOf(surahNumber, ayahStart);
    final jEnd = juzOf(surahNumber, ayahEnd);
    return jStart == jEnd ? 'Juz $jStart' : 'Juz $jStart–$jEnd';
  }

  /// Human-readable summary for a sorted list of distinct juz numbers.
  /// Consecutive runs are condensed: [1,2,3,5] → "Juz 1–3, 5".
  static String juzCoveredText(List<int> juzList) {
    if (juzList.isEmpty) return '-';
    if (juzList.length == 1) return 'Juz ${juzList[0]}';

    final parts = <String>[];
    int runStart = juzList[0];
    int prev = juzList[0];

    for (int i = 1; i < juzList.length; i++) {
      if (juzList[i] == prev + 1) {
        prev = juzList[i];
      } else {
        parts.add(prev == runStart ? '$runStart' : '$runStart–$prev');
        runStart = juzList[i];
        prev = juzList[i];
      }
    }
    parts.add(prev == runStart ? '$runStart' : '$runStart–$prev');

    return 'Juz ${parts.join(', ')}';
  }
}
