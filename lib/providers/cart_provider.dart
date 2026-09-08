import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/cart_item_model.dart';
import '../utils/constants.dart';

/// In-memory cart, persisted per-session. Cart totals, shipping and
/// coupon discounts are all computed here so checkout/cart screens
/// stay purely presentational.
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? appliedCouponCode;
  double couponDiscountPercent = 0;

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);
  double get shipping => subtotal >= AppConstants.freeShippingThreshold || subtotal == 0
      ? 0
      : AppConstants.standardShippingFee;
  double get discountAmount => subtotal * (couponDiscountPercent / 100);
  double get total => (subtotal - discountAmount + shipping).clamp(0, double.infinity);

  void addBook(Book book, {int quantity = 1}) {
    if (_items.containsKey(book.id)) {
      _items[book.id]!.quantity += quantity;
    } else {
      _items[book.id] = CartItem(
        bookId: book.id,
        title: book.title,
        coverUrl: book.coverUrl,
        price: book.effectivePrice,
        quantity: quantity,
      );
    }
    notifyListeners();
  }

  void removeBook(String bookId) {
    _items.remove(bookId);
    notifyListeners();
  }

  void updateQuantity(String bookId, int quantity) {
    if (quantity <= 0) {
      removeBook(bookId);
      return;
    }
    _items[bookId]?.quantity = quantity;
    notifyListeners();
  }

  void applyCoupon(String code, double discountPercent) {
    appliedCouponCode = code;
    couponDiscountPercent = discountPercent;
    notifyListeners();
  }

  void removeCoupon() {
    appliedCouponCode = null;
    couponDiscountPercent = 0;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    appliedCouponCode = null;
    couponDiscountPercent = 0;
    notifyListeners();
  }
}
