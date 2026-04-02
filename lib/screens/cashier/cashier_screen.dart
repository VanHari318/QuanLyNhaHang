import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import '../../models/order_model.dart';
import '../../models/table_model.dart';
import '../../models/user_model.dart';
import '../../utils/logout_helper.dart';
import '../profile/profile_screen.dart';

/// Màn hình thu ngân – dùng OrderModel API mới (dish thay foodItem, tableId thay tableNumber)
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final orderProvider = Provider.of<OrderProvider>(context);
    final tableProvider = Provider.of<TableProvider>(context);
    final cs = Theme.of(context).colorScheme;

    final servedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.served)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu Ngân'),
        leading: isAdmin
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: servedOrders.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_rounded,
                          size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text('Không có đơn nào chờ thanh toán',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
              itemCount: servedOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = servedOrders[index];
                // tableId hoặc "Online"
                final tableLabel = order.tableId ?? 'Online';
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.table_bar_rounded,
                          color: Colors.green),
                    ),
                    title: Text(tableLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        'Tổng: ${_formatPrice(order.totalPrice)}đ\n${order.items.length} món'),
                    isThreeLine: true,
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        await orderProvider.updateStatus(
                            order.id, OrderStatus.completed);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✅ Thanh toán thành công')),
                          );
                        }
                      },
                      child: const Text('Thanh toán'),
                    ),
                    onTap: () => _showDetails(context, order),
                  ),
                );
              },
            ),
      ),
    );
  }

  void _showDetails(BuildContext context, OrderModel order) {
    final tableLabel = order.tableId ?? 'Online';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết – $tableLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                      '${item.quantity}× ${item.dish.name}  –  ${_formatPrice(item.dish.price * item.quantity)}đ'),
                )),
            const Divider(),
            Text('Tổng: ${_formatPrice(order.totalPrice)}đ',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
      ),
    );
  }

  String _formatPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}
