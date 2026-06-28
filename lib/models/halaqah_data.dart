class HalaqahData {
  final String id;
  final String nama;
  final String? musyrifId;
  final String level;
  final int? kapasitas; // max santri in this halaqah
  final String? targetJuz; // e.g. 'Juz 30', '10 Juz', 'Hafal 30 Juz'
  final String? deskripsi;
  final String? jadwal;
  final String? lokasi;

  const HalaqahData({
    required this.id,
    required this.nama,
    this.musyrifId,
    this.level = 'Pemula',
    this.kapasitas,
    this.targetJuz,
    this.deskripsi,
    this.jadwal,
    this.lokasi,
  });

  HalaqahData copyWith({
    String? nama,
    String? musyrifId,
    String? level,
    int? kapasitas,
    String? targetJuz,
    String? deskripsi,
    String? jadwal,
    String? lokasi,
  }) {
    return HalaqahData(
      id: id,
      nama: nama ?? this.nama,
      musyrifId: musyrifId ?? this.musyrifId,
      level: level ?? this.level,
      kapasitas: kapasitas ?? this.kapasitas,
      targetJuz: targetJuz ?? this.targetJuz,
      deskripsi: deskripsi ?? this.deskripsi,
      jadwal: jadwal ?? this.jadwal,
      lokasi: lokasi ?? this.lokasi,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'musyrifId': musyrifId,
    'level': level,
    'kapasitas': kapasitas,
    'targetJuz': targetJuz,
    'deskripsi': deskripsi,
    'jadwal': jadwal,
    'lokasi': lokasi,
  };

  factory HalaqahData.fromJson(Map<String, dynamic> json) => HalaqahData(
    id: json['id'] as String,
    nama: json['nama'] as String,
    musyrifId: json['musyrifId'] as String?,
    level: (json['level'] as String?) ?? 'Pemula',
    kapasitas: json['kapasitas'] as int?,
    targetJuz: json['targetJuz'] as String?,
    deskripsi: json['deskripsi'] as String?,
    jadwal: json['jadwal'] as String?,
    lokasi: json['lokasi'] as String?,
  );

  static const List<String> levelOptions = [
    'Pemula',
    'Menengah',
    'Lanjutan',
    'Takhassus',
  ];
}
