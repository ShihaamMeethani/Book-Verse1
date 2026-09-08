import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../screens/search/search_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/about_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_navigation_screen.dart';

class AppDrawer extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const AppDrawer({super.key, this.onNavigateTab});

  void _goToTab(BuildContext context, int tabIndex) {
    Navigator.pop(context); // close drawer
    if (onNavigateTab != null) {
      onNavigateTab!(tabIndex);
    }
  }

  void _showCouponsSheet(BuildContext context) {
    final coupons = [
      {'code': 'WELCOME10', 'discount': '10% OFF', 'desc': 'Special welcome gift for new readers'},
      {'code': 'READMORE20', 'discount': '20% OFF', 'desc': 'Valid on orders over \$40'},
      {'code': 'BOOKWORM', 'discount': '15% OFF', 'desc': 'Curated bestseller shelf discount'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Active Promo Codes', style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...coupons.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? AppColors.surfaceRaised
                        : AppColors.paperSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c['code']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 1.2,
                                    color: AppColors.goldBright,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c['discount']!,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['desc']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(ctx).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: c['code']!));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('Copied "${c['code']}" to clipboard!'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.gold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('Copy', style: TextStyle(color: AppColors.goldBright, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final theme = context.watch<ThemeProvider>();
    final profile = auth.profile;
    final isAdmin = auth.isAdmin;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: BoxDecoration(
              color: dark ? AppColors.surface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.goldBright.withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppColors.goldBright),
                            SizedBox(width: 4),
                            Text('ADMIN', style: TextStyle(color: AppColors.goldBright, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: dark ? AppColors.surfaceRaised : Colors.white,
                        backgroundImage: profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null,
                        child: profile?.photoUrl == null
                            ? Text(
                                profile != null && profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : (profile?.email.isNotEmpty == true ? profile!.email[0].toUpperCase() : 'B'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.name.isNotEmpty == true ? profile!.name : (auth.status == AuthStatus.authenticated ? 'Reader' : 'Welcome to BookVerse'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.email.isNotEmpty == true
                                ? profile!.email
                                : (auth.status == AuthStatus.authenticated ? 'Member' : 'Explore great books'),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 14, color: AppColors.goldBright),
                            const SizedBox(width: 5),
                            Text(
                              '${profile.loyaltyPoints} Points',
                              style: const TextStyle(color: AppColors.goldBright, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        },
                        child: const Row(
                          children: [
                            Text('Edit Profile', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Scrollable Menu ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              children: [
                _drawerTile(
                  context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () => _goToTab(context, 0),
                ),
                _drawerTile(
                  context,
                  icon: Icons.travel_explore_rounded,
                  label: 'Search & Explore',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.favorite_rounded,
                  label: 'Wishlist',
                  badgeCount: wishlist.bookIds.length,
                  onTap: () => _goToTab(context, 3),
                ),
                _drawerTile(
                  context,
                  icon: Icons.shopping_cart_rounded,
                  label: 'My Cart',
                  badgeCount: cart.itemCount,
                  onTap: () => _goToTab(context, 2),
                ),
                _drawerTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  label: 'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.local_offer_outlined,
                  label: 'Promotions & Coupons',
                  badgeLabel: 'DEALS',
                  onTap: () => _showCouponsSheet(context),
                ),

                const Divider(height: 24, thickness: 1),

                // ── Admin Section ───────────────────────────────
                if (isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      'ADMINISTRATION',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                        color: dark ? AppColors.goldBright : AppColors.primary,
                      ),
                    ),
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Control Center',
                    badgeLabel: 'ADMIN',
                    color: AppColors.goldBright,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNavigationScreen()));
                    },
                  ),
                  const Divider(height: 24, thickness: 1),
                ],

                // ── Settings & Theme ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'PREFERENCES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    secondary: Icon(
                      theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    value: theme.isDark,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) => theme.toggle(),
                  ),
                ),
                _drawerTile(
                  context,
                  icon: Icons.person_rounded,
                  label: 'Account Settings',
                  onTap: () {
                    Navigator.pop(context);
                    if (auth.status == AuthStatus.authenticated) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
                _drawerTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'About ${AppConstants.appName}',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
              ],
            ),
          ),

          // ── Footer (Sign In / Sign Out) ─────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                if (auth.status == AuthStatus.authenticated) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to sign out of BookVerse?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          if (context.mounted) Navigator.pop(context);
                          await auth.logout();
                        }
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
    String? badgeLabel,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: badgeCount != null && badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            : (badgeLabel != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.goldBright.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        color: AppColors.goldBright,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary)),
        onTap: onTap,
      ),
    );
  }
}

