import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/book_model.dart';
import '../../../providers/wishlist_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/book_cover_image.dart';
import '../../book_details/book_details_screen.dart';

/// A product card that presents a book as a closed, physical 3D book
/// (cover + visible page-block depth) rather than a flat rectangular
/// product tile. Tapping it opens [BookDetailsScreen] using a custom
/// "book opening" page transition.
class BookCard extends StatelessWidget {
  final Book book;
  final double? width;
  final double height;
  final int? rank;

  const BookCard({
    super.key,
    required this.book,
    this.width,
    this.height = 320,
    this.rank,
  });

  bool get _isFree => book.effectivePrice <= 0;

  void _openBook(BuildContext context) {
    Navigator.push(context, BookOpenRoute(book: book));
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final isWishlisted = wishlist.isWishlisted(book.id);
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Reserve space for the info block beneath the closed book so the
    // book itself can be given a generous, centered footprint.
    const infoHeight = 88.0;
    final bookAreaHeight = (height - infoHeight).clamp(120.0, 400.0);
    final naturalBookWidth = ClosedBook.totalWidth(bookAreaHeight);

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : double.infinity;
          final contentWidth = maxW < naturalBookWidth ? maxW : naturalBookWidth;

          return Center(
            child: SizedBox(
              width: contentWidth,
              height: height,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _openBook(context),
                          child: Hero(
                            tag: 'book-cover-${book.id}',
                            flightShuttleBuilder: (flightContext, animation, direction,
                                    fromContext, toContext) =>
                                Material(
                              type: MaterialType.transparency,
                              child: ClosedBook(book: book, height: bookAreaHeight),
                            ),
                            child: ClosedBook(book: book, height: bookAreaHeight),
                          ),
                        ),
                        if (rank != null || book.hasDiscount || book.isBestseller)
                          Positioned(
                            left: 0,
                            top: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (rank != null)
                                  _badge(
                                    '#$rank',
                                    bg: Colors.black.withValues(alpha: 0.78),
                                    fg: rank! <= 3 ? AppColors.gold : Colors.white,
                                    border: rank! <= 3 ? AppColors.gold : Colors.white24,
                                  ),
                                if (book.hasDiscount)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: _badge('-${book.discountPercent}%',
                                        bg: AppColors.primary, fg: Colors.white),
                                  )
                                else if (book.isBestseller)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: _badge('HOT', bg: AppColors.coral, fg: AppColors.ink),
                                  ),
                              ],
                            ),
                          ),
                        Positioned(
                          right: 2,
                          top: 4,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => wishlist.toggle(book),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    key: ValueKey(isWishlisted),
                                    color: isWishlisted ? AppColors.primary : Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: infoHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (book.genres.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    book.genres.first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                              const SizedBox(width: 2),
                              Text(
                                book.avgRating > 0 ? book.avgRating.toStringAsFixed(1) : 'New',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (_isFree)
                                _pill('FREE', AppColors.success)
                              else ...[
                                Text(
                                  '\$${book.effectivePrice.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                if (book.hasDiscount) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    '\$${book.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ],
                              ],
                              const Spacer(),
                              Icon(Icons.menu_book_rounded,
                                  size: 12, color: dark ? AppColors.textSecondary : AppColors.textMuted),
                              const SizedBox(width: 2),
                              Text(
                                'Open',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? AppColors.textSecondary : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _badge(String text, {required Color bg, required Color fg, Color? border}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: border != null ? Border.all(color: border, width: 1) : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: fg,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

/// A realistic closed 3D book: front cover, spine shadow and a fanned
/// page-block edge, with elevation shadow beneath.
class ClosedBook extends StatelessWidget {
  final Book book;
  final double height;

  const ClosedBook({super.key, required this.book, required this.height});

  static double totalWidth(double height) {
    final width = height * 0.68;
    final pageEdge = (width * 0.09).clamp(6.0, 16.0);
    return width + pageEdge;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final width = height * 0.68;
    final pageEdge = (width * 0.09).clamp(6.0, 16.0);

    return SizedBox(
      width: width + pageEdge,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Elevation / contact shadow.
          Positioned(
            left: pageEdge * 0.4,
            right: 0,
            bottom: -6,
            child: Container(
              height: height * 0.14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.5 : 0.22),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),
          // Fanned page-block edge (peeking from behind the cover, right side).
          Positioned(
            right: 0,
            top: 3,
            bottom: 3,
            child: Container(
              width: pageEdge + 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF4ECDD),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(color: const Color(0xFFE0D3B8), width: 0.6),
              ),
              child: CustomPaint(painter: _PageLinesPainter(), size: Size.infinite),
            ),
          ),
          // Front cover.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.55 : 0.28),
                    blurRadius: 16,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookCoverImage(url: book.coverUrl, showSpineEffect: false),
                  // Spine shading (left edge, gives roundness/depth).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: width * 0.14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Soft glossy sheen across the cover.
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: -width * 0.3,
                    width: width * 0.5,
                    child: Transform.rotate(
                      angle: -0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Thin border to keep edges crisp.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black.withValues(alpha: 0.12), width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD9C9A3)
      ..strokeWidth = 0.6;
    final count = (size.height / 4).floor();
    for (var i = 1; i < count; i++) {
      final y = i * 4.0;
      canvas.drawLine(Offset(1, y), Offset(size.width - 1, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom route that gives the feeling of a physical book opening: the
/// destination screen (which itself renders the closed → open book
/// animation via a Hero-carried cover) fades/tilts in with a subtle
/// perspective so there's no abrupt jump between the closed card and
/// the open-book screen.
class BookOpenRoute extends PageRouteBuilder<void> {
  final Book book;

  BookOpenRoute({required this.book})
      : super(
          // Quick hand-off transition — the book itself then plays its own
          // 650ms opening animation once this lands (see BookDetailsScreen).
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              BookDetailsScreen(book: book),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) {
                final t = curved.value;
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateX((1 - t) * -0.10)
                      ..scale(0.94 + 0.06 * t),
                    child: child,
                  ),
                );
              },
            );
          },
        );
}
