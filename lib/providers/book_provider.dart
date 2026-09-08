import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';

enum SortOption { popularity, priceLowHigh, priceHighLow, newest, rating }

/// Holds the catalog in memory for fast client-side filtering/sorting,
/// refreshed live via a Firestore stream.
class BookProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Book> _allBooks = [];
  String selectedGenre = 'All';
  SortOption sortOption = SortOption.popularity;

  static const List<String> defaultGenres = [
    'All',
    'Fiction',
    'Non-Fiction',
    'Fantasy',
    'Sci-Fi',
    'Mystery',
    'Romance',
    'Self-Help',
    'Business',
    'History',
    'Technology',
  ];

  List<Book> get allBooks => _allBooks;

  List<String> get genres {
    final dynamicGenres = <String>{};
    for (final b in _allBooks) {
      for (final g in b.genres) {
        final clean = g.trim();
        if (clean.isNotEmpty) {
          dynamicGenres.add(clean);
        }
      }
    }
    // Merge dynamic genres with default standard genres
    final set = {'All', ...dynamicGenres, ...defaultGenres.where((g) => g != 'All')};
    return set.toList();
  }

  BookProvider() {
    _service.streamAllBooks().listen((books) {
      _allBooks = books;
      notifyListeners();
    });
  }

  List<Book> get filteredAndSorted {
    var list = selectedGenre == 'All'
        ? List<Book>.from(_allBooks)
        : _allBooks.where((b) {
            final target = selectedGenre.trim().toLowerCase();
            return b.genres.any((g) => g.trim().toLowerCase() == target);
          }).toList();

    switch (sortOption) {
      case SortOption.popularity:
        list.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
      case SortOption.priceLowHigh:
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case SortOption.priceHighLow:
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case SortOption.newest:
        list.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case SortOption.rating:
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
    }
    return list;
  }

  void setGenre(String genre) {
    selectedGenre = genre;
    notifyListeners();
  }

  void setSort(SortOption option) {
    sortOption = option;
    notifyListeners();
  }
}
