import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a book and the information displayed throughout the app.
class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final List<String> genres;
  final double price;
  final double? discountPrice;
  final double avgRating;
  final int ratingCount;
  final int stock;
  final bool isBestseller;
  final bool isNewArrival;
  final bool isFeatured;
  final DateTime releaseDate;
  final int pages;
  final String language;
  final String isbn;
  final int soldCount;
  final String? previewUrl; // Sample pages / PDF.

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.genres,
    required this.price,
    this.discountPrice,
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.stock = 0,
    this.isBestseller = false,
    this.isNewArrival = false,
    this.isFeatured = false,
    required this.releaseDate,
    this.pages = 0,
    this.language = 'English',
    this.isbn = '',
    this.soldCount = 0,
    this.previewUrl,
  });

  // These getters keep price, discount, and stock logic in one place.
  double get effectivePrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  int get discountPercent =>
      hasDiscount ? (((price - discountPrice!) / price) * 100).round() : 0;
  bool get inStock => stock > 0;

  factory Book.fromMap(Map<String, dynamic> map, String id) {
    // Convert Firestore data into a strongly typed Book object.
    return Book(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      description: map['description'] ?? '',
      coverUrl: (map['coverUrl'] ?? map['imageUrl'] ?? map['coverImageUrl'] ?? '').toString(),
      genres: List<String>.from(map['genres'] ?? []),
      price: (map['price'] ?? 0).toDouble(),
      discountPrice: map['discountPrice'] != null ? (map['discountPrice']).toDouble() : null,
      avgRating: (map['avgRating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      stock: map['stock'] ?? 0,
      isBestseller: map['isBestseller'] ?? false,
      isNewArrival: map['isNewArrival'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      releaseDate: (map['releaseDate'] is Timestamp)
          ? (map['releaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      pages: map['pages'] ?? 0,
      language: map['language'] ?? 'English',
      isbn: map['isbn'] ?? '',
      soldCount: map['soldCount'] ?? 0,
      previewUrl: map['previewUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    // Convert the Book object back into a Firestore-compatible map.
    return {
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'genres': genres,
      'price': price,
      'discountPrice': discountPrice,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
      'stock': stock,
      'isBestseller': isBestseller,
      'isNewArrival': isNewArrival,
      'isFeatured': isFeatured,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'pages': pages,
      'language': language,
      'isbn': isbn,
      'soldCount': soldCount,
      'previewUrl': previewUrl,
    };
  }
}
