import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/logout_helper.dart';
import 'customer_menu_page.dart';
import 'qr_scanner_screen.dart';

class CustomerMainScreen extends StatelessWidget {
  const CustomerMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vị Lai Quán – Khách Hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header chào mừng
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: user?.imageUrl.isNotEmpty == true
                      ? NetworkImage(user!.imageUrl)
                      : null,
                  child: user?.imageUrl.isEmpty == true
                      ? Text(user!.name[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào,',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      Text(user?.name ?? 'Khách hàng',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text('Bạn muốn làm gì hôm nay?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: cs.primary)),
            const SizedBox(height: 16),

            // Các nút chức năng chính
            _FeatureCard(
              title: 'Quét mã QR gọi món',
              subtitle: 'Ngồi tại bàn và quét mã để đặt món ngay',
              icon: Icons.qr_code_scanner_rounded,
              color: Colors.orange,
              onTap: () async {
                final result = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                );
                if (result != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerMenuPage(
                        tableId: result['tableId']!,
                        sessionId: result['sessionId']!,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            _FeatureCard(
              title: 'Xem thực đơn',
              subtitle: 'Khám phá các món ăn hấp dẫn của quán',
              icon: Icons.restaurant_menu_rounded,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerMenuPage(
                      tableId: '', // Chế độ xem (Browse Mode)
                      sessionId: '',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _FeatureCard(
              title: 'Đặt hàng Online',
              subtitle: 'Đặt món giao tận nơi hoặc đến lấy',
              icon: Icons.delivery_dining_rounded,
              color: Colors.green,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đặt hàng online sắp ra mắt!')),
                );
              },
            ),

            const SizedBox(height: 32),
            // Banner hoặc khuyến mãi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thành viên V-VIP',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        Text('Tích điểm mỗi lần dùng bữa để nhận ưu đãi hấp dẫn.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
