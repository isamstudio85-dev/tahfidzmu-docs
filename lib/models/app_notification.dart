import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String targetUserId;
  final bool isRead;
  final String type; // 'setoran' | 'presensi' | 'peringatan'
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.targetUserId,
    this.isRead = false,
    required this.type,
    this.metadata,
  });

  AppNotification copyWith({
    String? title,
    String? body,
    DateTime? timestamp,
    String? targetUserId,
    bool? isRead,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      targetUserId: targetUserId ?? this.targetUserId,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  factory AppNotification.fromJson(String id, Map<String, dynamic> json) {
    DateTime parsedTime;
    final ts = json['timestamp'];
    if (ts is Timestamp) {
      parsedTime = ts.toDate();
    } else if (ts is String) {
      parsedTime = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return AppNotification(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timestamp: parsedTime,
      targetUserId: json['targetUserId'] ?? '',
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'setoran',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'targetUserId': targetUserId,
      'isRead': isRead,
      'type': type,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
