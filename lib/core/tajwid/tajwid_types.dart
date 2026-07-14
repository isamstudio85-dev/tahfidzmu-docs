import 'package:flutter/material.dart';

/// Jenis-jenis hukum tajwid yang dideteksi oleh engine.
enum TajwidType {
  /// Nun sakinah/tanwin bertemu ي ن م w — dibaca dengung + lebur
  idghamBighunnah,

  /// Nun sakinah/tanwin bertemu ل ر — dibaca lebur tanpa dengung
  idghamBilaghunnah,

  /// Nun sakinah/tanwin bertemu 15 huruf ikhfa — dibaca samar
  ikhfaHaqiqi,

  /// Nun sakinah/tanwin bertemu ب — nun berubah jadi mim
  iqlab,

  /// Nun sakinah/tanwin bertemu huruf halqi (ء ه ع ح غ خ) — dibaca jelas
  izharHalqi,

  /// Nun atau mim bertasydid — dibaca dengung 2 harakat
  ghunnah,

  /// Huruf qalqalah (ق ط b gi d) dalam keadaan sakinah — memantul
  qalqalah,

  /// Mad tabi'i — panjang 2 harakat
  madThabii,

  /// Mim sakinah bertemu b — dibaca samar
  ikhfaSyafawi,
}

/// Extension untuk properti visual setiap hukum tajwid.
extension TajwidTypeExtension on TajwidType {
  /// Warna utama untuk rendering teks.
  Color get color {
    switch (this) {
      case TajwidType.idghamBighunnah:
        return const Color(0xFF2E7D32); // hijau
      case TajwidType.idghamBilaghunnah:
        return const Color(0xFF1B5E20); // hijau tua
      case TajwidType.ikhfaHaqiqi:
        return const Color(0xFF0288D1); // biru muda
      case TajwidType.iqlab:
        return const Color(0xFF7B1FA2); // ungu
      case TajwidType.izharHalqi:
        return const Color(0xFFE65100); // oranye
      case TajwidType.ghunnah:
        return const Color(0xFF1565C0); // biru
      case TajwidType.qalqalah:
        return const Color(0xFFC62828); // merah
      case TajwidType.madThabii:
        return const Color(0xFFD81B60); // pink / mad
      case TajwidType.ikhfaSyafawi:
        return const Color(0xFF00838F); // biru gelap/teal
    }
  }

  /// Label dalam Bahasa Indonesia.
  String get label {
    switch (this) {
      case TajwidType.idghamBighunnah:
        return 'Idgham Bighunnah';
      case TajwidType.idghamBilaghunnah:
        return 'Idgham Bilaghunnah';
      case TajwidType.ikhfaHaqiqi:
        return 'Ikhfa Haqiqi';
      case TajwidType.iqlab:
        return 'Iqlab';
      case TajwidType.izharHalqi:
        return 'Izhar Halqi';
      case TajwidType.ghunnah:
        return 'Ghunnah';
      case TajwidType.qalqalah:
        return 'Qalqalah';
      case TajwidType.madThabii:
        return 'Mad Tabi\'i';
      case TajwidType.ikhfaSyafawi:
        return 'Ikhfa Syafawi';
    }
  }

  /// Deskripsi singkat hukum.
  String get description {
    switch (this) {
      case TajwidType.idghamBighunnah:
        return 'Nun sakinah/tanwin + ي ن م و';
      case TajwidType.idghamBilaghunnah:
        return 'Nun sakinah/tanwin + ل ر';
      case TajwidType.ikhfaHaqiqi:
        return 'Nun sakinah/tanwin + 15 huruf';
      case TajwidType.iqlab:
        return 'Nun sakinah/tanwin + ب';
      case TajwidType.izharHalqi:
        return 'Nun sakinah/tanwin + huruf halqi';
      case TajwidType.ghunnah:
        return 'Nun/Mim bertasydid';
      case TajwidType.qalqalah:
        return 'ق ط ب ج d saat sakinah';
      case TajwidType.madThabii:
        return 'Panjang 2 harakat';
      case TajwidType.ikhfaSyafawi:
        return 'Mim sakinah + ب';
    }
  }

  /// Contoh teks Arab untuk legenda.
  String get example {
    switch (this) {
      case TajwidType.idghamBighunnah:
        return 'مِن مَّاءٍ';
      case TajwidType.idghamBilaghunnah:
        return 'مِن رَّbِّهِمْ';
      case TajwidType.ikhfaHaqiqi:
        return 'مِن قَبْلِ';
      case TajwidType.iqlab:
        return 'أَنۢbِئْهُم';
      case TajwidType.izharHalqi:
        return 'مِنْ عِلْمٍ';
      case TajwidType.ghunnah:
        return 'إِنَّ';
      case TajwidType.qalqalah:
        return 'أَحَدْ';
      case TajwidType.madThabii:
        return 'قَالَ';
      case TajwidType.ikhfaSyafawi:
        return 'تَرْمِيهِم بِحِجَارَةٍ';
    }
  }
}

/// Maps cpfair rule names to TajwidType
TajwidType? parseCpfairRule(String rule) {
  switch (rule) {
    case 'ghunnah':
      return TajwidType.ghunnah;
    case 'idghaam_ghunnah':
    case 'idghaam_mutajaanisain':
    case 'idghaam_mutaqaaribain':
      return TajwidType.idghamBighunnah;
    case 'idghaam_no_ghunnah':
      return TajwidType.idghamBilaghunnah;
    case 'ikhfa':
      return TajwidType.ikhfaHaqiqi;
    case 'ikhfa_shafawi':
      return TajwidType.ikhfaSyafawi;
    case 'iqlab':
      return TajwidType.iqlab;
    case 'izhar':
    case 'izhar_shafawi':
      return TajwidType.izharHalqi;
    case 'qalqalah':
      return TajwidType.qalqalah;
    case 'madd_2':
    case 'madd_246':
    case 'madd_45':
    case 'madd_muttasil':
    case 'madd_munfasil':
    case 'madd_6':
    case 'madd_lazim':
      return TajwidType.madThabii;
    default:
      return null;
  }
}
