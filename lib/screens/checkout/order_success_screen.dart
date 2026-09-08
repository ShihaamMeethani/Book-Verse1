import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/order_model.dart';
import '../../services/book_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/book_cover_image.dart';
import '../../widgets/custom_button.dart';
import '../main_nav/main_navigation_screen.dart';
import '../orders/order_details_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final double total;
  final BookOrder? order;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
    this.order,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  late ConfettiController _confettiController;
  BookOrder? _order;
  bool _loadingOrder = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();

    _order = widget.order;
    if (_order == null) {
      _fetchOrder();
    }
  }

  Future<void> _fetchOrder() async {
    setState(() => _loadingOrder = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.ordersCollection)
          .doc(widget.orderId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _order = BookOrder.fromMap(doc.data()!, widget.orderId);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingOrder = false);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ZoomIn(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, size: 68, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeInUp(
                    child: Text(
                      'Order Confirmed!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Thank you! Your order has been placed successfully.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Order Summary Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _row('Order ID', '#${widget.orderId.substring(0, widget.orderId.length.clamp(0, 8))}'),
                          const SizedBox(height: 8),
                          _row('Amount Paid', '\$${widget.total.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Digital Book PDF Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _buildDigitalBookSection(dark),
                  ),

                  const SizedBox(height: 28),

                  // Actions
                  FadeInUp(
                    delay: const Duration(milliseconds: 250),
                    child: CustomButton(
                      label: 'Track Order',
                      icon: Icons.local_shipping_outlined,
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailsScreen(orderId: widget.orderId)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: CustomButton(
                      label: 'Continue Shopping',
                      outlined: true,
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                        (route) => false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 12,
                minBlastForce: 6,
                emissionFrequency: 0.06,
                numberOfParticles: 24,
                gravity: 0.25,
                colors: const [AppColors.primary, AppColors.accent, AppColors.success, Colors.pinkAccent],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalBookSection(bool dark) {
    if (_loadingOrder) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }

    final items = _order?.items ?? [];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Digital Book PDF is Ready!',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Read immediate sample excerpt & pass while you wait',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'INCLUDED',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark ? AppColors.surface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 60,
                        child: BookCoverImage(url: item.coverUrl),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Digital Companion & Excerpt PDF',
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.auto_stories_rounded, size: 16),
                        label: Text(
                          'Read PDF',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          if (_order != null) {
                            BookPdfService.instance.openBookPdf(
                              context,
                              order: _order!,
                              item: item,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dark ? Colors.white : AppColors.ink,
                          side: BorderSide(
                            color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.share_outlined, size: 16),
                        label: Text(
                          'Share / Save',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          if (_order != null) {
                            BookPdfService.instance.shareBookPdf(
                              order: _order!,
                              item: item,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13.5)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}
