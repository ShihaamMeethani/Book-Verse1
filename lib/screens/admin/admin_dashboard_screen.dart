import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'add_edit_book_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _streamKey = 0;

  void _reloadStream() => setState(() => _streamKey++);

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: const Text('Sign out of the admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Dashboard',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _reloadStream,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<List<BookOrder>>(
        key: ValueKey(_streamKey),
        stream: service.streamAllOrders(),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];

          final totalRevenue = orders.fold(0.0, (acc, o) => acc + o.total);
          final totalOrders = orders.length;
          final pending = orders.where((o) =>
              o.status != OrderStatus.delivered &&
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.returned).length;
          final delivered = orders.where((o) => o.status == OrderStatus.delivered).length;

          final Map<int, double> byWeekday = {for (var i = 0; i < 7; i++) i: 0};
          for (final o in orders) {
            final diff = DateTime.now().difference(o.createdAt).inDays;
            if (diff < 7) {
              byWeekday[o.createdAt.weekday % 7] =
                  (byWeekday[o.createdAt.weekday % 7] ?? 0) + o.total;
            }
          }

          final recentOrders = orders.take(5).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Stats Grid ──────────────────────────────────────────
              FadeInDown(
                duration: const Duration(milliseconds: 350),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _statCard('\$${totalRevenue.toStringAsFixed(0)}', 'Total Revenue',
                        Icons.attach_money_rounded, AppColors.primary),
                    _statCard('$totalOrders', 'Total Orders',
                        Icons.shopping_bag_outlined, AppColors.info),
                    _statCard('$pending', 'Pending',
                        Icons.pending_actions_outlined, AppColors.warning),
                    _statCard('$delivered', 'Delivered',
                        Icons.check_circle_outline_rounded, AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Live user + book counts ─────────────────────────────
              FadeInDown(
                delay: const Duration(milliseconds: 60),
                child: Row(
                  children: [
                    Expanded(
                      child: _liveCountCard(
                        'Total Users',
                        Icons.people_outline_rounded,
                        AppColors.gold,
                        stream: FirebaseFirestore.instance
                            .collection(AppConstants.usersCollection)
                            .snapshots()
                            .map((s) => s.size),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _liveCountCard(
                        'Total Books',
                        Icons.library_books_outlined,
                        AppColors.primaryLight,
                        stream: FirebaseFirestore.instance
                            .collection(AppConstants.booksCollection)
                            .snapshots()
                            .map((s) => s.size),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Weekly Revenue Chart ─────────────────────────────────
              Text(
                'Weekly Revenue',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              FadeIn(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                    ),
                  ),
                  child: orders.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.bar_chart_rounded, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text(
                                  'No sales data yet',
                                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          days[value.toInt() % 7],
                                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(7, (i) {
                                return BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: byWeekday[i] ?? 0,
                                    color: AppColors.primary,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]);
                              }),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Quick Actions ───────────────────────────────────────
              Text(
                'Quick Actions',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                duration: const Duration(milliseconds: 350),
                delay: const Duration(milliseconds: 100),
                child: _actionCard(
                  context,
                  Icons.add_box_outlined,
                  'Add New Book',
                  'Add a new title to the catalog',
                  AppColors.primary,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditBookScreen())),
                ),
              ),
              const SizedBox(height: 28),

              // ── Recent Orders ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${orders.length} total',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentOrders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
                  ),
                  child: Center(
                    child: Text(
                      'No orders placed yet',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...recentOrders.asMap().entries.map((entry) {
                  final i = entry.key;
                  final order = entry.value;
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 40),
                    child: _recentOrderTile(context, order, dark, service),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _liveCountCard(String label, IconData icon, Color color, {required Stream<int> stream}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snap.hasData ? '${snap.data}' : '—',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _recentOrderTile(BuildContext context, BookOrder order, bool dark, FirestoreService service) {
    final statusColor = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? AppColors.surfaceBorder : AppColors.paperBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id.substring(0, order.id.length.clamp(0, 8)).toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  '${order.items.length} items · \$${order.total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              order.status.label,
              style: GoogleFonts.plusJakartaSans(
                color: statusColor, fontSize: 10, fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
}
