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

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final cart = context.watch<CartProvider>();
    final menu = context.watch<MenuProvider>();
    final cs = Theme.of(context).colorScheme;

    final List<Widget> _tabs = [
      const HomeTab(),
      CustomerMenuPage(
        tableId: cart.tableId ?? '', 
        sessionId: cart.sessionId ?? '',
      ), 
      const GPSOrderScreen(), 
      CartTab(onSwitchTab: (index) => setState(() => _currentIndex = index)),
      _buildAccountTab(context, user),
    ];

    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 0 || _currentIndex == 4 
        ? AppBar(
            title: Text(_currentIndex == 0 ? 'Vị Lai Quán' : 'Tài khoản', 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            centerTitle: _currentIndex == 4,
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
                    child: Icon(Icons.notifications_none_rounded, color: cs.primary, size: 20),
                  ),
                  onPressed: () {},
                ),
              const SizedBox(width: 8),
            ],
          )
        : null, // Hide AppBar for Menu/Map tabs as they have their own headers
      body: _tabs[_currentIndex],
      bottomNavigationBar: _buildBottomNav(cs),
    );
  }

  Widget _buildBottomNav(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, -5))
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: cs.primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: 'Thực đơn'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_rounded), label: 'Đặt hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_rounded), label: 'Giỏ hàng'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Tài khoản'),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context, dynamic user) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: cs.primaryContainer,
            backgroundImage: user?.imageUrl.isNotEmpty == true ? NetworkImage(user!.imageUrl) : null,
            child: user?.imageUrl.isEmpty == true 
              ? Text(user!.name[0].toUpperCase(), style: TextStyle(fontSize: 40, color: cs.primary, fontWeight: FontWeight.bold))
              : null,
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Khách hàng', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          _buildMenuTile(Icons.history_rounded, 'Lịch sử đơn hàng', () {}),
          _buildMenuTile(Icons.smart_toy_outlined, 'Trợ lý Vị Lai (AI)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerChatbotScreen()))),
          _buildMenuTile(Icons.favorite_outline_rounded, 'Món ăn yêu thích', () {}),
          _buildMenuTile(Icons.location_on_outlined, 'Địa chỉ của tôi', () {}),
          _buildMenuTile(Icons.support_agent_rounded, 'Hỗ trợ khách hàng', () {}),
          const Divider(height: 40),
          _buildMenuTile(Icons.logout_rounded, 'Đăng xuất', () => LogoutHelper.showLogoutDialog(context), isDanger: true),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.red : null, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Tính năng sắp ra mắt!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}


class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}
