import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../orders/order_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = FirestoreService();

  IconData _iconForType(String type) {
    switch (type) {
      case 'orderStatus':
        return Icons.local_shipping_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'orderStatus':
        return AppColors.info;
      case 'promotion':
        return AppColors.goldBright;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.profile?.uid;
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const EmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'Sign In Required',
          subtitle: 'Please sign in to view your order and account notifications.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _service.markAllNotificationsRead(uid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.streamNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load notifications: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error)),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final notifs = snapshot.data!;

          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No Notifications',
              subtitle: 'You are all caught up! Order status updates and special deals will appear here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              final id = n['id'] as String;
              final title = n['title'] as String? ?? '';
              final body = n['body'] as String? ?? '';
              final type = n['type'] as String? ?? 'general';
              final isRead = n['isRead'] as bool? ?? false;
              final orderId = n['orderId'] as String?;
              final createdAtRaw = n['createdAt'];
              final createdAt = (createdAtRaw is Timestamp) ? createdAtRaw.toDate() : DateTime.now();

              final iconColor = _colorForType(type);

              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: 20 * (i.clamp(0, 10))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isRead
                        ? (dark ? AppColors.surfaceRaised : AppColors.paperSurface)
                        : (dark
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.accentSoft.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? (dark ? AppColors.surfaceBorder : AppColors.paperBorder)
                          : AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_iconForType(type), color: iconColor, size: 22),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isRead ? AppColors.textSecondary : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('MMM d · h:mm a').format(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (!isRead) {
                        await _service.markNotificationRead(id);
                      }
                      if (orderId != null && orderId.isNotEmpty && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailsScreen(orderId: orderId),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
