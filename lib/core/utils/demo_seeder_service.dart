import 'dart:math';
import 'package:tahfidz_app/models/santri.dart';
import 'package:tahfidz_app/models/setoran.dart';
import 'package:tahfidz_app/models/musyrif_data.dart';
import 'package:tahfidz_app/models/halaqah_data.dart';
import 'package:tahfidz_app/providers/app_provider.dart';

class DemoSeederService {
  static final Random _random = Random();

  static const List<String> _names = [
    'Abdurrahman bin Auf',
    'Abdullah', 'Ahmad', 'Zaid', 'Umar', 'Usman', 'Ali', 'Hamzah', 'Thariq', 
    'Fatih', 'Ibrahim', 'Yusuf', 'Musa', 'Isa', 'Yahya', 'Zakaria', 'Sulaiman',
    'Daud', 'Harun', 'Luth', 'Shalih', 'Hud', 'Nuh', 'Idris', 'Adam'
  ];

  static const List<String> _surahNames = [
    'النبأ', 'النازعات', 'عبس', 'التكوير', 'الإنفطار', 'المطففين',
    'الانشقاق', 'البروج', 'الطارق', 'الأعلى', 'الغاشية', 'الفجر'
  ];

  static const List<String> _surahEnglishNames = [
    'An-Naba', 'An-Nazi\'at', 'Abasa', 'At-Takwir', 'Al-Infithar', 'Al-Muthaffifin',
    'Al-Insyiqaq', 'Al-Buruj', 'At-Thariq', 'Al-A\'la', 'Al-Ghasyiyah', 'Al-Fajr'
  ];

  static Future<void> seedDemoData(AppProvider provider) async {
    // 1. Create Musyrif
    final musyrifId = provider.generateId('musyrif');
    final musyrif = MusyrifData(
      id: musyrifId,
      nama: 'Ustadz Ahmad Al-Fatih',
      nip: '19900101',
      jabatan: 'Pembimbing Utama',
      isKoordinator: true,
    );
    await provider.getCollection('musyrif').doc(musyrifId).set(musyrif.toJson());

    // 2. Create Halaqah
    final halaqahId = provider.generateId('halaqah');
    final halaqah = HalaqahData(
      id: halaqahId,
      nama: 'Halaqah Imam Syafi\'i',
      musyrifId: musyrifId,
    );
    await provider.getCollection('halaqah').doc(halaqahId).set(halaqah.toJson());

    // 3. Create Santri & Setoran
    for (int i = 0; i < _names.length; i++) {
      final santriId = provider.generateId('santri');
      final name = _names[i];
      
      // Randomize XP and Level for ranking variety
      int baseXP = 500 + _random.nextInt(5000);
      int coins = 100 + _random.nextInt(1000);
      
      // Khusus untuk Abdurrahman bin Auf, beri koin melimpah agar bisa langsung belanja
      if (name == 'Abdurrahman bin Auf') {
        baseXP = 15000;
        coins = 9999;
      }
      
      final santri = Santri(
        id: santriId,
        name: name,
        nis: name == 'Abdurrahman bin Auf' ? '2024999' : '2024${i.toString().padLeft(3, '0')}',
        email: name == 'Abdurrahman bin Auf' ? 'abdurrahman@demo.com' : '${name.replaceAll(' ', '').toLowerCase()}@demo.com',
        totalXP: baseXP,
        totalCoins: coins,
        halaqahId: halaqahId,
        kelas: '10-A',
        status: 'aktif',
      );

      await provider.getCollection('santri').doc(santriId).set(santri.toJson());

      // Create 5-10 random setoran for each santri
      final setoranCount = 5 + _random.nextInt(5);
      for (int j = 0; j < setoranCount; j++) {
        final setoranId = provider.generateId('setoran');
        final surahIndex = _random.nextInt(_surahEnglishNames.length);
        final score = 80.0 + _random.nextInt(20);
        
        final setoran = SetoranRecord(
          id: setoranId,
          santriId: santriId,
          date: DateTime.now().subtract(Duration(days: j)),
          surahNumber: 78 + surahIndex,
          surahName: _surahNames[surahIndex],
          surahEnglishName: _surahEnglishNames[surahIndex],
          ayahStart: 1,
          ayahEnd: 10,
          type: SetoranType.ziyadah,
          errorMarks: [],
          fluencyRating: 5,
          finalScore: score,
        );

        await provider.getCollection('santri').doc(santriId).collection('setoranHistory').doc(setoranId).set(setoran.toJson());
      }
    }
  }
}
