class KelasData {
  final String id;
  final String nama;

  const KelasData({
    required this.id,
    required this.nama,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
  };

  factory KelasData.fromJson(Map<String, dynamic> json) => KelasData(
    id: json['id'] as String,
    nama: json['nama'] as String,
  );
}
