import 'package:flutter/material.dart';
import '../models/order_model.dart';

/// Compact order card for realtime feeds and order management lists.
class OrderItemCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onStatusTap;
  final VoidCallback? onTap;

  const OrderItemCard({
    super.key,
    required this.order,
    this.onStatusTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(order.status, cs);
    final label = _statusLabel(order.status);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(order.status), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.type == OrderType.dine_in
                          ? '🪑 ${order.tableId ?? "Bàn?"}'
                          : '🛵 Giao hàng online',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.items.length} món  •  ${_formatPrice(order.totalPrice)}đ',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Status chip
              GestureDetector(
                onTap: onStatusTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

Color _statusColor(OrderStatus s, ColorScheme cs) => switch (s) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.preparing => Colors.blue,
      OrderStatus.ready => Colors.teal,
      OrderStatus.completed => Colors.green,
      OrderStatus.cancelled => cs.error,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Chờ',
      OrderStatus.preparing => 'Đang làm',
      OrderStatus.ready => 'Sẵn sàng',
      OrderStatus.completed => 'Hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
    };

IconData _statusIcon(OrderStatus s) => switch (s) {
      OrderStatus.pending => Icons.pending_outlined,
      OrderStatus.preparing => Icons.soup_kitchen_outlined,
      OrderStatus.ready => Icons.check_circle_outline_rounded,
      OrderStatus.completed => Icons.task_alt_rounded,
      OrderStatus.cancelled => Icons.cancel_outlined,
    };
