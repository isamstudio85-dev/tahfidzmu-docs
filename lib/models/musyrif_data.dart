class MusyrifData {
  final String id;
  final String nama;
  final String? nip; // Nomor Induk Pegawai (login key)
  final String jenisKelamin; // 'L' / 'P'
  final String jabatan; // free text, e.g. Musyrif, Koordinator Tahfidz, dll.
  final String lembaga;
  final String nomorHp;
  final String? photoPath;
  final String status; // 'aktif' / 'nonaktif'
  final String? catatan;

  const MusyrifData({
    required this.id,
    required this.nama,
    this.nip,
    this.jenisKelamin = 'L',
    this.jabatan = 'Musyrif',
    this.lembaga = 'Halaqah Tahfidz',
    this.nomorHp = '',
    this.photoPath,
    this.status = 'aktif',
    this.catatan,
  });

  bool get isAktif => status == 'aktif';

  MusyrifData copyWith({
    String? nama,
    String? nip,
    String? jenisKelamin,
    String? jabatan,
    String? lembaga,
    String? nomorHp,
    String? photoPath,
    String? status,
    String? catatan,
  }) {
    return MusyrifData(
      id: id,
      nama: nama ?? this.nama,
      nip: nip ?? this.nip,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      jabatan: jabatan ?? this.jabatan,
      lembaga: lembaga ?? this.lembaga,
      nomorHp: nomorHp ?? this.nomorHp,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'nip': nip,
    'jenisKelamin': jenisKelamin,
    'jabatan': jabatan,
    'lembaga': lembaga,
    'nomorHp': nomorHp,
    'photoPath': photoPath,
    'status': status,
    'catatan': catatan,
  };

  factory MusyrifData.fromJson(Map<String, dynamic> json) => MusyrifData(
    id: json['id'] as String,
    nama: json['nama'] as String,
    nip: json['nip'] as String?,
    jenisKelamin: (json['jenisKelamin'] as String?) ?? 'L',
    jabatan: (json['jabatan'] as String?) ?? 'Musyrif',
    lembaga: (json['lembaga'] as String?) ?? 'Halaqah Tahfidz',
    nomorHp: (json['nomorHp'] as String?) ?? '',
    photoPath: json['photoPath'] as String?,
    status: (json['status'] as String?) ?? 'aktif',
    catatan: json['catatan'] as String?,
  );
}
