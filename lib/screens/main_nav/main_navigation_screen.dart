import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../home/home_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../chat/chat_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  void _onDrawerTabSelected(int tabIndex, bool isAdmin) {
    // Drawer navigation indexes: 0 Home, 1 Explore, 2 Cart, 3 Wishlist, 4 Profile.
    if (tabIndex >= 0 && tabIndex <= 4) {
      setState(() => _index = tabIndex);
    }
  }

  void _onDestinationSelected(int i) {
    if (_index != i) {
      HapticFeedback.lightImpact();
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final wishlistCount = context.watch<WishlistProvider>().bookIds.length;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final dark = Theme.of(context).brightness == Brightness.dark;

    const screens = [
      HomeScreen(),
      SearchScreen(),
      CartScreen(),
      WishlistScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      drawer: AppDrawer(
        onNavigateTab: (tabIndex) => _onDrawerTabSelected(tabIndex, isAdmin),
      ),
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bookverse_assistant_fab',
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        child: const Icon(Icons.support_agent_rounded, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.espresso : AppColors.paperSurface,
          border: Border(
            top: BorderSide(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.accentSoft,
          selectedIndex: _index,
          onDestinationSelected: _onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.travel_explore_rounded),
              selectedIcon: Icon(Icons.travel_explore_rounded, color: AppColors.primary),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$cartCount'),
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$cartCount'),
                isLabelVisible: cartCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.shopping_bag_rounded, color: AppColors.primary),
              ),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$wishlistCount'),
                isLabelVisible: wishlistCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.favorite_border_rounded),
              ),
              selectedIcon: Badge(
                label: Text('$wishlistCount'),
                isLabelVisible: wishlistCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.favorite_rounded, color: AppColors.primary),
              ),
              label: 'Wishlist',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

