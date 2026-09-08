import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'manage_books_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_users_screen.dart';
import 'manage_coupons_screen.dart';

/// Dedicated navigation shell for admin users.
/// Completely separate from the user-facing MainNavigationScreen —
/// admins never see Cart, Wishlist, or user Home tabs.
class AdminNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const AdminNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  late int _index;

  static const List<Widget> _screens = [
    AdminDashboardScreen(),
    ManageBooksScreen(),
    ManageOrdersScreen(),
    ManageUsersScreen(),
    ManageCouponsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  void _onDestinationSelected(int i) {
    if (_index != i) {
      HapticFeedback.lightImpact();
      setState(() => _index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BookVerse Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (profile != null)
                  Text(
                    profile.email,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 13, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  'ADMIN',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books_rounded, color: AppColors.primary),
              label: 'Books',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer_rounded, color: AppColors.primary),
              label: 'Coupons',
            ),
          ],
        ),
      ),
    );
  }
}
