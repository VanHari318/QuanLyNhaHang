import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/database_service.dart';
import '../models/order_model.dart';
import '../utils/logout_helper.dart';
import '../components/dashboard_card.dart';
import '../components/order_item_card.dart';
import 'menu_management_screen.dart';
import 'category_management_screen.dart';
import 'table_management_screen.dart';
import 'order_management_screen.dart';
import 'staff_management_screen.dart';
import 'inventory_management_screen.dart';
import 'dashboard_stats_screen.dart';
import 'chatbot_management_screen.dart';

/// Admin Dashboard – Vị Lai Quán (未来馆) – Premium MD3 layout
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final admin = Provider.of<AuthProvider>(context, listen: false).user;
    final inv = context.watch<InventoryProvider>();

    // Count low-stock items
    final lowStockCount = inv.items.where((item) {
      return item.maxQuantity > 0
          ? item.quantity < item.maxQuantity * 0.2
          : item.quantity < 5;
    }).length;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with gradient header ──────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, size: 26),
                    if (lowStockCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.primary, width: 1.5),
                          ),
                          child: Center(
                            child: Text('$lowStockCount',
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black)),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Thông báo',
                onPressed: () => _push(context, const InventoryManagementScreen()),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Đăng xuất',
                onPressed: () => LogoutHelper.showLogoutDialog(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary,
                      const Color(0xFF8B0000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Logo
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '未来馆',
                                  style: TextStyle(
                                    color: const Color(0xFFFFC107),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'Vị Lai Quán · Admin',
                                  style: TextStyle(
                                    color: cs.onPrimary.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Admin avatar
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: const Color(0xFFFFC107).withValues(alpha: 0.25),
                              backgroundImage: (admin != null && admin.imageUrl.isNotEmpty)
                                  ? NetworkImage(admin.imageUrl)
                                  : null,
                              child: (admin == null || admin.imageUrl.isEmpty)
                                  ? Text(
                                      admin?.name.isNotEmpty == true
                                          ? admin!.name[0].toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Xin chào, ${admin?.name ?? "Admin"} 👋',
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Section 1: KPI Cards ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(label: '📊 Tổng quan hôm nay'),
                  const SizedBox(height: 12),
                  StreamBuilder<List<OrderModel>>(
                    stream: _db.getOrders(),
                    builder: (ctx, snap) {
                      final orders = snap.data ?? [];
                      final now = DateTime.now();
                      final todayOrders = orders.where((o) =>
                          o.createdAt.year == now.year &&
                          o.createdAt.month == now.month &&
                          o.createdAt.day == now.day).toList();

                      final todayRevenue = todayOrders
                          .where((o) => o.status == OrderStatus.completed)
                          .fold(0.0, (sum, o) => sum + o.totalPrice);

                      // Top dish from today
                      final dishCount = <String, int>{};
                      for (final o in todayOrders) {
                        for (final item in o.items) {
                          dishCount[item.dish.name] =
                              (dishCount[item.dish.name] ?? 0) + item.quantity;
                        }
                      }
                      final topDish = dishCount.isNotEmpty
                          ? (dishCount.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value)))
                              .first
                              .key
                          : '–';

                      return GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.90,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          DashboardCard(
                            icon: Icons.monetization_on_rounded,
                            title: 'Doanh thu hôm nay',
                            value: '${_fmt(todayRevenue)}đ',
                            color: const Color(0xFFD32F2F),
                            onTap: () => _push(context, const DashboardStatsScreen()),
                          ),
                          DashboardCard(
                            icon: Icons.receipt_long_rounded,
                            title: 'Số đơn hôm nay',
                            value: '${todayOrders.length}',
                            color: Colors.blue,
                            badge: todayOrders
                                    .where((o) => o.status == OrderStatus.pending)
                                    .isNotEmpty
                                ? '${todayOrders.where((o) => o.status == OrderStatus.pending).length} chờ xử lý'
                                : null,
                            badgeColor: Colors.orange,
                            onTap: () => _push(context, const OrderManagementScreen()),
                          ),
                          DashboardCard(
                            icon: Icons.whatshot_rounded,
                            title: 'Món bán chạy',
                            value: topDish,
                            color: Colors.orange,
                            onTap: () => _push(context, const DashboardStatsScreen()),
                          ),
                          DashboardCard(
                            icon: Icons.warning_amber_rounded,
                            title: 'Kho sắp hết',
                            value: '$lowStockCount món',
                            color: lowStockCount > 0 ? cs.error : Colors.green,
                            badge: lowStockCount > 0 ? 'Cần bổ sung!' : 'Ổn định',
                            badgeColor: lowStockCount > 0 ? cs.error : Colors.green,
                            onTap: () =>
                                _push(context, const InventoryManagementScreen()),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Section 2: Realtime Order Feed ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SectionHeader(label: '⚡ Đơn hàng mới nhất'),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            _push(context, const OrderManagementScreen()),
                        child: const Text('Xem tất cả →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<OrderModel>>(
                    stream: _db.getOrders(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final orders = snap.data!.take(5).toList();
                      if (orders.isEmpty) {
                        return _emptyFeed(cs);
                      }
                      return Column(
                        children: orders
                            .map((o) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: OrderItemCard(
                                    order: o,
                                    onTap: () =>
                                        _push(context, const OrderManagementScreen()),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Section 3: Module Grid ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _SectionHeader(label: '🧭 Quản lý'),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _ModuleCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'Thống Kê',
                  color: Colors.blue,
                  onTap: () => _push(context, const DashboardStatsScreen()),
                ),
                _ModuleCard(
                  icon: Icons.restaurant_menu_rounded,
                  label: 'Quản Lý Món',
                  color: Colors.orange,
                  onTap: () => _push(context, const MenuManagementScreen()),
                ),
                _ModuleCard(
                  icon: Icons.category_rounded,
                  label: 'Danh Mục',
                  color: Colors.purple,
                  onTap: () => _push(context, const CategoryManagementScreen()),
                ),
                _ModuleCard(
                  icon: Icons.table_bar_rounded,
                  label: 'Quản Lý Bàn',
                  color: Colors.teal,
                  onTap: () => _push(context, const TableManagementScreen()),
                ),
                _ModuleCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Đơn Hàng',
                  color: const Color(0xFFD32F2F),
                  onTap: () => _push(context, const OrderManagementScreen()),
                ),
                _ModuleCard(
                  icon: Icons.people_rounded,
                  label: 'Nhân Sự',
                  color: Colors.indigo,
                  onTap: () => _push(context, const StaffManagementScreen()),
                ),
                _ModuleCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Kho Nguyên Liệu',
                  color: Colors.brown,
                  onTap: () => _push(context, const InventoryManagementScreen()),
                ),
                _ModuleCard(
                  icon: Icons.smart_toy_rounded,
                  label: 'ChatBot FAQ',
                  color: Colors.green,
                  onTap: () => _push(context, const ChatbotManagementScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _emptyFeed(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: cs.outlineVariant, size: 28),
          const SizedBox(width: 10),
          Text('Chưa có đơn hàng nào',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _fmt(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

// ── Module card widget ────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
