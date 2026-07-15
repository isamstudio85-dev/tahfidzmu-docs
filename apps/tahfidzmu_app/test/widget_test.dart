// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tahfidz_app/main.dart';
import 'package:core_models/core_models.dart';
import 'package:tahfidz_app/providers/app_provider.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/assessment_screen.dart';
import 'package:tahfidz_app/features/tahfidz_quran/screens/laporan_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_list_screen.dart';
import 'package:tahfidz_app/features/management/screens/santri_detail_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const TahfidzApp(),
      ),
    );
    expect(find.text('Tahfidz'), findsOneWidget);
  });

  testWidgets('Santri search filters list by query', (
    WidgetTester tester,
  ) async {
    final provider = AppProvider();
    provider.addSantri('Ali', nis: '001');
    provider.addSantri('Budi', nis: '002');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SantriListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pump();

    expect(find.text('Ali'), findsOneWidget);
    expect(find.text('Budi'), findsNothing);
  });

  testWidgets('Santri list shows juz summary instead of star rating', (
    WidgetTester tester,
  ) async {
    final provider = AppProvider();
    provider.addSantri('Ali', nis: '001');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SantriListScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Juz'), findsOneWidget);
  });

  testWidgets('Santri detail shows juz hafalan info', (
    WidgetTester tester,
  ) async {
    final provider = AppProvider();
    provider.addSantri('Ali', nis: '001');
    final santri = provider.santriList.first;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: SantriDetailScreen(santriId: santri.id)),
      ),
    );
    await tester.pump();

    expect(find.text('Juz Hafalan'), findsWidgets);
  });

  testWidgets('Ranking uses juz-based ordering without mode chips', (
    WidgetTester tester,
  ) async {
    final provider = AppProvider();
    provider.addSantri('Ali', nis: '001');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: LaporanScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(Tab).at(1));
    await tester.pump();

    expect(find.text('Akumulasi'), findsNothing);
    expect(find.text('Ziyadah'), findsNothing);
    expect(find.text("Muroja'ah"), findsNothing);
    expect(find.textContaining('Juz'), findsWidgets);
  });

  testWidgets('Saving a setoran returns to main shell with bottom navigation', (
    WidgetTester tester,
  ) async {
    final provider = AppProvider();
    provider.login(UserRole.admin);
    provider.addSantri('Ali', nis: '001');
    final santri = provider.santriList.first;
    provider.startSetoranSession(
      santri: santri,
      type: SetoranType.ziyadah,
      surah: const SurahInfo(
        number: 1,
        name: 'الفاتحة',
        englishName: 'Al-Fatiha',
        numberOfAyahs: 7,
        revelationType: 'Meccan',
      ),
      ayahStart: 1,
      ayahEnd: 7,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: AssessmentScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Simpan Penilaian'));
    await tester.pump();

    await tester.tap(find.text('Kembali ke Beranda'));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
