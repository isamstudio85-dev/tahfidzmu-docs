class PesantrenInfo {
  final String nama;
  final String alamat;
  final String noTelp;
  final String email;
  final String logoPath; // local file path from image_picker

  const PesantrenInfo({
    this.nama = '',
    this.alamat = '',
    this.noTelp = '',
    this.email = '',
    this.logoPath = '',
  });

  bool get hasLogo => logoPath.isNotEmpty;

  PesantrenInfo copyWith({
    String? nama,
    String? alamat,
    String? noTelp,
    String? email,
    String? logoPath,
  }) {
    return PesantrenInfo(
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      noTelp: noTelp ?? this.noTelp,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'alamat': alamat,
    'noTelp': noTelp,
    'email': email,
    'logoPath': logoPath,
  };

  factory PesantrenInfo.fromJson(Map<String, dynamic> json) => PesantrenInfo(
    nama: json['nama'] as String? ?? '',
    alamat: json['alamat'] as String? ?? '',
    noTelp: json['noTelp'] as String? ?? '',
    email: json['email'] as String? ?? '',
    logoPath: json['logoPath'] as String? ?? '',
  );
}
