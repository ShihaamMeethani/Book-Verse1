import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _faqFilter = '';

  final List<Map<String, dynamic>> _tutorials = [
    {
      'title': 'Discovering & Searching Books',
      'icon': Icons.explore_rounded,
      'color': const Color(0xFF6366F1),
      'steps': [
        'Open the Home tab to browse Featured Books, Bestsellers, and New Arrivals.',
        'Tap the Search icon or search bar to look up books by Title, Author, or Genre.',
        'Use the Sort & Filter button to organize results by Popularity, Price (Low to High / High to Low), Rating, or Newest Release.',
        'Tap on any author name or genre tag on a book page to instantly see all matching titles.',
      ],
    },
    {
      'title': 'Shopping Cart & Secure Checkout',
      'icon': Icons.shopping_cart_rounded,
      'color': const Color(0xFF10B981),
      'steps': [
        'Tap "Add to Cart" on any book details page to add the item to your basket.',
        'Go to the Cart screen to adjust item quantities or remove books.',
        'Enter valid promo coupons (e.g. "WELCOME10") at checkout to receive discounts.',
        'Select or add your preferred shipping address and payment method (Card, Wallet, or Cash on Delivery).',
        'Review the order summary and tap "Place Order" to confirm your purchase.',
      ],
    },
    {
      'title': 'Tracking Your Orders',
      'icon': Icons.local_shipping_rounded,
      'color': const Color(0xFFFB923C),
      'steps': [
        'Navigate to My Profile > My Orders to view your full purchase history.',
        'Tap on any order to open the live Order Details and Delivery Tracking screen.',
        'View the 6-stage visual timeline: Placed → Confirmed → Packed → Shipped → Out for Delivery → Delivered.',
        'You can cancel an order while it is in "Placed" or "Confirmed" status directly from the order screen.',
      ],
    },
    {
      'title': 'Ratings, Reviews & Community',
      'icon': Icons.star_rounded,
      'color': const Color(0xFFF59E0B),
      'steps': [
        'Open any book details page and scroll down to the "Reader Reviews" section.',
        'Tap "Write Review" to rate the book (1 to 5 stars) and write your feedback.',
        'You can edit or delete your existing review anytime.',
        'Tap the Thumbs Up icon on reviews written by other readers to like helpful reviews.',
      ],
    },
    {
      'title': 'Wishlist & Reading Collection',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFEC4899),
      'steps': [
        'Tap the Heart icon on any book card or details page to add it to your Wishlist.',
        'Access your saved books anytime from the Wishlist tab on the main navigation bar.',
        'Move wishlisted items directly to your shopping cart when you are ready to buy.',
      ],
    },
    {
      'title': 'Administrator Portal (Staff)',
      'icon': Icons.admin_panel_settings_rounded,
      'color': const Color(0xFF8B5CF6),
      'steps': [
        'Authorized admin accounts have direct access to the "Admin Control Center" from their Profile.',
        'Manage Catalog: Add new books with cover image uploads via Cloudinary, edit descriptions, stock, and pricing.',
        'Manage Orders: Review all customer orders and advance shipping status updates in real-time.',
        'Manage Users: View registered user accounts, loyalty points, and account statuses.',
      ],
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'category': 'Orders & Shipping',
      'q': 'How do I track the delivery status of my order?',
      'a': 'Go to Profile > Order History and select the order you want to inspect. The Order Details screen shows a live visual tracking timeline with real-time status updates from order placement to delivery.',
    },
    {
      'category': 'Orders & Shipping',
      'q': 'Can I cancel an order after placing it?',
      'a': 'Yes. Orders can be cancelled while in "Placed" or "Confirmed" status. Open the Order Details screen and tap the "Cancel Order" button.',
    },
    {
      'category': 'Account & Profile',
      'q': 'How do I add or update my shipping address?',
      'a': 'Go to Profile > Shipping Addresses (or tap Edit Profile). You can add multiple addresses, set a default delivery address, or remove outdated addresses anytime.',
    },
    {
      'category': 'Account & Profile',
      'q': 'Can I sign in using my Google account?',
      'a': 'Yes. BookVerse supports instant and secure Google Sign-In on both Login and Register screens in addition to standard email and password authentication.',
    },
    {
      'category': 'Account & Profile',
      'q': 'How do I reset my password if I forget it?',
      'a': 'On the Sign In screen, tap "Forgot Password?" and enter your registered email address. We will send a secure password reset link to your inbox.',
    },
    {
      'category': 'Payments & Discounts',
      'q': 'What payment methods are accepted?',
      'a': 'BookVerse supports saved Credit/Debit cards, Digital Wallets, and Cash on Delivery (COD). All sensitive payment credentials adhere to strict security best practices.',
    },
    {
      'category': 'Payments & Discounts',
      'q': 'How do loyalty points work?',
      'a': 'Every completed order earns you 10 loyalty points for every \$1 spent. Accumulating points unlocks Silver, Gold, and Platinum Bibliophile tiers with exclusive benefits.',
    },
    {
      'category': 'Reviews & Community',
      'q': 'Can I like reviews written by other readers?',
      'a': 'Yes! When viewing book reviews, simply tap the thumbs up button to like any review. The live like count updates in real time.',
    },
    {
      'category': 'Wishlist & Cart',
      'q': 'How do I save a book for later purchase?',
      'a': 'Tap the heart icon on any book card or details page. Your saved books will be stored securely in your Wishlist tab.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final filteredFaqs = _faqs.where((f) {
      if (_faqFilter.isEmpty) return true;
      final q = _faqFilter.toLowerCase();
      return f['q']!.toLowerCase().contains(q) ||
          f['a']!.toLowerCase().contains(q) ||
          f['category']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Guide & FAQs',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded, size: 20), text: 'User Guide & Tutorials'),
            Tab(icon: Icon(Icons.help_outline_rounded, size: 20), text: 'Frequently Asked Questions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: User Guide & Tutorials ────────────────────────
          ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to ${AppConstants.appName}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Learn how to discover books, manage orders, review titles, and navigate all features.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ..._tutorials.map((tutorial) => _buildTutorialCard(context, tutorial, dark)),
              const SizedBox(height: 24),
              // Support contact card
              _buildSupportContactCard(context, dark),
            ],
          ),

          // ── Tab 2: FAQs ──────────────────────────────────────────
          ListView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            children: [
              // Search FAQ bar
              Container(
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _faqFilter = v.trim()),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search help topics and FAQs...',
                    hintStyle: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _faqFilter = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (filteredFaqs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No answers found for "$_faqFilter"',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try searching with different keywords or browse the guide.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredFaqs.map((faq) => _buildFaqCard(context, faq, dark)),
              const SizedBox(height: 24),
              _buildSupportContactCard(context, dark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(BuildContext context, Map<String, dynamic> tutorial, bool dark) {
    final steps = tutorial['steps'] as List<String>;
    final color = tutorial['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tutorial['icon'] as IconData, color: color, size: 22),
          ),
          title: Text(
            tutorial['title'] as String,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Text(
            '${steps.length} step tutorial',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final text = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$idx',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: GoogleFonts.inter(fontSize: 13.5, height: 1.45),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, Map<String, String> faq, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 22),
          title: Text(
            faq['q']!,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              faq['category']!,
              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq['a']!,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.55,
                  color: dark ? Colors.white70 : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportContactCard(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need More Help?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Our customer support and developer assistance team is available 24/7.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Email Support'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Support email: support@bookverse.app'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Live Inquiries'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Live assistance representative available 9 AM - 8 PM EST.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
