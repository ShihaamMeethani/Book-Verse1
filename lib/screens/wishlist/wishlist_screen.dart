import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/book_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_button.dart';
import '../../theme/app_colors.dart';
import '../home/widgets/book_card.dart';
import '../search/search_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().profile?.uid;
    final wishlist = context.watch<WishlistProvider>();
    final wishlistIds = wishlist.bookIds;
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Books',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          if (wishlistIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${wishlistIds.length} Saved',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: uid == null || wishlistIds.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'Your Wishlist is Empty',
                      subtitle: 'Save compelling books you want to read or buy later by tapping the heart icon.',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: CustomButton(
                        label: 'Explore Books',
                        icon: Icons.travel_explore_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : StreamBuilder<List<Book>>(
              stream: service.streamAllBooks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final books = snapshot.data!.where((b) => wishlistIds.contains(b.id)).toList();
                if (books.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'Your Wishlist is Empty',
                      subtitle: 'Save compelling books you want to read or buy later by tapping the heart icon.',
                    ),
                  );
                }
                return FadeIn(
                  duration: const Duration(milliseconds: 300),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: books.length,
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 330,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, i) => BookCard(book: books[i]),
                  ),
                );
              },
            ),
    );
  }
}

