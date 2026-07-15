class MusyrifData {
  final String id;
  final String nama;
  final String? nip; // Nomor Induk Pegawai (login key)
  final String jenisKelamin; // 'L' / 'P'
  final String jabatan; // free text, e.g. Musyrif, Koordinator Tahfidz, dll.
  final String lembaga;
  final String nomorHp;
  final String? photoPath;
  final String? email;
  final String status; // 'aktif' / 'nonaktif'
  final String? catatan;
  
  /// Whether this musyrif has administrative privileges (can manage others).
  final bool isKoordinator;
  
  /// List of halaqah IDs that this coordinator is responsible for.
  /// If empty and isKoordinator is true, they might manage everything (depending on pesantren size).
  final List<String> managedHalaqahIds;

  const MusyrifData({
    required this.id,
    required this.nama,
    this.nip,
    this.jenisKelamin = 'L',
    this.jabatan = 'Musyrif',
    this.lembaga = 'Halaqah Tahfidz',
    this.nomorHp = '',
    this.photoPath,
    this.email,
    this.status = 'aktif',
    this.catatan,
    this.isKoordinator = false,
    this.managedHalaqahIds = const [],
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
    String? email,
    String? status,
    String? catatan,
    bool? isKoordinator,
    List<String>? managedHalaqahIds,
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
      email: email ?? this.email,
      status: status ?? this.status,
      catatan: catatan ?? this.catatan,
      isKoordinator: isKoordinator ?? this.isKoordinator,
      managedHalaqahIds: managedHalaqahIds ?? this.managedHalaqahIds,
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
    'email': email,
    'status': status,
    'catatan': catatan,
    'isKoordinator': isKoordinator,
    'managedHalaqahIds': managedHalaqahIds,
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
    email: json['email'] as String?,
    status: (json['status'] as String?) ?? 'aktif',
    catatan: json['catatan'] as String?,
    isKoordinator: json['isKoordinator'] as bool? ?? false,
    managedHalaqahIds: (json['managedHalaqahIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );
}
