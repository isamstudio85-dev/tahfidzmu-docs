import 'package:flutter/material.dart';

enum ErrorType {
  tajwid,
  makhroj;

  String get label {
    switch (this) {
      case ErrorType.tajwid:
        return 'Tajwid';
      case ErrorType.makhroj:
        return 'Makhroj';
    }
  }

  String get description {
    switch (this) {
      case ErrorType.tajwid:
        return 'Kesalahan hukum tajwid';
      case ErrorType.makhroj:
        return 'Kesalahan makhraj huruf';
    }
  }

  Color get color {
    switch (this) {
      case ErrorType.tajwid:
        return const Color(0xFFE65100); // deep orange
      case ErrorType.makhroj:
        return const Color(0xFF1565C0); // deep blue
    }
  }

  Color get bgColor {
    switch (this) {
      case ErrorType.tajwid:
        return const Color(0xFFFFE0B2);
      case ErrorType.makhroj:
        return const Color(0xFFBBDEFB);
    }
  }

  IconData get icon {
    switch (this) {
      case ErrorType.tajwid:
        return Icons.music_note;
      case ErrorType.makhroj:
        return Icons.record_voice_over;
    }
  }
}

class ErrorMark {
  final String wordKey;
  final ErrorType errorType;
  final int surahNumber;
  final int ayahNumber;
  final int wordIndex;
  final String word;

  const ErrorMark({
    required this.wordKey,
    required this.errorType,
    required this.surahNumber,
    required this.ayahNumber,
    required this.wordIndex,
    required this.word,
  });

  static String generateKey(int surahNumber, int ayahNumber, int wordIndex) =>
      '${surahNumber}_${ayahNumber}_$wordIndex';

  Map<String, dynamic> toJson() => {
    'wordKey': wordKey,
    'errorType': errorType.name,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'wordIndex': wordIndex,
    'word': word,
  };

  factory ErrorMark.fromJson(Map<String, dynamic> json) => ErrorMark(
    wordKey: json['wordKey'] as String,
    errorType: ErrorType.values.byName(json['errorType'] as String),
    surahNumber: json['surahNumber'] as int,
    ayahNumber: json['ayahNumber'] as int,
    wordIndex: json['wordIndex'] as int,
    word: json['word'] as String,
  );
}
