import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_shimmer.dart';
import '../search/search_screen.dart';
import '../notifications/notifications_screen.dart';
import 'widgets/book_card.dart';
import 'widgets/category_chip.dart';
import 'widgets/featured_swipe_stack.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final books = context.watch<BookProvider>();
    final profile = context.watch<AuthProvider>().profile;
    final isFiltering = books.selectedGenre != 'All';
    final filteredBooks = books.filteredAndSorted;
    final featured = books.allBooks.where((b) => b.isFeatured).take(6).toList();
    final bestsellers = books.allBooks.where((b) => b.isBestseller).take(8).toList();
    final newArrivals = books.allBooks.where((b) => b.isNewArrival).take(8).toList();
    final popular = books.filteredAndSorted.take(12).toList();
    final firstName = profile?.name.trim().split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: books.allBooks.isEmpty
            ? const BookGridShimmer(itemCount: 6)
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _header(
                      context,
                      firstName?.isNotEmpty == true ? firstName! : 'Reader',
                      profile?.photoUrl,
                      profile?.loyaltyPoints ?? 0,
                    ),
                  ),
                  SliverToBoxAdapter(child: _searchBar(context)),
                  SliverToBoxAdapter(child: _categoryBar(context, books)),

                  // When a specific category is tapped, show the filtered collection directly
                  if (isFiltering) ...[
                    SliverToBoxAdapter(
                      child: _categoryFilterHeader(context, books, filteredBooks.length),
                    ),
                    if (filteredBooks.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_stories_outlined,
                                size: 56,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No books found in "${books.selectedGenre}"',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Explore other categories or check back soon for new arrivals.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                onPressed: () => books.setGenre('All'),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Show All Books'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 320,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => BookCard(book: filteredBooks[i]),
                            childCount: filteredBooks.length,
                          ),
                        ),
                      ),
                  ] else ...[
                    // Default 'All' home layout with curated featured deck & shelves
                    if (featured.isNotEmpty)
                      SliverToBoxAdapter(child: _featured(context, featured)),
                    if (bestsellers.isNotEmpty)
                      _rankedSection(
                        context,
                        'Trending & Bestsellers',
                        'Top books readers are loving right now',
                        bestsellers,
                      ),
                    SliverToBoxAdapter(child: _dealsBanner(context)),
                    if (newArrivals.isNotEmpty)
                      _section(
                        context,
                        'Fresh Releases',
                        'Recently added to our curated shelves',
                        newArrivals,
                      ),
                    if (popular.isNotEmpty)
                      _section(
                        context,
                        'Popular in Catalog',
                        'Handpicked recommendations tailored for you',
                        popular,
                      ),
                    SliverToBoxAdapter(child: _literaryQuoteCard(context)),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
      ),
    );
  }

  Widget _header(BuildContext context, String firstName, String? photoUrl, int loyaltyPoints) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Drawer opener & avatar
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: dark ? AppColors.surfaceRaised : Colors.white,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'B',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getGreetingIcon(), size: 14, color: AppColors.gold),
                    const SizedBox(width: 5),
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: dark ? AppColors.textSecondary : AppColors.textDarkSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Loyalty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 16, color: AppColors.gold),
                const SizedBox(width: 5),
                Text(
                  '$loyaltyPoints pts',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.goldBright,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification Bell
          Builder(
            builder: (ctx) {
              final uid = ctx.read<AuthProvider>().profile?.uid;
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: uid != null ? FirestoreService().streamNotifications(uid) : null,
                builder: (ctx, snap) {
                  final unreadCount = snap.data?.where((n) => n['isRead'] == false).length ?? 0;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text('$unreadCount'),
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                        color: unreadCount > 0 ? AppColors.primary : null,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: dark ? AppColors.surface : AppColors.paperSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 22, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search titles, authors, genres...',
                  style: GoogleFonts.inter(
                    color: dark ? AppColors.textSecondary : AppColors.textDarkSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceRaised : AppColors.paperMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryBar(BuildContext context, BookProvider books) {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: books.genres
            .map((g) => CategoryChip(
                  label: g,
                  selected: books.selectedGenre == g,
                  onTap: () => books.setGenre(g),
                ))
            .toList(),
      ),
    );
  }

  Widget _featured(BuildContext context, List<Book> books) {
    return FeaturedSwipeStack(books: books);
  }

  Widget _rankedSection(BuildContext context, String title, String subtitle, List books) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(context, title, subtitle),
            SizedBox(
              height: 338,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => SizedBox(
                  width: 154,
                  child: BookCard(book: books[i], rank: i + 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String subtitle, List books) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(context, title, subtitle),
            SizedBox(
              height: 338,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => SizedBox(width: 154, child: BookCard(book: books[i])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dealsBanner(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SPECIAL OFFER',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('20% OFF', style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Use code READMORE20 at checkout',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy Code',
              icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'READMORE20'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Coupon code "READMORE20" copied! 🎉'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _literaryQuoteCard(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? AppColors.surface : AppColors.paperSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Daily Inspiration',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '"A reader lives a thousand lives before he dies. The man who never reads lives only one."',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: dark ? AppColors.textPrimary : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— George R.R. Martin',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryFilterHeader(BuildContext context, BookProvider books, int count) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                books.selectedGenre,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          // Sort option dropdown
          PopupMenuButton<SortOption>(
            initialValue: books.sortOption,
            onSelected: books.setSort,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _sortLabel(books.sortOption),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOption.popularity,
                child: Text('Most Popular'),
              ),
              const PopupMenuItem(
                value: SortOption.rating,
                child: Text('Highest Rated'),
              ),
              const PopupMenuItem(
                value: SortOption.priceLowHigh,
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: SortOption.priceHighLow,
                child: Text('Price: High to Low'),
              ),
              const PopupMenuItem(
                value: SortOption.newest,
                child: Text('Newest Releases'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.popularity:
        return 'Popular';
      case SortOption.rating:
        return 'Top Rated';
      case SortOption.priceLowHigh:
        return 'Price ↑';
      case SortOption.priceHighLow:
        return 'Price ↓';
      case SortOption.newest:
        return 'Newest';
    }
  }
}

