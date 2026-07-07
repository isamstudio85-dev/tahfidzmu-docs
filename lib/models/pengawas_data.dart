class PengawasData {
  final String id;
  final String nama;
  final String username; // Nomor HP atau nama login
  final String nomorHp;
  final String jabatan; // e.g. Pimpinan Pondok, Koordinator, dll.
  final String status; // 'aktif' / 'nonaktif'
  final String? photoPath;
  final String? catatan;

  const PengawasData({
    required this.id,
    required this.nama,
    required this.username,
    this.nomorHp = '',
    this.jabatan = 'Pengawas',
    this.status = 'aktif',
    this.photoPath,
    this.catatan,
  });

  bool get isAktif => status == 'aktif';

  PengawasData copyWith({
    String? nama,
    String? username,
    String? nomorHp,
    String? jabatan,
    String? status,
    String? photoPath,
    String? catatan,
  }) {
    return PengawasData(
      id: id,
      nama: nama ?? this.nama,
      username: username ?? this.username,
      nomorHp: nomorHp ?? this.nomorHp,
      jabatan: jabatan ?? this.jabatan,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      catatan: catatan ?? this.catatan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'username': username,
    'nomorHp': nomorHp,
    'jabatan': jabatan,
    'status': status,
    'photoPath': photoPath,
    'catatan': catatan,
  };

  factory PengawasData.fromJson(Map<String, dynamic> json) => PengawasData(
    id: json['id'] as String,
    nama: json['nama'] as String,
    username: json['username'] as String,
    nomorHp: (json['nomorHp'] as String?) ?? '',
    jabatan: (json['jabatan'] as String?) ?? 'Pengawas',
    status: (json['status'] as String?) ?? 'aktif',
    photoPath: json['photoPath'] as String?,
    catatan: json['catatan'] as String?,
  );
}
