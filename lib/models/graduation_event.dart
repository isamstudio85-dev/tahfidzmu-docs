class GraduationEvent {
  final String id;
  final String title; 
  final String year;
  final DateTime? examStartDate;
  final DateTime? examEndDate;
  final DateTime? graduationDate; // Tanggal Perayaan Wisuda
  final String method; 
  final int sessionsCount; 
  final String requirements; 
  final String description; // Isi Pengumuman
  final String status; // 'upcoming', 'ongoing', 'completed'
  final bool isPublished; // On/Off di Aplikasi
  final bool isCertificatesReleased; // Apakah sertifikat sudah boleh diunduh?
  final double registrationFee; // Biaya pendaftaran ujian
  final double graduationFee; // Biaya wisuda/pelaksanaan
  final String? bannerPath; // Path gambar popup motivasi

  const GraduationEvent({
    required this.id,
    required this.title,
    required this.year,
    this.examStartDate,
    this.examEndDate,
    this.graduationDate,
    this.method = "Tasmi' Sekali Duduk",
    this.sessionsCount = 1,
    this.requirements = "",
    this.description = "",
    this.status = 'upcoming',
    this.isPublished = false,
    this.isCertificatesReleased = false,
    this.registrationFee = 0,
    this.graduationFee = 0,
    this.bannerPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'year': year,
    'examStartDate': examStartDate?.toIso8601String(),
    'examEndDate': examEndDate?.toIso8601String(),
    'graduationDate': graduationDate?.toIso8601String(),
    'method': method,
    'sessionsCount': sessionsCount,
    'requirements': requirements,
    'description': description,
    'status': status,
    'isPublished': isPublished,
    'isCertificatesReleased': isCertificatesReleased,
    'registrationFee': registrationFee,
    'graduationFee': graduationFee,
    'bannerPath': bannerPath,
  };

  factory GraduationEvent.fromJson(Map<String, dynamic> json) => GraduationEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    year: json['year'] as String,
    examStartDate: json['examStartDate'] != null ? DateTime.parse(json['examStartDate'] as String) : null,
    examEndDate: json['examEndDate'] != null ? DateTime.parse(json['examEndDate'] as String) : null,
    graduationDate: json['graduationDate'] != null ? DateTime.parse(json['graduationDate'] as String) : null,
    method: json['method'] as String? ?? "Tasmi' Sekali Duduk",
    sessionsCount: json['sessionsCount'] as int? ?? 1,
    requirements: json['requirements'] as String? ?? "",
    description: json['description'] as String? ?? "",
    status: json['status'] as String? ?? 'upcoming',
    isPublished: json['isPublished'] as bool? ?? false,
    isCertificatesReleased: json['isCertificatesReleased'] as bool? ?? false,
    registrationFee: (json['registrationFee'] as num?)?.toDouble() ?? 0,
    graduationFee: (json['graduationFee'] as num?)?.toDouble() ?? 0,
    bannerPath: json['bannerPath'] as String?,
  );

  GraduationEvent copyWith({
    String? title,
    String? year,
    DateTime? examStartDate,
    DateTime? examEndDate,
    DateTime? graduationDate,
    String? method,
    int? sessionsCount,
    String? requirements,
    String? description,
    String? status,
    bool? isPublished,
    bool? isCertificatesReleased,
    double? registrationFee,
    double? graduationFee,
    String? bannerPath,
  }) {
    return GraduationEvent(
      id: id,
      title: title ?? this.title,
      year: year ?? this.year,
      examStartDate: examStartDate ?? this.examStartDate,
      examEndDate: examEndDate ?? this.examEndDate,
      graduationDate: graduationDate ?? this.graduationDate,
      method: method ?? this.method,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      requirements: requirements ?? this.requirements,
      description: description ?? this.description,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      isCertificatesReleased: isCertificatesReleased ?? this.isCertificatesReleased,
      registrationFee: registrationFee ?? this.registrationFee,
      graduationFee: graduationFee ?? this.graduationFee,
      bannerPath: bannerPath ?? this.bannerPath,
    );
  }
}
