import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../services/database_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: auth.user == null 
        ? const Center(child: Text('Vui lòng đăng nhập để xem lịch sử'))
        : StreamBuilder<List<OrderModel>>(
            stream: _db.getAllOrdersByCustomer(auth.user!.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final orders = snapshot.data ?? [];
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 16),
                      Text('Bạn chưa có đơn hàng nào', style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (order.type == OrderType.online ? cs.secondary : cs.primary).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          order.type == OrderType.online ? Icons.delivery_dining_rounded : Icons.table_restaurant_rounded,
                          color: order.type == OrderType.online ? cs.secondary : cs.primary,
                        ),
                      ),
                      title: Text(
                        order.type == OrderType.online ? 'Đơn Online' : 'Tại bàn ${order.tableId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(order.createdAt)),
                          Text('Tổng: ${_formatPrice(order.totalPrice)}đ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: _buildStatusBadge(order.status, cs),
                      onTap: () => _showOrderDetails(context, order),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status, ColorScheme cs) {
    final color = _statusColor(status, cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const Divider(height: 32),
            Expanded(
              child: ListView(
                children: [
                  ...order.items.map((it) => ListTile(
                    title: Text(it.dish.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${it.quantity} x ${_formatPrice(it.dish.price)}đ'),
                    trailing: Text('${_formatPrice(it.dish.price * it.quantity)}đ'),
                  )),
                  const Divider(),
                  _detailRow('Phương thức:', order.paymentMethod ?? 'N/A'),
                  _detailRow('Trạng thái:', _statusLabel(order.status)),
                  if (order.customerNote != null) _detailRow('Lưu ý:', order.customerNote!),
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_formatPrice(order.totalPrice)}đ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(ctx).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            )
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), textAlign: TextAlign.right)),
    ]),
  );

  String _formatDate(DateTime dt) => '${dt.hour}:${dt.minute} - ${dt.day}/${dt.month}/${dt.year}';
  String _formatPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Color _statusColor(OrderStatus s, ColorScheme cs) => switch (s) {
    OrderStatus.pending => Colors.orange,
    OrderStatus.preparing => Colors.blue,
    OrderStatus.ready => Colors.teal,
    OrderStatus.served => Colors.purple,
    OrderStatus.completed => Colors.green,
    OrderStatus.cancelled => cs.error,
  };

  String _statusLabel(OrderStatus s) => switch (s) {
    OrderStatus.pending => 'Chờ xử lý',
    OrderStatus.preparing => 'Đang làm',
    OrderStatus.ready => 'Sẵn sàng',
    OrderStatus.served => 'Đã phục vụ',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
  };
}
