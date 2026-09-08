import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../utils/constants.dart';

/// Syncs a user's wishlist (a simple array of bookIds) with Firestore
/// under users/{uid}/wishlist/{bookId}, so it's available across devices.
class WishlistProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _uid;
  final Set<String> _bookIds = {};

  Set<String> get bookIds => _bookIds;

  void attachUser(String? uid) {
    _uid = uid;
    _bookIds.clear();
    if (uid == null) {
      notifyListeners();
      return;
    }
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
    final ref = _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .collection(AppConstants.wishlistCollection)
        .doc(book.id);
    if (_bookIds.contains(book.id)) {
      await ref.delete();
    } else {
      await ref.set({
        'title': book.title,
        'coverUrl': book.coverUrl,
        'price': book.effectivePrice,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
