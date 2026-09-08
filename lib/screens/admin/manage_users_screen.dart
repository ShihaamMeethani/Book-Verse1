import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import 'package:provider/provider.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _service = FirestoreService();
  String _searchQuery = '';
  int _refreshKey = 0;

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().profile?.uid;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Manage Users',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _reload),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_refreshKey),
              stream: _service.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load users',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                var users = snapshot.data!.docs
                    .map((d) => AppUser.fromMap(d.data(), d.id))
                    .where((u) => u.uid != currentUid) // exclude self
                    .toList();

                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  users = users
                      .where((u) =>
                          u.name.toLowerCase().contains(_searchQuery) ||
                          u.email.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (users.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No Users Found',
                    subtitle: 'Registered readers will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, i) {
                    final user = users[i];
                    final isBanned = user.isBanned;
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: 30 * (i.clamp(0, 10))),
                      child: _UserTile(
                        user: user,
                        isBanned: isBanned,
                        dark: dark,
                        service: _service,
                        onAction: _reload,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isBanned;
  final bool dark;
  final FirestoreService service;
  final VoidCallback onAction;

  const _UserTile({
    required this.user,
    required this.isBanned,
    required this.dark,
    required this.service,
    required this.onAction,
  });

  void _showUserDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user, isBanned: isBanned, service: service),
    );
  }

  Future<void> _toggleBan(BuildContext context) async {
    final action = isBanned ? 'Unban' : 'Ban';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action User', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text(
          isBanned
              ? 'Restore access for "${user.name}"? They will be able to sign in again.'
              : 'Ban "${user.name}"? They will no longer be able to access their account.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await service.banUser(user.uid, !isBanned);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBanned ? 'User unbanned successfully' : 'User banned successfully'),
            backgroundColor: isBanned ? AppColors.success : AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text(
          'Permanently delete "${user.name}"\'s Firestore profile? This cannot be undone.\n\n'
          'Note: Their Firebase Auth login will remain active until deleted server-side.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User profile deleted'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBanned
              ? AppColors.error.withValues(alpha: 0.35)
              : (dark ? AppColors.surfaceBorder : AppColors.paperBorder),
        ),
      ),
      child: ListTile(
        onTap: () => _showUserDetails(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accentSoft,
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16,
                      ),
                    )
                  : null,
            ),
            if (isBanned)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: const Icon(Icons.block_rounded, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name.isEmpty ? 'Unnamed User' : user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ADMIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.gold,
                  ),
                ),
              ),
            ],
            if (isBanned) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'BANNED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'ban') _toggleBan(context);
            if (action == 'delete') _deleteUser(context);
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'ban',
              child: Row(
                children: [
                  Icon(
                    isBanned ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                    size: 16,
                    color: isBanned ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(isBanned ? 'Unban User' : 'Ban User'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete Profile', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailSheet extends StatelessWidget {
  final AppUser user;
  final bool isBanned;
  final FirestoreService service;

  const _UserDetailSheet({
    required this.user,
    required this.isBanned,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Avatar + name
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.accentSoft,
              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.name.isEmpty ? 'Unnamed User' : user.name,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(user.email, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.isAdmin) _badge('ADMIN', AppColors.gold),
                if (isBanned) _badge('BANNED', AppColors.error),
                if (!user.isAdmin && !isBanned) _badge('ACTIVE', AppColors.success),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _infoTile(Icons.calendar_today_outlined, 'Joined',
                      DateFormat('MMM d, yyyy').format(user.createdAt)),
                  _infoTile(Icons.phone_outlined, 'Phone', user.phone ?? 'Not provided'),
                  _infoTile(Icons.star_rounded, 'Loyalty Points', '${user.loyaltyPoints} pts'),
                  _infoTile(
                      Icons.location_on_outlined,
                      'Saved Addresses',
                      '${user.addresses.length} address(es)'),
                  _infoTile(
                      Icons.credit_card_outlined,
                      'Payment Methods',
                      '${user.paymentMethods.length} saved'),
                  // Live order count
                  FutureBuilder<int>(
                    future: service.getUserOrderCount(user.uid),
                    builder: (ctx, snap) => _infoTile(
                      Icons.receipt_long_outlined,
                      'Total Orders',
                      snap.hasData ? '${snap.data} orders' : '...',
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
