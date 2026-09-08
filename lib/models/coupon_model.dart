import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String code;
  final String description;
  final CouponType type;
  final double value; // percent (0-100) or fixed amount
  final double? minOrderAmount;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  CouponModel({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.usageLimit,
    this.usedCount = 0,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsageLimitReached =>
      usageLimit != null && usedCount >= usageLimit!;
  bool get isValid => isActive && !isExpired && !isUsageLimitReached;

  double computeDiscount(double subtotal) {
    if (!isValid) return 0;
    if (minOrderAmount != null && subtotal < minOrderAmount!) return 0;
    if (type == CouponType.percent) {
      return (subtotal * value / 100).clamp(0, subtotal);
    }
    return value.clamp(0, subtotal);
  }

  factory CouponModel.fromMap(Map<String, dynamic> map, String code) {
    return CouponModel(
      code: code,
      description: map['description'] ?? '',
      type: map['type'] == 'fixed' ? CouponType.fixed : CouponType.percent,
      value: (map['value'] ?? 0).toDouble(),
      minOrderAmount: map['minOrderAmount'] != null
          ? (map['minOrderAmount']).toDouble()
          : null,
      usageLimit: map['usageLimit'],
      usedCount: map['usedCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      expiresAt: (map['expiresAt'] is Timestamp)
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'type': type.name,
        'value': value,
        'minOrderAmount': minOrderAmount,
        'usageLimit': usageLimit,
        'usedCount': usedCount,
        'isActive': isActive,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

enum CouponType { percent, fixed }
