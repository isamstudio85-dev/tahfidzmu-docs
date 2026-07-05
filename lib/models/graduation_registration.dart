enum RegistrationStatus { menunggu, diterima, ditolak }
enum PaymentStatus { belumBayar, lunas }

class GraduationRegistration {
  final String id;
  final String eventId;
  final String santriId;
  final DateTime registrationDate;
  final RegistrationStatus status;
  final PaymentStatus registrationPaymentStatus;
  final PaymentStatus graduationPaymentStatus;
  final String? notes;
  final String registeredBy; // 'parent', 'musyrif', 'admin'

  const GraduationRegistration({
    required this.id,
    required this.eventId,
    required this.santriId,
    required this.registrationDate,
    this.status = RegistrationStatus.menunggu,
    this.registrationPaymentStatus = PaymentStatus.belumBayar,
    this.graduationPaymentStatus = PaymentStatus.belumBayar,
    this.notes,
    required this.registeredBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'santriId': santriId,
    'registrationDate': registrationDate.toIso8601String(),
    'status': status.name,
    'registrationPaymentStatus': registrationPaymentStatus.name,
    'graduationPaymentStatus': graduationPaymentStatus.name,
    'notes': notes,
    'registeredBy': registeredBy,
  };

  factory GraduationRegistration.fromJson(Map<String, dynamic> json) => GraduationRegistration(
    id: json['id'] as String,
    eventId: json['eventId'] as String,
    santriId: json['santriId'] as String,
    registrationDate: DateTime.parse(json['registrationDate'] as String),
    status: RegistrationStatus.values.byName(json['status'] as String? ?? 'menunggu'),
    registrationPaymentStatus: PaymentStatus.values.byName(json['registrationPaymentStatus'] as String? ?? 'belumBayar'),
    graduationPaymentStatus: PaymentStatus.values.byName(json['graduationPaymentStatus'] as String? ?? 'belumBayar'),
    notes: json['notes'] as String?,
    registeredBy: json['registeredBy'] as String? ?? 'unknown',
  );

  GraduationRegistration copyWith({
    RegistrationStatus? status,
    PaymentStatus? registrationPaymentStatus,
    PaymentStatus? graduationPaymentStatus,
    String? notes,
  }) {
    return GraduationRegistration(
      id: id,
      eventId: eventId,
      santriId: santriId,
      registrationDate: registrationDate,
      status: status ?? this.status,
      registrationPaymentStatus: registrationPaymentStatus ?? this.registrationPaymentStatus,
      graduationPaymentStatus: graduationPaymentStatus ?? this.graduationPaymentStatus,
      notes: notes ?? this.notes,
      registeredBy: registeredBy,
    );
  }
}
