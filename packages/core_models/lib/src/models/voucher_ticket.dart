import 'package:cloud_firestore/cloud_firestore.dart';

enum VoucherStatus { pending, redeemed, expired }

class VoucherTicket {
  final String id;
  final String santriId;
  final String santriName;
  final String rewardId;
  final String rewardName;
  final int cost;
  final DateTime purchaseDate;
  final DateTime? redeemedDate;
  final VoucherStatus status;

  const VoucherTicket({
    required this.id,
    required this.santriId,
    required this.santriName,
    required this.rewardId,
    required this.rewardName,
    required this.cost,
    required this.purchaseDate,
    this.redeemedDate,
    this.status = VoucherStatus.pending,
  });

  factory VoucherTicket.fromJson(Map<String, dynamic> json) {
    return VoucherTicket(
      id: json['id'] as String,
      santriId: json['santriId'] as String,
      santriName: json['santriName'] as String,
      rewardId: json['rewardId'] as String,
      rewardName: json['rewardName'] as String,
      cost: json['cost'] as int,
      purchaseDate: (json['purchaseDate'] as Timestamp).toDate(),
      redeemedDate: json['redeemedDate'] != null 
          ? (json['redeemedDate'] as Timestamp).toDate() 
          : null,
      status: VoucherStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VoucherStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'santriId': santriId,
    'santriName': santriName,
    'rewardId': rewardId,
    'rewardName': rewardName,
    'cost': cost,
    'purchaseDate': Timestamp.fromDate(purchaseDate),
    'redeemedDate': redeemedDate != null ? Timestamp.fromDate(redeemedDate!) : null,
    'status': status.name,
  };
}
