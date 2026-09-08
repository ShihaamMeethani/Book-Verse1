class CartItem {
  final String bookId;
  final String title;
  final String coverUrl;
  final double price;
  int quantity;

  CartItem({
    required this.bookId,
    required this.title,
    required this.coverUrl,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        bookId: map['bookId'],
        title: map['title'],
        coverUrl: map['coverUrl'],
        price: (map['price'] ?? 0).toDouble(),
        quantity: map['quantity'] ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'title': title,
        'coverUrl': coverUrl,
        'price': price,
        'quantity': quantity,
      };
}
