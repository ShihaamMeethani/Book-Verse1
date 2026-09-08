import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/book_model.dart';
import '../../models/review_model.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'pdf_viewer_screen.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../home/widgets/book_card.dart';
import '../cart/cart_screen.dart';
import '../auth/login_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreService();
  final int _quantity = 1;
  bool _cartActionLoading = false;
  bool _closing = false;
  bool _openScheduled = false;

  late final AnimationController _openCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 500),
  );

  bool get _isFree => widget.book.effectivePrice <= 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_openScheduled) return;
    _openScheduled = true;
    final route = ModalRoute.of(context);
    final routeAnim = route?.animation;
    if (routeAnim == null || routeAnim.isCompleted) {
      // No incoming route transition (or it's already done) — open right away.
      _openCtrl.forward();
    } else {
      void listener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          if (mounted) _openCtrl.forward();
          routeAnim.removeStatusListener(listener);
        }
      }

      routeAnim.addStatusListener(listener);
      // Safety net in case the listener is somehow never fired.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _openCtrl.value == 0) _openCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    super.dispose();
  }

  Future<void> _closeBook() async {
    if (_closing) return;
    setState(() => _closing = true);
    await _openCtrl.reverse();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addToCartAndOpen() async {
    if (_cartActionLoading) return;
    final cart = context.read<CartProvider>();
    final alreadyInCart = cart.items.any((item) => item.bookId == widget.book.id);
    if (alreadyInCart) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
      return;
    }

    setState(() => _cartActionLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    cart.addBook(widget.book, quantity: _quantity);
    await NotificationService().showInstant(
      title: 'Added to Cart 🛒',
      body: '${widget.book.title} added to your cart.',
    );

    if (!mounted) return;
    setState(() => _cartActionLoading = false);
  }

  void _readOnline() {
    final url = widget.book.previewUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No readable file is available for this book yet.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(title: widget.book.title, pdfUrl: url),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
                title: const Text('Share this book'),
                onTap: () {
                  Navigator.pop(ctx);
                  Share.share('Check out "${widget.book.title}" by ${widget.book.author} on BookVerse!');
                },
              ),
              ListTile(
                leading: const Icon(Icons.rate_review_outlined, color: AppColors.primary),
                title: const Text('Write a review'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReviewSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.textSecondary),
                title: const Text('Report an issue'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Thanks — our team will take a look.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewSheet(BuildContext context, [Review? existingReview]) {
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.profile?.uid;

    if (currentUserId == null || currentUserId.isEmpty) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Sign In to Review', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Please sign in to share your thoughts and rate "${widget.book.title}".',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Sign In / Register',
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
      return;
    }

    final commentController = TextEditingController(text: existingReview?.comment ?? '');
    double rating = existingReview?.rating ?? 5.0;
    bool isSubmitting = false;

    String getRatingLabel(double r) {
      if (r >= 5) return '⭐⭐⭐⭐⭐ Exceptional — Must read!';
      if (r >= 4) return '⭐⭐⭐⭐ Great — Really enjoyed it!';
      if (r >= 3) return '⭐⭐⭐ Good — Worth checking out.';
      if (r >= 2) return '⭐⭐ Fair — Had some flaws.';
      return '⭐ Poor — Did not enjoy it.';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingReview != null ? 'Edit Your Review' : 'Rate this book',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getRatingLabel(rating),
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: isSubmitting ? null : () => setModalState(() => rating = starIndex.toDouble()),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            starIndex <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.gold,
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts about this book (optional)...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Theme.of(ctx).brightness == Brightness.dark
                          ? AppColors.surfaceRaised
                          : AppColors.paperSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.surfaceBorder.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: existingReview != null ? 'Update Review' : 'Submit Review',
                    isLoading: isSubmitting,
                    onPressed: () async {
                      setModalState(() => isSubmitting = true);
                      try {
                        final userName = auth.profile?.name.isNotEmpty == true
                            ? auth.profile!.name
                            : (auth.profile?.email.split('@').first ?? 'Reader');
                        final photoUrl = auth.profile?.photoUrl;

                        final rev = Review(
                          id: existingReview?.id ?? '',
                          bookId: widget.book.id,
                          userId: currentUserId,
                          userName: userName,
                          userPhotoUrl: photoUrl,
                          rating: rating,
                          comment: commentController.text.trim(),
                          createdAt: DateTime.now(),
                          likedBy: existingReview?.likedBy ?? [],
                        );

                        await _service.addReview(rev);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.success,
                              content: Text(existingReview != null
                                  ? 'Review updated successfully! ⭐'
                                  : 'Thank you! Your review has been submitted. ⭐'),
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.error,
                              content: Text('Failed to submit review: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final wishlist = context.watch<WishlistProvider>();
    final auth = context.watch<AuthProvider>();
    final inCart = context.watch<CartProvider>().items.any((item) => item.bookId == book.id);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeBook();
      },
      child: Scaffold(
        backgroundColor: dark ? AppColors.ink : AppColors.paper,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Row(
                    children: [
                      _circleButton(context, Icons.arrow_back_ios_new_rounded, _closeBook),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _OpenBookSpread(
                    book: book,
                    controller: _openCtrl,
                    dark: dark,
                    isFree: _isFree,
                    inCart: inCart,
                    cartLoading: _cartActionLoading,
                    onAddToCart: book.inStock
                        ? (inCart
                            ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))
                            : _addToCartAndOpen)
                        : null,
                    onReadOnline: _readOnline,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _controlsRow(context, wishlist, book, inCart),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isFree && book.previewUrl != null) ...[
                        FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: CustomButton(
                            label: 'Read Free Sample Chapter',
                            icon: Icons.menu_book_rounded,
                            outlined: true,
                            onPressed: _readOnline,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Reviews Section Header & Stream
                      StreamBuilder<List<Review>>(
                        stream: _service.streamReviews(book.id),
                        builder: (context, snapshot) {
                          final reviews = snapshot.data ?? [];
                          final myReview = (auth.profile != null)
                              ? reviews.cast<Review?>().firstWhere(
                                  (r) => r?.userId == auth.profile!.uid,
                                  orElse: () => null,
                                )
                              : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reader Reviews',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  if (reviews.isNotEmpty)
                                    Text(
                                      '(${reviews.length})',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Review action prompt card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.rate_review_outlined, color: AppColors.gold),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        myReview != null
                                            ? 'You rated this book ${myReview.rating}★'
                                            : 'Have you read this book?',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _showReviewSheet(context, myReview),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: Text(
                                        myReview != null ? 'Edit' : 'Write Review',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (snapshot.hasError) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: AppColors.error),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Could not load live reviews (${snapshot.error}).',
                                            style: const TextStyle(fontSize: 13, color: AppColors.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else if (!snapshot.hasData) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              ] else if (reviews.isEmpty) ...[
                                const EmptyState(
                                  icon: Icons.rate_review_outlined,
                                  title: 'No reviews yet',
                                  subtitle: 'Be the first reader to share your thoughts!',
                                ),
                              ] else ...[
                                Column(
                                  children: reviews.map((r) => _reviewTile(context, r, auth)).toList(),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Readers Also Enjoyed',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<Book>>(
                        future: _service.recommendationsFor(book),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final recs = snapshot.data!;
                          return SizedBox(
                            height: 338,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: recs.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 14),
                              itemBuilder: (context, i) => SizedBox(width: 154, child: BookCard(book: recs[i])),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlsRow(BuildContext context, WishlistProvider wishlist, Book book, bool inCart) {
    final isWishlisted = wishlist.isWishlisted(book.id);
    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      delay: const Duration(milliseconds: 150),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionCircle(
              context,
              icon: Icons.more_horiz_rounded,
              onTap: () => _showMoreSheet(context),
            ),
            const SizedBox(width: 14),
            _actionCircle(
              context,
              icon: Icons.ios_share_rounded,
              onTap: () => Share.share('Check out "${book.title}" by ${book.author} on BookVerse!'),
            ),
            const SizedBox(width: 14),
            _actionCircle(
              context,
              icon: isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              iconColor: isWishlisted ? AppColors.primary : null,
              onTap: () => wishlist.toggle(book),
            ),
            const SizedBox(width: 14),
            _actionCircle(
              context,
              icon: Icons.menu_book_rounded,
              filled: true,
              onTap: _closeBook,
            ),
            const SizedBox(width: 14),
            _actionCircle(
              context,
              icon: inCart ? Icons.shopping_cart_rounded : Icons.add_shopping_cart_rounded,
              onTap: book.inStock
                  ? (inCart
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))
                      : _addToCartAndOpen)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCircle(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
    bool filled = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = filled
        ? AppColors.primary
        : (dark ? AppColors.surfaceRaised : AppColors.paperSurface);
    final fg = filled ? Colors.white : (iconColor ?? (dark ? AppColors.textPrimary : AppColors.textDark));
    return Material(
      color: bg,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
              width: filled ? 0 : 1,
            ),
          ),
          child: Icon(icon, size: 20, color: onTap == null ? fg.withValues(alpha: 0.35) : fg),
        ),
      ),
    );
  }

  Widget _circleButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap),
    );
  }

  Widget _reviewTile(BuildContext context, Review r, AuthProvider auth) {
    final currentUid = auth.profile?.uid;
    final liked = currentUid != null && r.likedBy.contains(currentUid);
    final isAuthor = currentUid != null && currentUid == r.userId;
    final canDelete = isAuthor || auth.isAdmin;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentSoft,
                backgroundImage: r.userPhotoUrl != null ? NetworkImage(r.userPhotoUrl!) : null,
                child: r.userPhotoUrl == null
                    ? Text(
                        r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.userName,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        RatingStars(rating: r.rating, size: 12, showValue: false),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd().format(r.createdAt),
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAuthor)
                IconButton(
                  tooltip: 'Edit review',
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                  onPressed: () => _showReviewSheet(context, r),
                ),
              if (canDelete)
                IconButton(
                  tooltip: 'Delete review',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Review'),
                        content: const Text('Are you sure you want to delete this review?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete',
                                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _service.deleteReview(r.id, widget.book.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Review deleted.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              IconButton(
                icon: Icon(
                  liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                  size: 18,
                  color: liked ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () {
                  if (currentUid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Please sign in to like reviews.'),
                      ),
                    );
                    return;
                  }
                  _service.toggleLikeReview(r.id, currentUid, !liked);
                },
              ),
              Text('${r.likeCount}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          if (r.comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Text(
                r.comment,
                style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
              ),
            ),
        ],
      ),
    );
  }
}

/// The animated closed → open physical book. A [Hero] carries the closed
/// cover in from the tapped [BookCard]; once that flight lands, [controller]
/// drives a perspective "cover swings open" animation that reveals the
/// two-page spread (left = cover/identity page, right = details & CTA).
class _OpenBookSpread extends StatelessWidget {
  final Book book;
  final AnimationController controller;
  final bool dark;
  final bool isFree;
  final bool inCart;
  final bool cartLoading;
  final VoidCallback? onAddToCart;
  final VoidCallback onReadOnline;

  const _OpenBookSpread({
    required this.book,
    required this.controller,
    required this.dark,
    required this.isFree,
    required this.inCart,
    required this.cartLoading,
    required this.onAddToCart,
    required this.onReadOnline,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final spreadWidth = maxW > 620 ? 580.0 : (maxW - 20).clamp(280.0, 580.0);
        final bookHeight = spreadWidth * 0.72;
        const spineWidth = 14.0;
        final pageWidth = (spreadWidth - spineWidth) / 2;
        final pageColor = dark ? AppColors.surfaceRaised : AppColors.paperSurface;

        return SizedBox(
          height: bookHeight + 30,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(controller.value);
              // Smoothly transition center: closed book is centered at t=0, open spread is centered at t=1
              final centerOffsetX = (1.0 - t) * (-pageWidth / 2 - spineWidth / 2);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Contact shadow that expands as the book opens
                  Positioned(
                    bottom: 2,
                    child: Transform.translate(
                      offset: Offset(centerOffsetX, 0),
                      child: Container(
                        width: pageWidth * (1.0 + 0.95 * t) + spineWidth * t,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: dark ? 0.60 : 0.28),
                              blurRadius: 28,
                              spreadRadius: -3,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Physical 3D Book Spread
                  Transform.translate(
                    offset: Offset(centerOffsetX, 0),
                    child: SizedBox(
                      width: spreadWidth,
                      height: bookHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Base Left Page (flat underneath)
                          if (t >= 0.5)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: _leftPage(context, pageWidth, bookHeight, pageColor),
                            ),
                          // Center Spine
                          Positioned(
                            left: pageWidth,
                            top: 0,
                            child: _centerSpine(spineWidth, bookHeight),
                          ),
                          // Right Page (unveiled as front cover swings open)
                          Positioned(
                            left: pageWidth + spineWidth,
                            top: 0,
                            child: _rightPage(context, pageWidth, bookHeight, pageColor, t),
                          ),
                          // 3D Flipping Leaf (Front Cover 0° -> 90°, then Left Page 90° -> 0°)
                          if (t < 0.5)
                            Positioned(
                              left: pageWidth + spineWidth,
                              top: 0,
                              child: _flippingLeaf(context, pageWidth, bookHeight, t, pageColor),
                            )
                          else if (t < 0.999)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: _flippingLeaf(context, pageWidth, bookHeight, t, pageColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _flippingLeaf(
    BuildContext context,
    double pageWidth,
    double pageHeight,
    double t,
    Color pageColor,
  ) {
    if (t >= 0.999) return const SizedBox.shrink();

    if (t < 0.5) {
      // Phase 1: Front cover lifting off the right page (0° to -90°)
      final progress = t * 2.0;
      final angle = -progress * (math.pi / 2.0);

      return Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(angle),
        child: SizedBox(
          width: pageWidth,
          height: pageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ClosedBook.totalWidth(pageHeight),
                  height: pageHeight,
                  child: Hero(
                    tag: 'book-cover-${book.id}',
                    child: ClosedBook(book: book, height: pageHeight),
                  ),
                ),
              ),
              // Dynamic specular sheen as cover turns towards light
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    color: Colors.white.withValues(
                      alpha: 0.12 * math.sin(progress * math.pi),
                    ),
                  ),
                ),
              ),
              // Spine shadow gradient on inner turning edge
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.40 * (1 - progress)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Phase 2: Inside Left page swinging down to flat (+90° down to 0°)
      final progress = (t - 0.5) * 2.0;
      final angle = (1.0 - progress) * (math.pi / 2.0);

      return Transform(
        alignment: Alignment.centerRight,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(angle),
        child: Stack(
          children: [
            _leftPage(context, pageWidth, pageHeight, pageColor),
            // Ambient shadow on page face that clears as it settles flat
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    color: Colors.black.withValues(
                      alpha: 0.28 * (1.0 - progress),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _centerSpine(double spineWidth, double pageHeight) {
    return Container(
      width: spineWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: dark ? 0.48 : 0.26),
            Colors.black.withValues(alpha: 0.03),
            Colors.black.withValues(alpha: dark ? 0.48 : 0.26),
          ],
        ),
      ),
    );
  }

  Widget _leftPage(BuildContext context, double pageWidth, double pageHeight, Color pageColor) {
    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(-4, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (book.genres.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: book.genres.take(2).map((g) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          g,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  book.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'by ${book.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RatingStars(rating: book.avgRating, size: 11, showValue: true),
                    if (book.ratingCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${book.ratingCount})',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _specRow(
                        Icons.menu_book_rounded,
                        'Pages',
                        book.pages > 0 ? '${book.pages}p' : 'N/A',
                        dark,
                      ),
                      _specRow(
                        Icons.language_rounded,
                        'Language',
                        book.language,
                      dark,
                    ),
                    _specRow(
                      Icons.calendar_today_rounded,
                      'Published',
                      DateFormat.yMMM().format(book.releaseDate),
                      dark,
                    ),
                    _specRow(
                      Icons.inventory_2_outlined,
                      'Status',
                      book.inStock ? 'In Stock' : 'Out of Stock',
                      dark,
                      statusColor: book.inStock ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Gutter shadow along right edge (spine fold)
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 18,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withValues(alpha: dark ? 0.35 : 0.15),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _rightPage(
    BuildContext context,
    double pageWidth,
    double pageHeight,
    Color pageColor,
    double t,
  ) {
    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'SYNOPSIS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      book.description.isEmpty
                          ? 'No synopsis available for this title yet.'
                          : book.description,
                      style: GoogleFonts.inter(
                        fontSize: 10.8,
                        height: 1.5,
                        color: dark ? AppColors.textPrimary : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FREE · ONLINE',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.success,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Text(
                        '\$${book.effectivePrice.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    if (!isFree && book.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Text(
                        '\$${book.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: isFree
                      ? CustomButton(
                          label: 'Read Online',
                          icon: Icons.auto_stories_rounded,
                          height: 38,
                          fontSize: 11.5,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: onReadOnline,
                        )
                      : CustomButton(
                          label: !book.inStock ? 'Out of Stock' : (inCart ? 'View Cart' : 'Add to Cart'),
                          icon: inCart ? Icons.shopping_cart_rounded : Icons.add_shopping_cart_rounded,
                          height: 38,
                          fontSize: 11.5,
                          borderRadius: BorderRadius.circular(10),
                          isLoading: cartLoading,
                          onPressed: onAddToCart,
                        ),
                ),
              ],
            ),
          ),
          // Gutter shadow along left edge (spine fold)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 18,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: dark ? 0.35 : 0.15),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dynamic shadow cast by the lifting front cover
          if (t < 0.65)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    color: Colors.black.withValues(
                      alpha: (0.32 * (1.0 - (t / 0.65))).clamp(0.0, 0.32),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _specRow(IconData icon, String label, String value, bool dark, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: statusColor ?? AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: statusColor ?? (dark ? AppColors.textPrimary : AppColors.textDark),
            ),
          ),
        ),
      ],
    );
  }
}
