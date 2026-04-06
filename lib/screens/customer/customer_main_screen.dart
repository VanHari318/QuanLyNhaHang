import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter/services.dart';
>>>>>>> 6690387 (sua loi)
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
<<<<<<< HEAD
=======
import '../../theme/role_themes.dart';
>>>>>>> 6690387 (sua loi)
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

<<<<<<< HEAD
class _CustomerMainScreenState extends State<CustomerMainScreen> {
  int _selectedIndex = 0;
=======
class _CustomerMainScreenState extends State<CustomerMainScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }
>>>>>>> 6690387 (sua loi)

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final String tid = cart.tableId ?? '';
    final String sid = cart.sessionId ?? '';

<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vị Lai Quán', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
=======
    // Set status bar to light icons for dark AppBar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(context, cart),
>>>>>>> 6690387 (sua loi)
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeTab(),
<<<<<<< HEAD
          CustomerMenuPage(tableId: tid, sessionId: sid),
=======
          CustomerMenuPage(
              key: ValueKey('menu_$tid'), tableId: tid, sessionId: sid),
>>>>>>> 6690387 (sua loi)
          const GPSOrderScreen(),
          const CartTab(),
          _buildAccountTab(context, user),
        ],
      ),
<<<<<<< HEAD
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined), 
            selectedIcon: Icon(Icons.home_rounded), 
            label: 'Trang chủ'
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined), 
            selectedIcon: Icon(Icons.restaurant_menu_rounded), 
            label: 'Thực đơn'
          ),
          const NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined), 
            selectedIcon: Icon(Icons.delivery_dining_rounded), 
            label: 'Đặt món'
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
            label: 'Tài khoản'
          ),
        ],
=======
      bottomNavigationBar: _buildNavBar(context, cart),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CartProvider cart) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(gradient: CustomerTheme.appBarGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Logo icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.ramen_dining_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('Vị Lai Quán',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    )),
                const Spacer(),
                // Notification bell
                _AppBarIconBtn(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {},
                  badge: false,
                ),
                const SizedBox(width: 4),
                // Refresh
                _AppBarIconBtn(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Đang làm mới dữ liệu...'),
                          ],
                        ),
                        backgroundColor: CustomerTheme.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  badge: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, CartProvider cart) {
    const items = [
      _NavItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Trang chủ'),
      _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Thực đơn'),
      _NavItem(Icons.moped_outlined, Icons.moped_rounded, 'Đặt món'),
      _NavItem(null, null, 'Giỏ hàng'), // cart item handled separately
      _NavItem(Icons.account_circle_outlined, Icons.account_circle_rounded,
          'Tài khoản'),
    ];

    return Container(
      decoration: CustomerTheme.navBarDecoration,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = _selectedIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CustomerTheme.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cart icon w/ badge OR regular icon
                        index == 3
                            ? Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.shopping_basket_rounded
                                        : Icons.shopping_basket_outlined,
                                    color: isSelected
                                        ? CustomerTheme.primary
                                        : Colors.grey.shade500,
                                    size: 24,
                                  ),
                                  if (cart.totalCount > 0)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: CustomerTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${cart.totalCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected
                                    ? CustomerTheme.primary
                                    : Colors.grey.shade500,
                                size: 24,
                              ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? CustomerTheme.primary
                                : Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
>>>>>>> 6690387 (sua loi)
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context, dynamic user) {
<<<<<<< HEAD
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: cs.primaryContainer,
            backgroundImage: user?.imageUrl != null && user!.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
            child: user?.imageUrl == null || user!.imageUrl.isEmpty 
              ? Text(user?.name != null && user!.name.isNotEmpty ? user!.name[0].toUpperCase() : '?', style: TextStyle(fontSize: 40, color: cs.primary, fontWeight: FontWeight.bold))
              : null,
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Khách hàng', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? '', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          _buildMenuTile(Icons.history_rounded, 'Lịch sử đơn hàng', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()))),
          _buildMenuTile(Icons.person_pin_outlined, 'Thông tin của tôi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()))),
          _buildMenuTile(Icons.smart_toy_outlined, 'Trợ lý Vị Lai (AI)', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerChatbotScreen()))),
          _buildMenuTile(Icons.support_agent_rounded, 'Hỗ trợ khách hàng', () {}),
          const Divider(height: 40),
          _buildMenuTile(Icons.logout_rounded, 'Đăng xuất', () => LogoutHelper.showLogoutDialog(context), isDanger: true),
        ],
=======
    return RefreshIndicator(
      color: CustomerTheme.primary,
      onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header gradient card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: CustomerTheme.appBarGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.3),
                          backgroundImage: user?.imageUrl != null &&
                                  user!.imageUrl.isNotEmpty
                              ? NetworkImage(user.imageUrl)
                              : null,
                          child: user?.imageUrl == null ||
                                  user!.imageUrl.isEmpty
                              ? Text(
                                  user?.name != null && user!.name.isNotEmpty
                                      ? user!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Khách hàng',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Menu cards
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      Icons.history_rounded,
                      'Lịch sử đơn hàng',
                      CustomerTheme.primary,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen()),
                      ),
                    ),
                    _divider(),
                    _buildMenuTile(
                      Icons.manage_accounts_rounded,
                      'Thông tin của tôi',
                      const Color(0xFF6C5CE7),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen()),
                      ),
                    ),
                    _divider(),
                    _buildMenuTile(
                      Icons.smart_toy_rounded,
                      'Trợ lý Vị Lai (AI)',
                      const Color(0xFF00CEC9),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerChatbotScreen()),
                      ),
                    ),
                    _divider(),
                    _buildMenuTile(
                      Icons.support_agent_rounded,
                      'Hỗ trợ khách hàng',
                      const Color(0xFFFDAB00),
                      () {},
                    ),
                  ],
                ),
              ),
            ),

            // Logout card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _buildMenuTile(
                  Icons.logout_rounded,
                  'Đăng xuất',
                  Colors.red,
                  () => LogoutHelper.showLogoutDialog(context),
                  isDanger: true,
                ),
              ),
            ),
          ],
        ),
>>>>>>> 6690387 (sua loi)
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? Colors.red : null),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.red : null, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
=======
  Widget _divider() => const Divider(height: 1, indent: 68, endIndent: 16);

  Widget _buildMenuTile(
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : const Color(0xFF2D3436),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: Colors.grey.shade400,
      ),
>>>>>>> 6690387 (sua loi)
      onTap: onTap,
    );
  }
}
<<<<<<< HEAD
=======

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _AppBarIconBtn(
      {required this.icon, required this.onTap, required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final IconData? activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
>>>>>>> 6690387 (sua loi)
