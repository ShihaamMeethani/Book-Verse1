import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../profile/edit_profile_screen.dart';
import 'order_success_screen.dart';

enum PaymentMethod { card, cashOnDelivery, wallet }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _service = FirestoreService();
  Address? _selectedAddress;
  SavedPaymentMethod? _selectedSavedMethod;
  PaymentMethod _paymentMethod = PaymentMethod.card;
  bool _placing = false;

  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          content: Text('Please select or add a shipping address'),
        ),
      );
      return;
    }
    setState(() => _placing = true);

    final paymentLabel = _selectedSavedMethod?.label ?? _paymentLabel(_paymentMethod);

    final order = BookOrder(
      id: '',
      userId: auth.profile!.uid,
      items: cart.items,
      subtotal: cart.subtotal,
      shipping: cart.shipping,
      discount: cart.discountAmount,
      total: cart.total,
      couponCode: cart.appliedCouponCode,
      shippingAddress: _selectedAddress!.formatted,
      paymentMethod: paymentLabel,
      createdAt: DateTime.now(),
    );

    final orderId = await _service.placeOrder(order);
    await NotificationService().showInstant(
      title: 'Order Confirmed! 🎉',
      body: 'Your order #$orderId has been placed successfully.',
    );
    final placedOrder = BookOrder(
      id: orderId,
      userId: order.userId,
      items: order.items,
      subtotal: order.subtotal,
      shipping: order.shipping,
      discount: order.discount,
      total: order.total,
      couponCode: order.couponCode,
      shippingAddress: order.shippingAddress,
      paymentMethod: order.paymentMethod,
      status: order.status,
      createdAt: order.createdAt,
      trackingNumber: order.trackingNumber,
    );

    cart.clear();

    if (!mounted) return;
    setState(() => _placing = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: orderId,
          total: order.total,
          order: placedOrder,
        ),
      ),
    );
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return 'Credit / Debit Card';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final addresses = auth.profile?.addresses ?? [];
    _selectedAddress ??= addresses.isNotEmpty
        ? addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first)
        : null;

    final savedMethods = auth.profile?.paymentMethods ?? [];
    if (savedMethods.isNotEmpty && _selectedSavedMethod == null) {
      _selectedSavedMethod = savedMethods.firstWhere((p) => p.isDefault, orElse: () => savedMethods.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Step 1: Shipping Address ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepHeader('1', 'Shipping Address'),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: Text(
                  addresses.isEmpty ? 'Add' : 'Manage',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (addresses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded, color: AppColors.goldBright),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No saved shipping address. Tap Manage above to add your delivery address.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            ...addresses.map((a) {
              final selected = _selectedAddress == a;
              return GestureDetector(
                onTap: () => setState(() => _selectedAddress = a),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : (dark ? AppColors.surfaceRaised : AppColors.paperSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : (dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: selected ? AppColors.primary : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  a.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (a.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.primary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.formatted,
                              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // ── Step 2: Payment Method ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stepHeader('2', 'Payment Method'),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
                icon: const Icon(Icons.credit_card_rounded, size: 16),
                label: Text(
                  'Manage',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (savedMethods.isNotEmpty) ...[
            ...savedMethods.map((p) => _savedPaymentTile(p)),
          ] else ...[
            _paymentTile(PaymentMethod.card, Icons.credit_card_rounded, 'Credit / Debit Card'),
            _paymentTile(PaymentMethod.cashOnDelivery, Icons.payments_outlined, 'Cash on Delivery (COD)'),
            _paymentTile(PaymentMethod.wallet, Icons.account_balance_wallet_outlined, 'Digital Wallet / Apple Pay'),
          ],

          const SizedBox(height: 24),

          // ── Step 3: Order Summary ───────────────────────────────
          _stepHeader('3', 'Order Summary'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
              ),
            ),
            child: Column(
              children: [
                _row('Items (${cart.itemCount})', '\$${cart.subtotal.toStringAsFixed(2)}'),
                if (cart.discountAmount > 0)
                  _row('Promo Discount', '-\$${cart.discountAmount.toStringAsFixed(2)}', color: AppColors.success),
                _row('Standard Shipping', cart.shipping == 0 ? 'FREE' : '\$${cart.shipping.toStringAsFixed(2)}'),
                Divider(height: 20, color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                _row('Grand Total', '\$${cart.total.toStringAsFixed(2)}', bold: true),
              ],
            ),
          ),
          const SizedBox(height: 28),
          CustomButton(
            label: 'Confirm Order · \$${cart.total.toStringAsFixed(2)}',
            isLoading: _placing,
            onPressed: auth.profile == null ? null : _placeOrder,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _stepHeader(String stepNum, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: Center(
            child: Text(
              stepNum,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _savedPaymentTile(SavedPaymentMethod method) {
    final selected = _selectedSavedMethod?.id == method.id;
    final dark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    switch (method.type) {
      case 'wallet':
        icon = Icons.account_balance_wallet_outlined;
        break;
      case 'cod':
        icon = Icons.payments_outlined;
        break;
      case 'card':
      default:
        icon = Icons.credit_card_rounded;
    }
    return GestureDetector(
      onTap: () => setState(() => _selectedSavedMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (dark ? AppColors.surfaceRaised : AppColors.paperSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : (dark ? AppColors.surfaceBorder : AppColors.paperBorder),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.label,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  if (method.expiry != null && method.expiry!.isNotEmpty)
                    Text(
                      'Expires ${method.expiry}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(PaymentMethod method, IconData icon, String label) {
    final selected = _paymentMethod == method;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : (dark ? AppColors.surfaceRaised : AppColors.paperSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : (dark ? AppColors.surfaceBorder : AppColors.paperBorder),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              fontSize: bold ? 15 : 13.5,
              color: bold ? null : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
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

