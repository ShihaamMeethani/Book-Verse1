import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/book_cover_image.dart';
import '../../widgets/empty_state.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final _service = FirestoreService();
  int _refreshKey = 0;
  String _searchQuery = '';
  OrderStatus? _selectedStatusFilter; // null means 'All'

  void _reload() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Manage Orders',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by order ID or address...',
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

          // ── Filter Chips ─────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip('All', _selectedStatusFilter == null, () {
                  setState(() => _selectedStatusFilter = null);
                }),
                ...OrderStatus.values.map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _filterChip(status.label, isSelected, () {
                      setState(() => _selectedStatusFilter = status);
                    }),
                  );
                }),
              ],
            ),
          ),

          // ── Orders Stream ────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<BookOrder>>(
              key: ValueKey(_refreshKey),
              stream: _service.streamAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load orders',
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

                var orders = snapshot.data!;

                // Filter by status
                if (_selectedStatusFilter != null) {
                  orders = orders.where((o) => o.status == _selectedStatusFilter).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((o) {
                    final idMatch = o.id.toLowerCase().contains(_searchQuery);
                    final addrMatch = o.shippingAddress.toLowerCase().contains(_searchQuery);
                    final payMatch = o.paymentMethod.toLowerCase().contains(_searchQuery);
                    return idMatch || addrMatch || payMatch;
                  }).toList();
                }

                if (orders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _selectedStatusFilter != null
                        ? 'No ${_selectedStatusFilter!.label} Orders'
                        : 'No Orders Found',
                    subtitle: 'Fulfillment requests will appear here when placed.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: 25 * (i.clamp(0, 10))),
                      child: _AdminOrderTile(order: order, service: _service, dark: dark),
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

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.accentSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
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
    );
  }
}

class _AdminOrderTile extends StatefulWidget {
  final BookOrder order;
  final FirestoreService service;
  final bool dark;

  const _AdminOrderTile({
    required this.order,
    required this.service,
    required this.dark,
  });

  @override
  State<_AdminOrderTile> createState() => _AdminOrderTileState();
}

class _AdminOrderTileState extends State<_AdminOrderTile> {
  late OrderStatus _status;
  bool _updating = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
  }

  @override
  void didUpdateWidget(covariant _AdminOrderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_updating && oldWidget.order.status != widget.order.status) {
      _status = widget.order.status;
    }
  }

  Future<void> _changeStatus(OrderStatus? status) async {
    if (status == null || status == _status) return;
    final prev = _status;
    setState(() {
      _status = status;
      _updating = true;
    });

    try {
      await widget.service.updateOrderStatus(
        widget.order.id,
        status,
        userId: widget.order.userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${status.label}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _promptTrackingNumber() async {
    final controller = TextEditingController(text: widget.order.trackingNumber ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tracking Number', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. TRK-84920489',
            labelText: 'Courier Tracking ID',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await widget.service.updateTrackingNumber(widget.order.id, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tracking number saved!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save tracking: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.returned:
        return AppColors.error;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final color = _statusColor(_status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.dark ? AppColors.surfaceBorder : AppColors.paperBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.id.substring(0, order.id.length.clamp(0, 8)).toUpperCase()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (_updating)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          _status.label,
                          style: GoogleFonts.plusJakartaSans(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy · h:mm a').format(order.createdAt),
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} item(s) · Total: \$${order.total.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Row(
                        children: [
                          Text(
                            _expanded ? 'Hide details' : 'View items',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expanded items list & customer details
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer & Shipping',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.shippingAddress.isNotEmpty ? order.shippingAddress : 'No address provided',
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Payment: ${order.paymentMethod}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tracking: ${order.trackingNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Ordered Items',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 34,
                                height: 48,
                                child: BookCoverImage(url: item.coverUrl),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12.5),
                                  ),
                                  Text(
                                    'Qty: ${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${item.subtotal.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],

          const Divider(height: 1),

          // Actions & Status Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<OrderStatus>(
                    initialValue: _status,
                    isDense: true,
                    decoration: InputDecoration(
                      labelText: 'Update Status',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: OrderStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: _updating ? null : _changeStatus,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primary),
                  tooltip: 'Set Tracking #',
                  onPressed: _promptTrackingNumber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
