import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/book_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/book_cover_image.dart';
import '../../book_details/book_details_screen.dart';

/// A swipeable stack of featured book covers, styled like a deck of
/// magazine covers you can drag away one by one — replaces the old
/// auto-playing carousel with a hand-driven card stack.
class FeaturedSwipeStack extends StatefulWidget {
  final List<Book> books;
  const FeaturedSwipeStack({super.key, required this.books});

  @override
  State<FeaturedSwipeStack> createState() => _FeaturedSwipeStackState();
}

class _FeaturedSwipeStackState extends State<FeaturedSwipeStack>
    with SingleTickerProviderStateMixin {
  static const int _visibleDepth = 3;

  late final AnimationController _controller;
  late List<Book> _order;

  Offset _dragOffset = Offset.zero;
  int _exitDirection = 1; // 1 = right, -1 = left

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.plum,
    AppColors.coral,
    Color(0xFF242430),
    Color(0xFF5C1E38),
    Color(0xFFC02A50),
  ];

  @override
  void initState() {
    super.initState();
    _order = List.of(widget.books);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant FeaturedSwipeStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.books != widget.books) {
      _order = List.of(widget.books);
      _dragOffset = Offset.zero;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details, double width) {
    final threshold = width * 0.28;
    final flungFast = details.velocity.pixelsPerSecond.dx.abs() > 800;

    if (_dragOffset.dx.abs() > threshold || flungFast) {
      _exitDirection = _dragOffset.dx >= 0 ? 1 : -1;
      _animateOffscreen(width);
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    final start = _dragOffset;
    _controller.reset();
    final anim = Tween<Offset>(begin: start, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    void tick() => setState(() => _dragOffset = anim.value);
    anim.addListener(tick);
    _controller.forward().whenCompleteOrCancel(() {
      anim.removeListener(tick);
    });
  }

  void _animateOffscreen(double width) {
    final start = _dragOffset;
    final end = Offset(_exitDirection * (width + 200), start.dy * 0.4);
    _controller.reset();
    final anim = Tween<Offset>(begin: start, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    void tick() => setState(() => _dragOffset = anim.value);
    anim.addListener(tick);
    _controller.forward().whenCompleteOrCancel(() {
      anim.removeListener(tick);
      _cycleToNext();
    });
  }

  void _cycleToNext() {
    if (_order.isEmpty) return;
    setState(() {
      final front = _order.removeAt(0);
      _order.add(front);
      _dragOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_order.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: SizedBox(
        height: 300,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final depth = math.min(_visibleDepth, _order.length);
            final cards = <Widget>[];

            for (int d = depth - 1; d >= 0; d--) {
              final book = _order[d];
              final isFront = d == 0;

              if (isFront) {
                cards.add(_buildFrontCard(book, width));
              } else {
                cards.add(_buildBackCard(book, d));
              }
            }

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: cards,
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackCard(Book book, int depth) {
    final scale = 1 - (depth * 0.045);
    final yOffset = depth * 12.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translateByDouble(0.0, yOffset, 0.0, 1.0)
        ..scaleByDouble(scale, scale, 1.0, 1.0),
      transformAlignment: Alignment.center,
      child: Opacity(
        opacity: (1 - depth * 0.28).clamp(0.0, 1.0),
        child: _card(book, index: _originalIndex(book)),
      ),
    );
  }

  int _originalIndex(Book book) {
    final i = widget.books.indexWhere((b) => b.id == book.id);
    return i < 0 ? 0 : i;
  }

  Widget _buildFrontCard(Book book, double width) {
    final index = _originalIndex(book);
    final angle = (_dragOffset.dx / width) * 0.55; // radians, subtle tilt
    final dragFraction = (_dragOffset.dx / (width * 0.5)).clamp(-1.0, 1.0);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (details) => _onPanEnd(details, width),
      onTap: () {
        if (_dragOffset.distance < 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
          );
        }
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              _card(book, index: index),
              // Swipe direction hint badges
              if (dragFraction.abs() > 0.08)
                Positioned(
                  top: 18,
                  left: dragFraction > 0 ? null : 18,
                  right: dragFraction > 0 ? 18 : null,
                  child: Opacity(
                    opacity: dragFraction.abs().clamp(0.0, 1.0),
                    child: _hintBadge(dragFraction > 0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintBadge(bool liked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (liked ? AppColors.success : AppColors.textSecondary).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        liked ? 'NEXT' : 'SKIP',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _card(Book book, {required int index}) {
    final cardColor = _palette[index.abs() % _palette.length];
    final orderNumber = (index + 1).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: BookCoverImage(url: book.coverUrl, showSpineEffect: false),
            ),
          ),
          // Bottom solid scrim for text legibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),
          // Top-left tag
          Positioned(
            top: 16,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Text(
                'EDITOR\'S CHOICE',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          // Top-right bookmark
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 18),
            ),
          ),
          // Bottom text block
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  orderNumber,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w900,
                    fontSize: 46,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'by ${book.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '\$${book.effectivePrice.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Explore',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
