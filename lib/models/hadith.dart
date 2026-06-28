class Hadith {
  final int id;
  final int? arbainNo;
  final String tema;
  final String perawi;
  final String sumber;
  final String matanArab;
  final String terjemah;

  const Hadith({
    required this.id,
    this.arbainNo,
    required this.tema,
    required this.perawi,
    required this.sumber,
    required this.matanArab,
    required this.terjemah,
  });

  bool get isArbain => arbainNo != null;

  factory Hadith.fromJson(Map<String, dynamic> json) => Hadith(
    id: json['id'] as int,
    arbainNo: json['arbain_no'] as int?,
    tema: json['tema'] as String,
    perawi: json['perawi'] as String,
    sumber: json['sumber'] as String,
    matanArab: json['matan_arab'] as String,
    terjemah: json['terjemah'] as String,
  );

  static String temaLabel(String key) {
    const labels = {
      'niat': 'Niat & Ikhlas',
      'akidah': 'Akidah & Tauhid',
      'ibadah': 'Ibadah',
      'akhlak': 'Akhlak Mulia',
      'quran': 'Al-Quran',
      'ilmu': 'Ilmu & Hikmah',
      'muamalah': 'Muamalah',
      'keluarga': 'Keluarga',
      'doa': 'Doa & Dzikir',
      'larangan': 'Larangan',
      'dunia': 'Dunia & Akhirat',
      'kesehatan': 'Kesehatan',
    };
    return labels[key] ?? key;
  }

  static const allTemas = [
    'niat',
    'akidah',
    'ibadah',
    'akhlak',
    'quran',
    'ilmu',
    'muamalah',
    'keluarga',
    'doa',
    'larangan',
    'dunia',
    'kesehatan',
  ];
}
