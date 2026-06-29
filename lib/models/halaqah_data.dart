class HalaqahData {
  final String id;
  final String nama;
  final String? musyrifId;
  final String? photoPath;

  const HalaqahData({
    required this.id,
    required this.nama,
    this.musyrifId,
    this.photoPath,
  });

  HalaqahData copyWith({
    String? nama,
    String? musyrifId,
    String? photoPath,
  }) {
    return HalaqahData(
      id: id,
      nama: nama ?? this.nama,
      musyrifId: musyrifId ?? this.musyrifId,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'musyrifId': musyrifId,
    'photoPath': photoPath,
  };

  factory HalaqahData.fromJson(Map<String, dynamic> json) => HalaqahData(
    id: json['id'] as String,
    nama: json['nama'] as String,
    musyrifId: json['musyrifId'] as String?,
    photoPath: json['photoPath'] as String?,
  );
}
