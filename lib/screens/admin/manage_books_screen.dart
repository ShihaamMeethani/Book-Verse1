import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/book_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/book_cover_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import 'add_edit_book_screen.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

enum _BookSortOption { titleAsc, priceAsc, priceDesc, stockAsc, ratingDesc }

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  final _service = FirestoreService();
  int _refreshKey = 0;
  String _searchQuery = '';
  _BookSortOption _sort = _BookSortOption.titleAsc;

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Manage Catalog',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Book',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditBookScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search books by title, author, ISBN...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                  ),
                ),
              ),
            ),
          ),

          // ── Sort & Genre Filter Row ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Sort Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_BookSortOption>(
                        value: _sort,
                        isExpanded: true,
                        icon: const Icon(Icons.sort_rounded, size: 18),
                        style: GoogleFonts.inter(fontSize: 12.5, color: dark ? Colors.white : Colors.black),
                        items: const [
                          DropdownMenuItem(value: _BookSortOption.titleAsc, child: Text('Sort: Title (A-Z)')),
                          DropdownMenuItem(value: _BookSortOption.priceAsc, child: Text('Sort: Price (Low → High)')),
                          DropdownMenuItem(value: _BookSortOption.priceDesc, child: Text('Sort: Price (High → Low)')),
                          DropdownMenuItem(value: _BookSortOption.stockAsc, child: Text('Sort: Stock (Low → High)')),
                          DropdownMenuItem(value: _BookSortOption.ratingDesc, child: Text('Sort: Highest Rated')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _sort = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Books List Stream ────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Book>>(
              key: ValueKey(_refreshKey),
              stream: _service.streamAllBooks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Catalog Loading Issue',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) return const BookGridShimmer();

                var books = snapshot.data!;

                // Filter search
                if (_searchQuery.isNotEmpty) {
                  books = books.where((b) {
                    final titleMatch = b.title.toLowerCase().contains(_searchQuery);
                    final authorMatch = b.author.toLowerCase().contains(_searchQuery);
                    final isbnMatch = b.isbn.toLowerCase().contains(_searchQuery);
                    final genreMatch = b.genres.any((g) => g.toLowerCase().contains(_searchQuery));
                    return titleMatch || authorMatch || isbnMatch || genreMatch;
                  }).toList();
                }

                // Sort
                switch (_sort) {
                  case _BookSortOption.titleAsc:
                    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                    break;
                  case _BookSortOption.priceAsc:
                    books.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
                    break;
                  case _BookSortOption.priceDesc:
                    books.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
                    break;
                  case _BookSortOption.stockAsc:
                    books.sort((a, b) => a.stock.compareTo(b.stock));
                    break;
                  case _BookSortOption.ratingDesc:
                    books.sort((a, b) => b.avgRating.compareTo(a.avgRating));
                    break;
                }

                if (books.isEmpty) {
                  return EmptyState(
                    icon: Icons.library_books_outlined,
                    title: 'No Books Found',
                    subtitle: 'Tap below to add a book to the store catalog.',
                    actionLabel: 'Add Book',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddEditBookScreen()),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  physics: const BouncingScrollPhysics(),
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final book = books[i];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: 25 * (i.clamp(0, 10))),
                      child: _BookRow(book: book, service: _service, dark: dark),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  final Book book;
  final FirestoreService service;
  final bool dark;

  const _BookRow({
    required this.book,
    required this.service,
    required this.dark,
  });

  Widget _stockBadge(int stock) {
    if (stock <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('OUT OF STOCK', style: TextStyle(color: AppColors.error, fontSize: 9.5, fontWeight: FontWeight.w800)),
      );
    }
    if (stock <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('LOW: $stock', style: const TextStyle(color: AppColors.warning, fontSize: 9.5, fontWeight: FontWeight.w800)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$stock IN STOCK', style: const TextStyle(color: AppColors.success, fontSize: 9.5, fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Book', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('Remove "${book.title}" from the catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await service.deleteBook(book.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" removed'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 76,
              child: BookCoverImage(url: book.coverUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '\$${book.effectivePrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.primary,
                      ),
                    ),
                    if (book.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\$${book.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    _stockBadge(book.stock),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.goldBright),
                    const SizedBox(width: 3),
                    Text(
                      '${book.avgRating} (${book.ratingCount})',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${book.soldCount} sold',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditBookScreen(book: book)),
                ),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: () => _delete(context),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
