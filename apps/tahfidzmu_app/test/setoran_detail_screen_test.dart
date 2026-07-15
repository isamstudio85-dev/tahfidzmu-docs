import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/setoran_detail_screen.dart';

void main() {
  testWidgets('read-only setoran detail shows summary and error details', (
    WidgetTester tester,
  ) async {
    final santri = Santri(id: '1', name: 'Ali');
    final record = SetoranRecord(
      id: 'r1',
      santriId: santri.id,
      type: SetoranType.ziyadah,
      surahNumber: 1,
      surahName: 'الفاتحة',
      surahEnglishName: 'Al-Fatiha',
      ayahStart: 1,
      ayahEnd: 7,
      errorMarks: [
        const ErrorMark(
          wordKey: '1_1_0',
          errorType: ErrorType.tajwid,
          surahNumber: 1,
          ayahNumber: 1,
          wordIndex: 0,
          word: 'بسم',
        ),
      ],
      fluencyRating: 4,
      date: DateTime(2024, 6, 27, 14, 30),
      finalScore: 78.5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SetoranDetailScreen(record: record, santri: santri),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rincian Hafalan'), findsOneWidget);
    expect(find.textContaining('Ali'), findsWidgets);
    expect(find.textContaining('Tajwid'), findsWidgets);
  });
}
