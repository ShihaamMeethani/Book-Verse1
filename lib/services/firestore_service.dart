import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../utils/constants.dart';

/// Central data-access layer for books, orders, reviews and coupons.
/// Keeping all Firestore query logic here (rather than scattered across
/// screens) makes the app easy to extend and to unit test.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _books =>
      _db.collection(AppConstants.booksCollection);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConstants.ordersCollection);
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection(AppConstants.reviewsCollection);

  // ── Books ────────────────────────────────────────────────
  Stream<List<Book>> streamAllBooks() {
    return _books.orderBy('title').snapshots().map(
        (s) => s.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Book>> streamFeatured() {
    return _books.where('isFeatured', isEqualTo: true).limit(10).snapshots().map(
        (s) => s.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Book>> streamBestsellers() {
    return _books
        .where('isBestseller', isEqualTo: true)
        .orderBy('soldCount', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Book>> streamNewArrivals() {
    return _books
        .where('isNewArrival', isEqualTo: true)
        .orderBy('releaseDate', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<Book>> streamByGenre(String genre) {
    return _books.where('genres', arrayContains: genre).snapshots().map(
        (s) => s.docs.map((d) => Book.fromMap(d.data(), d.id)).toList());
  }

  Future<Book?> getBook(String id) async {
    final doc = await _books.doc(id).get();
    if (!doc.exists) return null;
    return Book.fromMap(doc.data()!, doc.id);
  }

  /// Naive client-side search across title/author. For scale, this should
  /// be swapped for Algolia or Firestore full-text extensions — noted in
  /// the README as a suggested production upgrade.
  Future<List<Book>> searchBooks(String query) async {
    final snapshot = await _books.get();
    final lower = query.toLowerCase();
    return snapshot.docs
        .map((d) => Book.fromMap(d.data(), d.id))
        .where((b) =>
            b.title.toLowerCase().contains(lower) ||
            b.author.toLowerCase().contains(lower) ||
            b.genres.any((g) => g.toLowerCase().contains(lower)))
        .toList();
  }

  /// Simple content-based recommendation: books sharing genres with the
  /// given book, sorted by rating. A lightweight stand-in for a full
  /// recommendation engine (see README "Future Work").
  Future<List<Book>> recommendationsFor(Book book, {int limit = 6}) async {
    final snapshot = await _books.where('genres', arrayContainsAny: book.genres).get();
    final list = snapshot.docs
        .map((d) => Book.fromMap(d.data(), d.id))
        .where((b) => b.id != book.id)
        .toList()
      ..sort((a, b) => b.avgRating.compareTo(a.avgRating));
    return list.take(limit).toList();
  }

  /// Saves a book through the Firestore SDK.
  /// Refresh the auth token first so a freshly signed-in account is not using
  /// a stale token. Firebase Storage is not involved in this operation.
  Future<void> addOrUpdateBook(Book book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in. Please log in again.');
    await user.getIdToken(true);
    await _books.doc(book.id).set(book.toMap(), SetOptions(merge: true))
        .timeout(const Duration(seconds: 20));
  }

  Future<void> deleteBook(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in. Please log in again.');
    await user.getIdToken(true);
    await _books.doc(id).delete().timeout(const Duration(seconds: 20));
  }

  Future<void> decrementStock(String bookId, int qty) {
    return _books.doc(bookId).update({
      'stock': FieldValue.increment(-qty),
      'soldCount': FieldValue.increment(qty),
    });
  }

  // ── Reviews ──────────────────────────────────────────────
  Stream<List<Review>> streamReviews(String bookId) {
    return _reviews
        .where('bookId', isEqualTo: bookId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Review.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addReview(Review review) async {
    if (review.id.isNotEmpty) {
      await _reviews.doc(review.id).set(review.toMap(), SetOptions(merge: true));
    } else {
      final existing = await _reviews
          .where('bookId', isEqualTo: review.bookId)
          .where('userId', isEqualTo: review.userId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        await _reviews.doc(existing.docs.first.id).set(review.toMap(), SetOptions(merge: true));
      } else {
        await _reviews.add(review.toMap());
      }
    }
    await _recalculateRating(review.bookId);
  }

  Future<void> deleteReview(String reviewId, String bookId) async {
    await _reviews.doc(reviewId).delete();
    await _recalculateRating(bookId);
  }

  Future<void> toggleLikeReview(String reviewId, String userId, bool liked) {
    return _reviews.doc(reviewId).update({
      'likedBy': liked ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> _recalculateRating(String bookId) async {
    try {
      final snap = await _reviews.where('bookId', isEqualTo: bookId).get();
      if (snap.docs.isEmpty) {
        await _books.doc(bookId).update({'avgRating': 0.0, 'ratingCount': 0});
        return;
      }
      final ratings = snap.docs.map((d) => ((d.data()['rating'] ?? 0) as num).toDouble()).toList();
      final avg = ratings.reduce((a, b) => a + b) / ratings.length;
      await _books.doc(bookId).update({
        'avgRating': double.parse(avg.toStringAsFixed(1)),
        'ratingCount': ratings.length,
      });
    } catch (_) {}
  }

  // ── Orders ───────────────────────────────────────────────
  Future<String> placeOrder(BookOrder order) async {
    final ref = await _orders.add(order.toMap());
    for (final item in order.items) {
      await decrementStock(item.bookId, item.quantity);
    }
    // Increment coupon usedCount if applied
    if (order.couponCode != null && order.couponCode!.isNotEmpty) {
      try {
        await _db.collection(AppConstants.couponsCollection).doc(order.couponCode!.toUpperCase()).update({
          'usedCount': FieldValue.increment(1),
        });
      } catch (_) {}
    }
    // Award loyalty points: 10 pts per $1 spent
    final points = (order.total * 10).round();
    await awardLoyaltyPoints(order.userId, points);
    // Create order notification for user
    await addNotification(
      userId: order.userId,
      title: 'Order Placed Successfully!',
      body: 'Your order #${ref.id.substring(0, 8).toUpperCase()} has been placed and is being processed.',
      type: 'orderStatus',
      orderId: ref.id,
    );
    return ref.id;
  }

  Stream<List<BookOrder>> streamUserOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => BookOrder.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<BookOrder>> streamAllOrders() {
    return _orders.orderBy('createdAt', descending: true).snapshots().map(
        (s) => s.docs.map((d) => BookOrder.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status, {String? userId}) async {
    await _orders.doc(orderId).update({'status': status.name});
    if (userId != null) {
      await addNotification(
        userId: userId,
        title: 'Order Status Updated',
        body: 'Your order #${orderId.substring(0, 8).toUpperCase()} is now: ${status.label}',
        type: 'orderStatus',
        orderId: orderId,
      );
    }
  }

  Future<void> updateTrackingNumber(String orderId, String trackingNumber) {
    return _orders.doc(orderId).update({'trackingNumber': trackingNumber});
  }

  Future<void> cancelOrder(String orderId, String userId) async {
    await _orders.doc(orderId).update({'status': OrderStatus.cancelled.name});
    await addNotification(
      userId: userId,
      title: 'Order Cancelled',
      body: 'Your order #${orderId.substring(0, 8).toUpperCase()} has been cancelled.',
      type: 'orderStatus',
      orderId: orderId,
    );
  }

  // ── Users (Admin) ─────────────────────────────────────────
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<int> getUserOrderCount(String userId) async {
    final snap = await _orders.where('userId', isEqualTo: userId).get();
    return snap.size;
  }

  Future<void> banUser(String uid, bool isBanned) {
    return _db.collection(AppConstants.usersCollection).doc(uid).update({
      'isBanned': isBanned,
    });
  }

  // ── Loyalty Points ───────────────────────────────────────
  Future<void> awardLoyaltyPoints(String userId, int points) async {
    try {
      await _db.collection(AppConstants.usersCollection).doc(userId).update({
        'loyaltyPoints': FieldValue.increment(points),
      });
    } catch (_) {}
  }

  // ── Notifications ────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => {...d.data(), 'id': d.id}).toList();
          list.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });
          if (list.length > 50) {
            return list.sublist(0, 50);
          }
          return list;
        });
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? orderId,
  }) async {
    try {
      await _db.collection(AppConstants.notificationsCollection).add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> markNotificationRead(String notifId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final snap = await _db
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        if (doc.data()['isRead'] != true) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Coupons ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> validateCoupon(String code) async {
    final doc = await _db.collection(AppConstants.couponsCollection).doc(code.toUpperCase()).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) return null;
    if (data['isActive'] == false) return null;
    final usageLimit = data['usageLimit'] as int?;
    final usedCount = (data['usedCount'] ?? 0) as int;
    if (usageLimit != null && usedCount >= usageLimit) return null;
    return data;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCoupons() {
    return _db
        .collection(AppConstants.couponsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addOrUpdateCoupon(String code, Map<String, dynamic> data) {
    return _db
        .collection(AppConstants.couponsCollection)
        .doc(code.toUpperCase())
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteCoupon(String code) {
    return _db.collection(AppConstants.couponsCollection).doc(code.toUpperCase()).delete();
  }

  Future<void> toggleCouponActive(String code, bool isActive) {
    return _db
        .collection(AppConstants.couponsCollection)
        .doc(code.toUpperCase())
        .update({'isActive': isActive});
  }
}
