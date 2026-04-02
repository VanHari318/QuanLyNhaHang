import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../utils/logout_helper.dart';
import '../profile/profile_screen.dart';

/// Màn hình bếp – dùng OrderModel API mới (item.dish thay item.foodItem)
class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final orderProvider = Provider.of<OrderProvider>(context);
    final cs = Theme.of(context).colorScheme;

    final activeOrders = orderProvider.orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bếp'),
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
        child: activeOrders.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.kitchen_rounded,
                          size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text('Không có đơn hàng đang chờ',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
              itemCount: activeOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final order = activeOrders[i];
                final tableLabel = order.tableId ?? 'Online';
                final isPending = order.status == OrderStatus.pending;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tableLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            _StatusChip(status: order.status),
                          ],
                        ),
                        const Divider(height: 16),
                        // Items – dùng item.dish thay item.foodItem
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Text('${item.quantity}×',
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.dish.name)),
                                if (item.note?.isNotEmpty == true)
                                  Text('📝 ${item.note}',
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12)),
                              ]),
                            )),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: isPending
                              ? FilledButton.icon(
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Bắt đầu làm'),
                                  onPressed: () => orderProvider.updateStatus(
                                      order.id, OrderStatus.preparing),
                                )
                              : FilledButton.icon(
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Xong'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () => orderProvider.updateStatus(
                                      order.id, OrderStatus.ready),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.pending => (Colors.orange, 'Chờ xử lý'),
      OrderStatus.preparing => (Colors.blue, 'Đang làm'),
      OrderStatus.ready => (Colors.teal, 'Sẵn sàng'),
      OrderStatus.served => (Colors.purple, 'Đã phục vụ'),
      _ => (Colors.grey, status.name),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
