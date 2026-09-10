import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../utils/constants.dart';

/// Keeps the signed-in user's wishlist synchronized with Firestore.
class WishlistProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _uid;
  final Set<String> _bookIds = {};

  Set<String> get bookIds => _bookIds;

  void attachUser(String? uid) {
    // Reset the local wishlist whenever the signed-in account changes.
    _uid = uid;
    _bookIds.clear();

    if (uid == null) {
      notifyListeners();
      return;
    }

    // Listen to this user's wishlist so changes made in Firestore are reflected
    // in the UI automatically.
    _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.wishlistCollection)
        .snapshots()
        .listen((snap) {
      _bookIds
        ..clear()
        ..addAll(snap.docs.map((d) => d.id));
      notifyListeners();
    });
  }

  bool isWishlisted(String bookId) => _bookIds.contains(bookId);

  Future<void> toggle(Book book) async {
    if (_uid == null) return;

    // Each wishlist entry uses the book ID as its document ID, making it easy
    // to determine whether the book is already saved.
    final ref = _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.wishlistCollection)
        .doc(book.id);

    if (_bookIds.contains(book.id)) {
      // Remove the book when it is already in the wishlist.
      await ref.delete();
    } else {
      // Store enough book information to represent the saved wishlist item.
      await ref.set({
        'title': book.title,
        'coverUrl': book.coverUrl,
        'price': book.effectivePrice,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
