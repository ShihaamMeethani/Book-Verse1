import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/book_cover_image.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();
  final _service = FirestoreService();
  String? _couponError;
  bool _validating = false;

  Future<void> _applyCoupon(CartProvider cart) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _validating = true;
      _couponError = null;
    });
    final data = await _service.validateCoupon(code);
    setState(() => _validating = false);
    if (data == null) {
      setState(() => _couponError = 'Invalid or expired coupon code');
      return;
    }
    cart.applyCoupon(code.toUpperCase(), (data['discountPercent'] ?? 0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    const freeShippingThreshold = 40.0;
    final progressToFreeShipping = (cart.subtotal / freeShippingThreshold).clamp(0.0, 1.0);
    final neededForFreeShipping = (freeShippingThreshold - cart.subtotal).clamp(0.0, freeShippingThreshold);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.itemCount} items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your Cart is Empty',
                      subtitle: 'Looks like you haven\'t added any books to your cart yet.',
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: CustomButton(
                        label: 'Start Exploring',
                        icon: Icons.travel_explore_rounded,
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Free Shipping Progress Tracker
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            progressToFreeShipping >= 1.0
                                ? Icons.check_circle_rounded
                                : Icons.local_shipping_rounded,
                            color: progressToFreeShipping >= 1.0 ? AppColors.success : AppColors.goldBright,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              progressToFreeShipping >= 1.0
                                  ? 'Unlocked FREE Standard Shipping! 🎉'
                                  : 'Add \$${neededForFreeShipping.toStringAsFixed(2)} more for FREE Shipping',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: progressToFreeShipping >= 1.0 ? AppColors.success : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressToFreeShipping,
                          minHeight: 5,
                          backgroundColor: dark ? AppColors.surfaceBorder : AppColors.paperMuted,
                          color: progressToFreeShipping >= 1.0 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return FadeInUp(
                        delay: Duration(milliseconds: i * 50),
                        child: Slidable(
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => cart.removeBook(item.bookId),
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_outline_rounded,
                                label: 'Remove',
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 62,
                                    height: 90,
                                    child: BookCoverImage(url: item.coverUrl, showSpineEffect: true),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '\$${item.price.toStringAsFixed(2)}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: dark ? AppColors.surface : AppColors.paperMuted,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _qtyButton(Icons.remove_rounded, () =>
                                          cart.updateQuantity(item.bookId, item.quantity - 1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          '${item.quantity}',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                                        ),
                                      ),
                                      _qtyButton(Icons.add_rounded, () =>
                                          cart.updateQuantity(item.bookId, item.quantity + 1)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.surface : AppColors.paperSurface,
                    border: Border(
                      top: BorderSide(
                        color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
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
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                style: GoogleFonts.inter(fontSize: 13.5),
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon code',
                                  errorText: _couponError,
                                  prefixIcon: const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.goldBright),
                                  suffixIcon: cart.appliedCouponCode != null
                                      ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _validating ? null : () => _applyCoupon(cart),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _validating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                        if (cart.appliedCouponCode != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.celebration_rounded, size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Text(
                                  'Coupon ${cart.appliedCouponCode} applied! (${cart.couponDiscountPercent.toInt()}% off)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _summaryRow('Subtotal', cart.subtotal),
                        if (cart.discountAmount > 0)
                          _summaryRow('Promo Discount', -cart.discountAmount, color: AppColors.success),
                        _summaryRow('Shipping', cart.shipping, isFree: cart.shipping == 0),
                        Divider(height: 20, color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                        _summaryRow('Total Price', cart.total, bold: true),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: 'Proceed to Checkout · \$${cart.total.toStringAsFixed(2)}',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool bold = false, bool isFree = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 16 : 13.5,
              color: bold ? null : AppColors.textSecondary,
            ),
          ),
          Text(
            isFree ? 'FREE' : '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: bold ? 18 : 14,
              color: color ?? (bold ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}

