import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;
  final List<Address> addresses;
  final List<SavedPaymentMethod> paymentMethods;
  final bool isAdmin;
  final bool isBanned;
  final DateTime createdAt;
  final int loyaltyPoints;
  final List<String> readingHistory; // bookIds
  final String? fcmToken;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
    this.addresses = const [],
    this.paymentMethods = const [],
    this.isAdmin = false,
    this.isBanned = false,
    required this.createdAt,
    this.loyaltyPoints = 0,
    this.readingHistory = const [],
    this.fcmToken,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    final email = map['email'] ?? '';
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: email,
      photoUrl: map['photoUrl'],
      phone: map['phone'],
      addresses: (map['addresses'] as List<dynamic>? ?? [])
          .map((a) => Address.fromMap(Map<String, dynamic>.from(a)))
          .toList(),
      paymentMethods: (map['paymentMethods'] as List<dynamic>? ?? [])
          .map((p) => SavedPaymentMethod.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      isAdmin: AppConstants.isAdminEmail(email),
      isBanned: map['isBanned'] ?? false,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      readingHistory: List<String>.from(map['readingHistory'] ?? []),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'paymentMethods': paymentMethods.map((p) => p.toMap()).toList(),
      'isAdmin': isAdmin,
      'isBanned': isBanned,
      'createdAt': Timestamp.fromDate(createdAt),
      'loyaltyPoints': loyaltyPoints,
      'readingHistory': readingHistory,
      'fcmToken': fcmToken,
    };
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    String? phone,
    List<Address>? addresses,
    List<SavedPaymentMethod>? paymentMethods,
    bool? isAdmin,
    bool? isBanned,
    int? loyaltyPoints,
    List<String>? readingHistory,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      readingHistory: readingHistory ?? this.readingHistory,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

/// A saved payment method on a user's profile (e.g. "Visa ending 4242").
/// Only display-safe metadata is ever persisted — no full card numbers,
/// CVVs, or other sensitive data should be stored here or anywhere in
/// Firestore. A real production build would tokenize cards through a
/// PCI-compliant processor (Stripe, Braintree, etc.) and store only the
/// returned token/last4/brand, exactly as modeled below.
class SavedPaymentMethod {
  final String id;
  final String type; // 'card' | 'wallet' | 'cod'
  final String label; // e.g. "Visa •••• 4242" or "PayPal"
  final String? last4;
  final String? brand; // Visa, Mastercard, Amex...
  final String? expiry; // MM/YY, card only
  final bool isDefault;

  SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.last4,
    this.brand,
    this.expiry,
    this.isDefault = false,
  });

  factory SavedPaymentMethod.fromMap(Map<String, dynamic> map) => SavedPaymentMethod(
        id: map['id'] ?? '',
        type: map['type'] ?? 'card',
        label: map['label'] ?? '',
        last4: map['last4'],
        brand: map['brand'],
        expiry: map['expiry'],
        isDefault: map['isDefault'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'label': label,
        'last4': last4,
        'brand': brand,
        'expiry': expiry,
        'isDefault': isDefault,
      };
}

class Address {
  final String label; // Home, Work...
  final String line1;
  final String city;
  final String state;
  final String zip;
  final bool isDefault;

  Address({
    required this.label,
    required this.line1,
    required this.city,
    required this.state,
    required this.zip,
    this.isDefault = false,
  });

  factory Address.fromMap(Map<String, dynamic> map) => Address(
        label: map['label'] ?? 'Home',
        line1: map['line1'] ?? '',
        city: map['city'] ?? '',
        state: map['state'] ?? '',
        zip: map['zip'] ?? '',
        isDefault: map['isDefault'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'line1': line1,
        'city': city,
        'state': state,
        'zip': zip,
        'isDefault': isDefault,
      };

  String get formatted => '$line1, $city, $state $zip';
}
