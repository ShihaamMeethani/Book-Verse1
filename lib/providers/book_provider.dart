import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/firestore_service.dart';

enum SortOption { popularity, priceLowHigh, priceHighLow, newest, rating }

/// Manages the book catalogue and prepares it for display.
/// Firestore supplies the live data, while filtering and sorting are handled locally.
class BookProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Book> _allBooks = [];
  String selectedGenre = 'All';
  SortOption sortOption = SortOption.popularity;

  // Standard genres are always available, even if no current book uses one.
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

    // Collect genres directly from the books stored in Firestore.
    for (final b in _allBooks) {
      for (final g in b.genres) {
        final clean = g.trim();
        if (clean.isNotEmpty) {
          dynamicGenres.add(clean);
        }
      }
    }

    // Combine database genres with the application's standard genre list.
    final set = {'All', ...dynamicGenres, ...defaultGenres.where((g) => g != 'All')};
    return set.toList();
  }

  BookProvider() {
    // Listen for catalogue changes so the UI updates automatically when
    // books are added, edited, or removed in Firestore.
    _service.streamAllBooks().listen((books) {
      _allBooks = books;
      notifyListeners();
    });
  }

  List<Book> get filteredAndSorted {
    // Start with every book or filter the catalogue by the selected genre.
    var list = selectedGenre == 'All'
        ? List<Book>.from(_allBooks)
        : _allBooks.where((b) {
            final target = selectedGenre.trim().toLowerCase();
            return b.genres.any((g) => g.trim().toLowerCase() == target);
          }).toList();

    // Apply the selected sorting rule after genre filtering.
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
    // Store the user's selected genre and refresh listening widgets.
    selectedGenre = genre;
    notifyListeners();
  }

  void setSort(SortOption option) {
    // Store the selected sorting method and refresh the catalogue view.
    sortOption = option;
    notifyListeners();
  }
}
