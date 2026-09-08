import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../services/book_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/book_cover_image.dart';
import '../../utils/constants.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  static const _steps = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  Future<void> _cancelOrder(BuildContext context, BookOrder order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Order', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be reversed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await FirestoreService().cancelOrder(order.id, order.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order has been cancelled.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.ordersCollection)
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final order = BookOrder.fromMap(snapshot.data!.data()!, orderId);
          final currentStep = order.status.step;
          final canCancel = order.status == OrderStatus.placed || order.status == OrderStatus.confirmed;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Header Summary Card ──────────────────────────────────
              FadeInDown(
                duration: const Duration(milliseconds: 350),
                child: Container(
                  padding: const EdgeInsets.all(18),
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
                          Text(
                            '#${order.id.substring(0, order.id.length.clamp(0, 8)).toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          _statusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Placed on ${DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt)}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.info),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tracking: ${order.trackingNumber}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Timeline Section ─────────────────────────────────────
              if (currentStep >= 0) ...[
                Text(
                  'Tracking Progress',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 18),
                _trackingTimeline(currentStep),
                const SizedBox(height: 24),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: AppColors.error, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This order was ${order.status.label.toLowerCase()}.',
                          style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Items Ordered ────────────────────────────────────────
              Text(
                'Items in Order (${order.items.length})',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 14),
              ...order.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 48,
                                height: 68,
                                child: BookCoverImage(url: item.coverUrl),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${item.quantity} · \$${item.price.toStringAsFixed(2)} each',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${item.subtotal.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 16, color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Digital Excerpt & Pass',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  icon: const Icon(Icons.auto_stories_rounded, size: 14),
                                  label: Text(
                                    'Read PDF',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () => BookPdfService.instance.openBookPdf(
                                    context,
                                    order: order,
                                    item: item,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 15),
                                  tooltip: 'Share / Save PDF',
                                  visualDensity: VisualDensity.compact,
                                  color: AppColors.textSecondary,
                                  onPressed: () => BookPdfService.instance.shareBookPdf(
                                    order: order,
                                    item: item,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 16),

              // ── Shipping & Payment Cards ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.location_on_outlined, 'Delivery Address'),
                    const SizedBox(height: 6),
                    Text(
                      order.shippingAddress.isNotEmpty ? order.shippingAddress : 'Not specified',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 24),
                    _sectionHeader(Icons.payment_outlined, 'Payment Method'),
                    const SizedBox(height: 6),
                    Text(
                      order.paymentMethod,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Payment Breakdown ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                ),
                child: Column(
                  children: [
                    _row('Subtotal', order.subtotal),
                    if (order.discount > 0)
                      _row('Coupon Discount (${order.couponCode ?? "PROMO"})', -order.discount,
                          color: AppColors.success),
                    _row('Shipping', order.shipping, isFree: order.shipping == 0),
                    const Divider(height: 20),
                    _row('Total Paid', order.total, bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Order Actions (Cancel / Support) ─────────────────────
              if (canCancel)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(
                    'Cancel Order',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _cancelOrder(context, order),
                ),
            ],
          );
        },
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }

  Widget _trackingTimeline(int currentStep) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final done = i <= currentStep;
        final isLast = i == _steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: done ? AppColors.primary : AppColors.surfaceDim,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : Icons.circle,
                      size: 14,
                      color: done ? Colors.white : Colors.transparent,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 3,
                        color: i < currentStep ? AppColors.primary : AppColors.surfaceDim,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _steps[i].label,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                      color: done ? null : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String label, double amount, {bool bold = false, bool isFree = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              fontSize: bold ? 14 : 13,
            ),
          ),
          Text(
            isFree ? 'FREE' : '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: bold ? 15 : 13,
              color: color ?? (bold ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}
