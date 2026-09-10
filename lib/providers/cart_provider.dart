import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/cart_item_model.dart';
import '../utils/constants.dart';

/// Keeps the current shopping cart in memory and calculates checkout totals.
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? appliedCouponCode;
  double couponDiscountPercent = 0;

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  // These values are calculated from the current cart instead of stored separately.
  double get subtotal => _items.values.fold(0.0, (sum, i) => sum + i.subtotal);
  double get shipping => subtotal >= AppConstants.freeShippingThreshold || subtotal == 0
      ? 0
      : AppConstants.standardShippingFee;
  double get discountAmount => subtotal * (couponDiscountPercent / 100);
  double get total => (subtotal - discountAmount + shipping).clamp(0, double.infinity);

  void addBook(Book book, {int quantity = 1}) {
    // If the book is already in the cart, increase its quantity.
    if (_items.containsKey(book.id)) {
      _items[book.id]!.quantity += quantity;
    } else {
      // Otherwise create a new cart item using the book's current selling price.
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
    // Remove the selected book completely from the cart.
    _items.remove(bookId);
    notifyListeners();
  }

  void updateQuantity(String bookId, int quantity) {
    // A quantity of zero or less means the item should be removed.
    if (quantity <= 0) {
      removeBook(bookId);
      return;
    }

    _items[bookId]?.quantity = quantity;
    notifyListeners();
  }

  void applyCoupon(String code, double discountPercent) {
    // Store the coupon information so the calculated total reflects the discount.
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
    // Used after checkout or when the user wants to empty the entire cart.
    _items.clear();
    appliedCouponCode = null;
    couponDiscountPercent = 0;
    notifyListeners();
  }
}
