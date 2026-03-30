import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_service.dart';
import '../../models/order_model.dart';
import '../../utils/logout_helper.dart';
import '../../components/dashboard_card.dart';
import '../../components/order_item_card.dart';
import '../../theme/admin_theme.dart';
import '../../services/data_seed_service.dart';
import '../../providers/admin_theme_provider.dart';

// Management screens
import 'menu_management_screen.dart';
import 'category_management_screen.dart';
import 'table_management_screen.dart';
import 'order_management_screen.dart';
import 'staff_management_screen.dart';
import 'inventory_management_screen.dart';
import 'dashboard_stats_screen.dart';
import 'chatbot_management_screen.dart';
import 'restaurant_location_screen.dart';
import '../customer/customer_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Admin Dashboard – Vị Lai Quán Premium Dark
/// Layout: Fixed header → Scrollable content (KPI → Orders → Modules)
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AuthProvider>(context, listen: false).user;
    final inv   = context.watch<InventoryProvider>();
    final lowCount = inv.items.where((i) => inv.isLow(i)).length;

    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              admin: admin,
              lowStockCount: lowCount,
              onLogout: () => LogoutHelper.showLogoutDialog(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _KpiSection(
                      db: _db, 
                      onTapOrder: _pushOrdersToday,
                      onTapRevenue: () => _push(const DashboardStatsScreen()),
                    ),
                    const SizedBox(height: 4),
                    _OrderFeedSection(db: _db, onViewAll: _pushAllOrders),
                    const SizedBox(height: 4),
                    _ModuleSection(push: _push),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, _fadeRoute(screen));

  void _pushOrdersToday() =>
      _push(OrderManagementScreen(initialDate: DateTime.now()));

  void _pushAllOrders() => _push(const OrderManagementScreen());

  void _snackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AdminText.bodyMedium(context)),
      backgroundColor: color.withValues(alpha: 0.15),
      duration: const Duration(seconds: 4),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final dynamic admin;
  final int lowStockCount;
  final VoidCallback onLogout;

  const _Header({
    required this.admin,
    required this.lowStockCount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: BoxDecoration(
        color: AdminColors.bgPrimary(context),
        border: Border(
          bottom: BorderSide(color: AdminColors.borderMuted(context), width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Brand ──────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/logo.png',
              width: 36, height: 36, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AdminColors.crimsonSubtle(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: AdminColors.crimson, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VỊ LAI QUÁN', style: AdminText.brandName),
                Text(
                  admin?.name != null ? 'Xin chào, ${admin.name}' : 'Trang Quản Trị',
                  style: AdminText.caption(context),
                ),
              ],
            ),
          ),
          // ── Action icons ───────────────────────────────────────────────────
           _HeaderAction(
            icon: Icons.notifications_outlined,
            badge: lowStockCount > 0 ? '$lowStockCount' : null,
            onTap: () => Navigator.push(
              context,
              _fadeRoute(const InventoryManagementScreen()),
            ),
          ),
          // ── Theme Toggle ───────────────────────────────────────────────────
          Consumer<AdminThemeProvider>(
            builder: (context, themeProvider, _) => _HeaderAction(
              icon: themeProvider.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
              onTap: () => themeProvider.toggleTheme(),
            ),
          ),
          _HeaderAction(
            icon: Icons.power_settings_new_rounded,
            onTap: onLogout,
          ),
          const SizedBox(width: 4),
          // ── Admin avatar ───────────────────────────────────────────────────
          CircleAvatar(
            radius: 17,
            backgroundColor: AdminColors.crimsonSubtle(context),
            backgroundImage: (admin?.imageUrl?.isNotEmpty == true)
                ? NetworkImage(admin.imageUrl)
                : null,
            child: (admin == null || (admin.imageUrl?.isEmpty ?? true))
                ? Text(
                    admin?.name?.isNotEmpty == true
                        ? admin!.name[0].toUpperCase()
                        : 'A',
                    style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.crimsonBright,
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _HeaderAction(
      {required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, size: 22),
          onPressed: onTap,
          color: AdminColors.textSecondary(context),
          splashRadius: 20,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
        if (badge != null)
          Positioned(
            right: 4, top: 4,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: AdminColors.warning,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AdminColors.bgPrimary(context), width: 1.5),
              ),
              child: Center(
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: Colors.black)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _KpiSection extends StatelessWidget {
  final DatabaseService db;
  final VoidCallback onTapOrder;
  final VoidCallback onTapRevenue;

  const _KpiSection({
    required this.db, 
    required this.onTapOrder,
    required this.onTapRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'TỔNG QUAN HÔM NAY'),
          const SizedBox(height: 14),
          StreamBuilder<List<OrderModel>>(
            stream: db.getOrders(limit: 300),
            builder: (ctx, snap) {
              final orders = snap.data ?? [];
              final now = DateTime.now();
              final today = orders.where((o) =>
                  o.createdAt.year == now.year &&
                  o.createdAt.month == now.month &&
                  o.createdAt.day == now.day).toList();

              final revenue = today
                  .where((o) => o.status == OrderStatus.completed)
                  .fold(0.0, (s, o) => s + o.totalPrice);
              final pending =
                  today.where((o) => o.status == OrderStatus.pending).length;

              final allDishCount = <String, int>{};
              for (final o in orders.where(
                  (o) => o.status == OrderStatus.completed)) {
                for (final item in o.items) {
                  allDishCount[item.dish.name] =
                      (allDishCount[item.dish.name] ?? 0) + item.quantity;
                }
              }
              final sorted = allDishCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final topDish = sorted.isNotEmpty ? sorted.first.key : '–';
              final topQty =
                  sorted.isNotEmpty ? sorted.first.value : 0;

              final lowCount = context
                  .read<InventoryProvider>()
                  .items
                  .where((i) =>
                      context.read<InventoryProvider>().isLow(i))
                  .length;

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  DashboardCard(
                    icon: Icons.monetization_on_rounded,
                    title: 'Doanh thu hôm nay',
                    value: '${_fmt(revenue)}đ',
                    color: AdminColors.crimson,
                    onTap: onTapRevenue,
                  ),
                  DashboardCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Số đơn hôm nay',
                    value: '${today.length}',
                    color: AdminColors.info,
                    badge: pending > 0 ? '$pending chờ' : null,
                    badgeColor: AdminColors.warning,
                    onTap: onTapOrder,
                  ),
                  DashboardCard(
                    icon: Icons.whatshot_rounded,
                    title: 'Bán chạy nhất',
                    value: topDish,
                    color: AdminColors.orange,
                    badge: topQty > 0 ? '$topQty suất' : null,
                    badgeColor: AdminColors.orange,
                  ),
                  DashboardCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Kho sắp hết',
                    value: '$lowCount món',
                    color: lowCount > 0 ? AdminColors.error : AdminColors.success,
                    badge: lowCount > 0 ? 'Cần bổ sung' : 'Ổn định',
                    badgeColor:
                        lowCount > 0 ? AdminColors.error : AdminColors.success,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _fmt(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER FEED SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _OrderFeedSection extends StatelessWidget {
  final DatabaseService db;
  final VoidCallback onViewAll;

  const _OrderFeedSection({required this.db, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionLabel(label: 'ĐƠN HÀNG MỚI NHẤT'),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Text('Xem tất cả →',
                    style: AdminText.caption(context).copyWith(
                        color: AdminColors.crimson,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<OrderModel>>(
            stream: db.getOrders(limit: 10),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AdminColors.crimson),
                  ),
                );
              }
              final orders = snap.data!.take(5).toList();
              if (orders.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          color: AdminColors.textMuted(context), size: 22),
                      const SizedBox(width: 8),
                      Text('Chưa có đơn hàng nào',
                          style: AdminText.caption(context)),
                    ],
                  ),
                );
              }
              return Column(
                children: orders
                    .map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OrderItemCard(
                            order: o,
                            onTap: onViewAll,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleSection extends StatelessWidget {
  final void Function(Widget) push;

  const _ModuleSection({required this.push});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Module(Icons.bar_chart_rounded,      'Thống Kê',         AdminColors.info,    () => push(const DashboardStatsScreen())),
      _Module(Icons.restaurant_menu_rounded, 'Quản Lý Món',      AdminColors.orange,  () => push(const MenuManagementScreen())),
      _Module(Icons.category_rounded,        'Danh Mục',         AdminColors.purple,  () => push(const CategoryManagementScreen())),
      _Module(Icons.table_bar_rounded,       'Quản Lý Bàn',      AdminColors.teal,    () => push(const TableManagementScreen())),
      _Module(Icons.receipt_long_rounded,    'Đơn Hàng',         AdminColors.crimson, () => push(const OrderManagementScreen())),
      _Module(Icons.people_rounded,          'Nhân Sự',          AdminColors.indigo,  () => push(const StaffManagementScreen())),
      _Module(Icons.inventory_2_rounded,     'Kho Hàng',         AdminColors.warning, () => push(const InventoryManagementScreen())),
      _Module(Icons.smart_toy_rounded,       'ChatBot FAQ',      AdminColors.success,  () => push(ChatbotManagementScreen())),
      _Module(Icons.map_rounded,             'Vị Trí & Bản Đồ', AdminColors.gold,    () => push(RestaurantLocationScreen())),
      _Module(Icons.person_search_rounded,   'Khách Hàng',       AdminColors.crimsonBright, () => push(CustomerManagementScreen())),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'QUẢN LÝ'),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (_, i) => _ModuleTile(module: modules[i]),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Module(this.icon, this.label, this.color, this.onTap);
}

class _ModuleTile extends StatefulWidget {
  final _Module module;
  const _ModuleTile({required this.module});

  @override
  State<_ModuleTile> createState() => _ModuleTileState();
}

class _ModuleTileState extends State<_ModuleTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.module;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        m.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: AdminColors.bgCard(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.borderDefault(context), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [m.color, m.color.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(m.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  m.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textSecondary(context),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3, height: 16,
            decoration: BoxDecoration(
              color: AdminColors.crimson,
              borderRadius: BorderRadius.circular(99),
            )),
        const SizedBox(width: 8),
        Text(label, style: AdminText.sectionLabel(context)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSITION
// ─────────────────────────────────────────────────────────────────────────────
Route _fadeRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
