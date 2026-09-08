import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

class ManageCouponsScreen extends StatefulWidget {
  const ManageCouponsScreen({super.key});

  @override
  State<ManageCouponsScreen> createState() => _ManageCouponsScreenState();
}

class _ManageCouponsScreenState extends State<ManageCouponsScreen> {
  final _service = FirestoreService();

  void _showCouponDialog({
    Map<String, dynamic>? existing,
    String? existingCode,
  }) {
    final codeCtrl = TextEditingController(
      text: existingCode ?? '',
    );

    final descCtrl = TextEditingController(
      text: existing?['description'] ?? '',
    );

    final valueCtrl = TextEditingController(
      text: existing != null ? '${existing['value']}' : '',
    );

    final minOrderCtrl = TextEditingController(
      text: existing?['minOrderAmount'] != null
          ? '${existing!['minOrderAmount']}'
          : '',
    );

    final usageLimitCtrl = TextEditingController(
      text: existing?['usageLimit'] != null
          ? '${existing!['usageLimit']}'
          : '',
    );

    DateTime? expiresAt = (existing?['expiresAt'] is Timestamp)
        ? (existing!['expiresAt'] as Timestamp).toDate()
        : null;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            existingCode != null ? 'Edit Coupon' : 'Create Coupon',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coupon code
                  TextFormField(
                    controller: codeCtrl,
                    enabled: existingCode == null,
                    decoration: const InputDecoration(
                      labelText: 'Coupon Code *',
                      hintText: 'e.g. SAVE20',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Code required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Coupon description
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Description required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Percentage discount
                  TextFormField(
                    controller: valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage *',
                      hintText: 'e.g. 10',
                      suffixText: '%',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Discount percentage is required';
                      }

                      final n = double.tryParse(v.trim());

                      if (n == null || n <= 0) {
                        return 'Enter a valid discount percentage';
                      }

                      if (n > 100) {
                        return 'Maximum discount is 100%';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Minimum order amount
                  TextFormField(
                    controller: minOrderCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min Order Amount (\$)',
                      hintText: 'Optional',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }

                      final n = double.tryParse(v.trim());

                      if (n == null || n < 0) {
                        return 'Enter a valid amount';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Usage limit
                  TextFormField(
                    controller: usageLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Usage Limit',
                      hintText: 'Optional (blank = unlimited)',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }

                      final n = int.tryParse(v.trim());

                      if (n == null || n <= 0) {
                        return 'Enter a valid usage limit';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // Expiry date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: expiresAt ??
                            DateTime.now().add(
                              const Duration(days: 30),
                            ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 2),
                        ),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          expiresAt = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            expiresAt != null
                                ? DateFormat(
                              'MMM d, yyyy',
                            ).format(expiresAt!)
                                : 'No expiry (tap to set)',
                            style: TextStyle(
                              color: expiresAt != null
                                  ? null
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final code = codeCtrl.text.trim().toUpperCase();

                final data = {
                  'description': descCtrl.text.trim(),

                  // All coupons are percentage based.
                  'type': 'percent',

                  'value': double.parse(
                    valueCtrl.text.trim(),
                  ),

                  'minOrderAmount': minOrderCtrl.text.trim().isNotEmpty
                      ? double.tryParse(
                    minOrderCtrl.text.trim(),
                  )
                      : null,

                  'usageLimit': usageLimitCtrl.text.trim().isNotEmpty
                      ? int.tryParse(
                    usageLimitCtrl.text.trim(),
                  )
                      : null,

                  'usedCount': existing?['usedCount'] ?? 0,

                  'isActive': existing?['isActive'] ?? true,

                  'expiresAt': expiresAt != null
                      ? Timestamp.fromDate(expiresAt!)
                      : null,

                  'createdAt': existing?['createdAt'] ??
                      FieldValue.serverTimestamp(),
                };

                try {
                  await _service.addOrUpdateCoupon(
                    code,
                    data,
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          existingCode != null
                              ? 'Coupon updated successfully!'
                              : 'Coupon "$code" created!',
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: Text(
                existingCode != null ? 'Update' : 'Create',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCoupon(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text(
          'Permanently delete coupon "$code"? '
              'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      await _service.deleteCoupon(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon "$code" deleted',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Coupon Management',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCouponDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: Text(
          'New Coupon',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamCoupons(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading coupons: ${snapshot.error}',
                style: const TextStyle(
                  color: AppColors.error,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No Coupons Created',
              subtitle:
              'Tap the button below to create your first discount coupon.',
              actionLabel: 'Create Coupon',
              onAction: () => _showCouponDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final code = doc.id;

              final isActive =
                  data['isActive'] ?? true;

              final value =
              (data['value'] ?? 0).toDouble();

              final usedCount =
                  data['usedCount'] ?? 0;

              final usageLimit =
              data['usageLimit'];

              final expiresAt =
              (data['expiresAt'] is Timestamp)
                  ? (data['expiresAt'] as Timestamp)
                  .toDate()
                  : null;

              final isExpired =
                  expiresAt != null &&
                      expiresAt.isBefore(
                        DateTime.now(),
                      );

              return FadeInUp(
                delay: Duration(
                  milliseconds: i * 40,
                ),
                child: Container(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? AppColors.surfaceRaised
                        : AppColors.paperSurface,
                    borderRadius:
                    BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive && !isExpired
                          ? AppColors.primary.withValues(
                        alpha: 0.3,
                      )
                          : (dark
                          ? AppColors.surfaceBorder
                          : AppColors.paperBorder),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isActive &&
                                    !isExpired
                                    ? AppColors.primary
                                    .withValues(
                                  alpha: 0.1,
                                )
                                    : AppColors
                                    .textSecondary
                                    .withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius:
                                BorderRadius.circular(
                                  12,
                                ),
                              ),
                              child: Icon(
                                Icons.local_offer_rounded,
                                color: isActive &&
                                    !isExpired
                                    ? AppColors.primary
                                    : AppColors
                                    .textSecondary,
                                size: 22,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        code,
                                        style: GoogleFonts
                                            .plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight
                                              .w800,
                                          letterSpacing:
                                          0.5,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      _statusBadge(
                                        isActive,
                                        isExpired,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    data['description'] ??
                                        '',
                                    style: GoogleFonts.inter(
                                      color: AppColors
                                          .textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Percentage discount display
                            Text(
                              '${value.toStringAsFixed(0)}% OFF',
                              style: GoogleFonts
                                  .plusJakartaSans(
                                fontWeight:
                                FontWeight.w800,
                                fontSize: 15,
                                color: isActive &&
                                    !isExpired
                                    ? AppColors.primary
                                    : AppColors
                                    .textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            _infoChip(
                              Icons.bar_chart_rounded,
                              usageLimit != null
                                  ? '$usedCount / $usageLimit used'
                                  : '$usedCount used',
                            ),

                            if (expiresAt != null) ...[
                              const SizedBox(width: 8),
                              _infoChip(
                                Icons.schedule_rounded,
                                isExpired
                                    ? 'Expired'
                                    : 'Expires ${DateFormat('MMM d').format(expiresAt)}',
                                color: isExpired
                                    ? AppColors.error
                                    : null,
                              ),
                            ],

                            const Spacer(),

                            // Toggle active status
                            Switch(
                              value: isActive,
                              activeThumbColor:
                              AppColors.primary,
                              onChanged: (val) async {
                                await _service
                                    .toggleCouponActive(
                                  code,
                                  val,
                                );
                              },
                            ),

                            // Edit coupon
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                              ),
                              onPressed: () =>
                                  _showCouponDialog(
                                    existing: data,
                                    existingCode: code,
                                  ),
                              tooltip: 'Edit',
                            ),

                            // Delete coupon
                            IconButton(
                              icon: const Icon(
                                Icons
                                    .delete_outline_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () =>
                                  _deleteCoupon(code),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusBadge(
      bool isActive,
      bool isExpired,
      ) {
    final label = isExpired
        ? 'Expired'
        : (isActive ? 'Active' : 'Inactive');

    final color = isExpired
        ? AppColors.error
        : (isActive
        ? AppColors.success
        : AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoChip(
      IconData icon,
      String label, {
        Color? color,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: color ?? AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}