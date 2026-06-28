import 'setoran.dart';
import 'surah_model.dart';

/// Suggested next setoran position based on last completed setoran.
class SetoranContinuation {
  final SurahInfo surah;
  final int ayahStart;
  final int ayahEnd;
  final SetoranType type;

  const SetoranContinuation({
    required this.surah,
    required this.ayahStart,
    required this.ayahEnd,
    required this.type,
  });

  String get description =>
      '${type.label} · ${surah.englishName} Ayat $ayahStart–$ayahEnd';
}
