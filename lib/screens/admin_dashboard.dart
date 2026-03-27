import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/init_data_service.dart';
import '../utils/logout_helper.dart';
import 'menu_management_screen.dart';
import 'category_management_screen.dart';
import 'table_management_screen.dart';
import 'order_management_screen.dart';
import 'staff_management_screen.dart';
import 'inventory_management_screen.dart';
import 'dashboard_stats_screen.dart';
import 'chatbot_management_screen.dart';

/// Admin Dashboard – MD3 NavigationDrawer layout
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final admin = Provider.of<AuthProvider>(context, listen: false).user;

    return Scaffold(
      // ── AppBar
      appBar: AppBar(
        title: const Text('Quản Lý Nhà Hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),

      // ── Body: realtime stats + module grid
      body: CustomScrollView(
        slivers: [
          // Welcome banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
                    child: Icon(Icons.admin_panel_settings_rounded,
                        color: cs.onPrimary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào, Admin 👋',
                          style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text(admin?.name ?? '',
                          style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Module grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
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
                  color: Colors.red,
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

          // Seed data card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _SeedDataCard(),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
        borderRadius: BorderRadius.circular(12),
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

// ── Seed data card ────────────────────────────────────────────────────────────
class _SeedDataCard extends StatefulWidget {
  @override
  State<_SeedDataCard> createState() => _SeedDataCardState();
}

class _SeedDataCardState extends State<_SeedDataCard> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);
    try {
      await InitDataService().seedAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Đã tạo dữ liệu mẫu: 20 bàn + 30 món + 4 danh mục')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: cs.onSecondaryContainer, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khởi tạo dữ liệu mẫu',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          )),
                  Text('20 bàn • 30 món • 4 danh mục',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSecondaryContainer.withValues(alpha: 0.8),
                          )),
                ],
              ),
            ),
            _loading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton(
                    onPressed: _seed,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: cs.onSecondary,
                    ),
                    child: const Text('Seed'),
                  ),
          ],
        ),
      ),
    );
  }
}
