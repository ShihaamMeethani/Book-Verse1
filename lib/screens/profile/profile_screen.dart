import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../admin/admin_navigation_screen.dart';
import '../auth/login_screen.dart';
import '../orders/order_history_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of BookVerse?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loggingOut = true);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    try {
      await auth.logout();
    } catch (e) {
      if (mounted) {
        setState(() => _loggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not log out: $e'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.watch<CartProvider>();
    final profile = auth.profile;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final loyaltyPoints = profile?.loyaltyPoints ?? 0;
    final tier = loyaltyPoints >= 500 ? 'Platinum Bibliophile' : (loyaltyPoints >= 200 ? 'Gold Bibliophile' : 'Silver Reader');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Profile Header Card ─────────────────────────────────
          FadeInDown(
            duration: const Duration(milliseconds: 350),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: dark ? AppColors.surfaceRaised : Colors.white,
                      backgroundImage: profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null,
                      child: profile?.photoUrl == null
                          ? Text(
                              profile != null && profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : (profile?.email.isNotEmpty == true ? profile!.email[0].toUpperCase() : '?'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile != null
                            ? (profile.name.isNotEmpty ? profile.name : 'Reader')
                            : 'Welcome Reader',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?.email ?? 'Explore your personal library',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── VIP Loyalty Membership Card ─────────────────────────
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 60),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.workspace_premium_rounded, color: AppColors.goldBright, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            tier.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.goldBright,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'VIP PASS',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$loyaltyPoints Points Available',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Earn 10 points for every \$1 spent. Redeem for instant discounts.',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (loyaltyPoints % 200) / 200.0,
                      minHeight: 4,
                      backgroundColor: Colors.white12,
                      color: AppColors.goldBright,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Grouped Section: Library & Shopping ─────────────────
          _sectionCard(
            context,
            title: 'MY ACTIVITIES',
            tiles: [
              _menuTile(
                context,
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFF38BDF8),
                title: 'Order History & Tracking',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                ),
              ),
              _menuTile(
                context,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFF43F5E),
                title: 'Saved Wishlist',
                badgeCount: wishlist.bookIds.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                ),
              ),
              _menuTile(
                context,
                icon: Icons.shopping_bag_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Current Cart',
                badgeCount: cart.itemCount,
                onTap: () {
                  // Navigate to cart tab in main shell or push
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Grouped Section: Account & Settings ─────────────────
          _sectionCard(
            context,
            title: 'ACCOUNT & PREFERENCES',
            tiles: [
              _menuTile(
                context,
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFFFB923C),
                title: 'Shipping Addresses',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              _menuTile(
                context,
                icon: Icons.payment_rounded,
                iconColor: const Color(0xFFA855F7),
                title: 'Payment Methods',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Dark Obsidian Mode',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  value: theme.isDark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (_) => theme.toggle(),
                ),
              ),
              _menuTile(
                context,
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFF6366F1),
                title: 'Notifications & Alerts',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
              _menuTile(
                context,
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF0EA5E9),
                title: 'Help Center & FAQs',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                ),
              ),
              _menuTile(
                context,
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF64748B),
                title: 'About ${AppConstants.appName}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),

          if (auth.isAdmin) ...[
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'ADMINISTRATION',
              tiles: [
                _menuTile(
                  context,
                  icon: Icons.admin_panel_settings_rounded,
                  iconColor: AppColors.goldBright,
                  title: 'Admin Control Center',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNavigationScreen()),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // ── Log Out Button ──────────────────────────────────────
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                  )
                : const Icon(Icons.logout_rounded, size: 20),
            label: Text(
              'Sign Out of BookVerse',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            onPressed: _loggingOut ? null : _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> tiles}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
            ),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
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
          : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

