/// App-wide constants: Firestore collection names, storage paths,
/// route names, and shared static configuration.
class AppConstants {
  AppConstants._();

  // Firestore collections
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String cartCollection = 'carts';
  static const String wishlistCollection = 'wishlists';
  static const String couponsCollection = 'coupons';
  static const String notificationsCollection = 'notifications';
  static const String categoriesCollection = 'categories';

  // Storage paths
  static const String bookCoversPath = 'book_covers';
  static const String profileImagesPath = 'profile_images';

  // Shared preference keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefOnboardingSeen = 'pref_onboarding_seen';
  static const String prefLastSync = 'pref_last_sync';

  // Misc
  static const double freeShippingThreshold = 40.0;
  static const double standardShippingFee = 4.99;
  static const int pageSize = 12;
  static const String appName = 'BookVerse';
  static const String supportEmail = 'support@bookverse.app';
  static const String adminEmail = 'admin@bookverse.com';
  static const List<String> adminEmails = [
    'admin@bookverse.com',
  ];

  static bool isAdminEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final clean = email.trim().toLowerCase();
    return adminEmails.any((e) => e.toLowerCase() == clean);
  }
}

enum OrderStatus { placed, confirmed, packed, shipped, outForDelivery, delivered, cancelled, returned }

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  int get step {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.packed:
        return 2;
      case OrderStatus.shipped:
        return 3;
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return -1;
    }
  }
}
