class KelasData {
  final String id;
  final String nama; // e.g. 'Kelas 1A', 'Kelas VII', 'Tahfidz Intensif'
  final String? tingkat; // e.g. 'SD', 'SMP', 'SMA', 'Tsanawiyah', 'Aliyah'
  final String? waliKelas; // Nama wali kelas (free text or musyrifId later)

  const KelasData({
    required this.id,
    required this.nama,
    this.tingkat,
    this.waliKelas,
  });

  KelasData copyWith({String? nama, String? tingkat, String? waliKelas}) {
    return KelasData(
      id: id,
      nama: nama ?? this.nama,
      tingkat: tingkat ?? this.tingkat,
      waliKelas: waliKelas ?? this.waliKelas,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'tingkat': tingkat,
    'waliKelas': waliKelas,
  };

  factory KelasData.fromJson(Map<String, dynamic> json) => KelasData(
    id: json['id'] as String,
    nama: json['nama'] as String,
    tingkat: json['tingkat'] as String?,
    waliKelas: json['waliKelas'] as String?,
  );

  static const List<String> tingkatOptions = [
    'SD / MI',
    'SMP / MTs',
    'SMA / MA',
    'Pesantren',
    'Lainnya',
  ];
}
