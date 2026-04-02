import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/logout_helper.dart';
import 'customer_chatbot_screen.dart';
import 'customer_menu_page.dart';
import 'gps_order_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/cart_tab.dart';
import 'order_history_screen.dart';
import 'profile_edit_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final String tid = cart.tableId ?? '';
    final String sid = cart.sessionId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vị Lai Quán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              // Trigger refresh visual feedback
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang làm mới dữ liệu...'),
                  duration: Duration(seconds: 1),
                ),
              );
              // Simply notify providers to re-fetch/notify if needed
              // (In this app, Streams handle updates, so this is mainly for UX confidence)
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeTab(),
          CustomerMenuPage(key: ValueKey('menu_$tid'), tableId: tid, sessionId: sid),
          const GPSOrderScreen(),
          const CartTab(),
          _buildAccountTab(context, user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Thực đơn',
          ),
          const NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            selectedIcon: Icon(Icons.delivery_dining_rounded),
            label: 'Đặt món',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text(cart.totalCount.toString()),
              isLabelVisible: cart.totalCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: Text(cart.totalCount.toString()),
              isLabelVisible: cart.totalCount > 0,
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Giỏ hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context, dynamic user) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      displacement: 40,
      edgeOffset: 20,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: cs.primaryContainer,
              backgroundImage:
                  user?.imageUrl != null && user!.imageUrl.isNotEmpty
                  ? NetworkImage(user.imageUrl)
                  : null,
              child: user?.imageUrl == null || user!.imageUrl.isEmpty
                  ? Text(
                      user?.name != null && user!.name.isNotEmpty
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 40,
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Khách hàng',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            _buildMenuTile(
              Icons.history_rounded,
              'Lịch sử đơn hàng',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              ),
            ),
            _buildMenuTile(
              Icons.person_pin_outlined,
              'Thông tin của tôi',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              ),
            ),
            _buildMenuTile(
              Icons.smart_toy_outlined,
              'Trợ lý Vị Lai (AI)',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerChatbotScreen(),
                ),
              ),
            ),
            _buildMenuTile(
              Icons.support_agent_rounded,
              'Hỗ trợ khách hàng',
              () {},
            ),
            const Divider(height: 40),
            _buildMenuTile(
              Icons.logout_rounded,
              'Đăng xuất',
              () => LogoutHelper.showLogoutDialog(context),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
