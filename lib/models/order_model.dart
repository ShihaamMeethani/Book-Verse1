import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import 'cart_item_model.dart';

class BookOrder {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final String? couponCode;
  final String shippingAddress;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;
  final String? trackingNumber;

  BookOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shipping,
    this.discount = 0,
    required this.total,
    this.couponCode,
    required this.shippingAddress,
    required this.paymentMethod,
    this.status = OrderStatus.placed,
    required this.createdAt,
    this.trackingNumber,
  });

  factory BookOrder.fromMap(Map<String, dynamic> map, String id) {
    return BookOrder(
      id: id,
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => CartItem.fromMap(Map<String, dynamic>.from(i)))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      shipping: (map['shipping'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      couponCode: map['couponCode'],
      shippingAddress: map['shippingAddress'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'placed'),
        orElse: () => OrderStatus.placed,
      ),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      trackingNumber: map['trackingNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'couponCode': couponCode,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'trackingNumber': trackingNumber,
    };
  }
}
