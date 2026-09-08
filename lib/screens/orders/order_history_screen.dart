import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import 'order_details_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'All'; // 'All', 'Active', 'Delivered', 'Cancelled'

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().profile?.uid;
    final service = FirestoreService();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: uid == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                // ── Filter Chips ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _chip('All'),
                      const SizedBox(width: 8),
                      _chip('Active'),
                      const SizedBox(width: 8),
                      _chip('Delivered'),
                      const SizedBox(width: 8),
                      _chip('Cancelled'),
                    ],
                  ),
                ),

                // ── Orders List ────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<BookOrder>>(
                    stream: service.streamUserOrders(uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      var orders = snapshot.data!;

                      if (_selectedFilter == 'Active') {
                        orders = orders.where((o) =>
                            o.status != OrderStatus.delivered &&
                            o.status != OrderStatus.cancelled &&
                            o.status != OrderStatus.returned).toList();
                      } else if (_selectedFilter == 'Delivered') {
                        orders = orders.where((o) => o.status == OrderStatus.delivered).toList();
                      } else if (_selectedFilter == 'Cancelled') {
                        orders = orders.where((o) =>
                            o.status == OrderStatus.cancelled ||
                            o.status == OrderStatus.returned).toList();
                      }

                      if (orders.isEmpty) {
                        return EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: _selectedFilter == 'All'
                              ? 'No Orders Placed Yet'
                              : 'No $_selectedFilter Orders',
                          subtitle: 'When you purchase books, your delivery status and tracking will appear here.',
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                        physics: const BouncingScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final order = orders[i];
                          return FadeInUp(
                            delay: Duration(milliseconds: i * 40),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: order.id)),
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 16),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '#${order.id.substring(0, order.id.length.clamp(0, 8)).toUpperCase()}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        _statusBadge(order.status),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt),
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '\$${order.total.toStringAsFixed(2)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _chip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.accentSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.delivered:
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        color = AppColors.error;
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        color = AppColors.info;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
