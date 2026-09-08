import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (map['type'] ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      orderId: map['orderId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'orderId': orderId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

enum NotificationType { orderStatus, promotion, general }

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.orderStatus:
        return 'Order Update';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.general:
        return 'General';
    }
  }
}
