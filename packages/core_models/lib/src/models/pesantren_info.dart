class PesantrenInfo {
  final String nama;
  final String alamat;
  final String noTelp;
  final String email;
  final String logoPath; // local file path from image_picker
  final String npsn;      // National School ID Number
  final String website;   // Pesantren Website
  final String pimpinan;  // Head / Kyai of the Pesantren
  final bool qrSecurityEnabled; // Toggle QR scan requirement

  const PesantrenInfo({
    this.nama = '',
    this.alamat = '',
    this.noTelp = '',
    this.email = '',
    this.logoPath = '',
    this.npsn = '',
    this.website = '',
    this.pimpinan = '',
    this.qrSecurityEnabled = true,
  });

  bool get hasLogo => logoPath.isNotEmpty;

  PesantrenInfo copyWith({
    String? nama,
    String? alamat,
    String? noTelp,
    String? email,
    String? logoPath,
    String? npsn,
    String? website,
    String? pimpinan,
    bool? qrSecurityEnabled,
  }) {
    return PesantrenInfo(
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      noTelp: noTelp ?? this.noTelp,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      npsn: npsn ?? this.npsn,
      website: website ?? this.website,
      pimpinan: pimpinan ?? this.pimpinan,
      qrSecurityEnabled: qrSecurityEnabled ?? this.qrSecurityEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'alamat': alamat,
    'noTelp': noTelp,
    'email': email,
    'logoPath': logoPath,
    'npsn': npsn,
    'website': website,
    'pimpinan': pimpinan,
    'qrSecurityEnabled': qrSecurityEnabled,
  };

  factory PesantrenInfo.fromJson(Map<String, dynamic> json) => PesantrenInfo(
    nama: json['nama'] as String? ?? '',
    alamat: json['alamat'] as String? ?? '',
    noTelp: json['noTelp'] as String? ?? '',
    email: json['email'] as String? ?? '',
    logoPath: json['logoPath'] as String? ?? '',
    npsn: json['npsn'] as String? ?? '',
    website: json['website'] as String? ?? '',
    pimpinan: json['pimpinan'] as String? ?? '',
    qrSecurityEnabled: json['qrSecurityEnabled'] as bool? ?? true,
  );
}
