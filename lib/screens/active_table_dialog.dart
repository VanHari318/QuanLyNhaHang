import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';
import '../theme/role_themes.dart';
import '../services/database_service.dart';
import 'waiter/ordering_screen.dart';

/// Hiển thị danh sách các đơn hàng đang hoạt động của bàn
void showActiveTableDialog(
    BuildContext context, TableModel table, List<OrderModel> activeOrders) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ActiveTableSheet(
      table: table,
      parentContext: context,
    ),
  );
}

class _ActiveTableSheet extends StatelessWidget {
  final TableModel table;
  final BuildContext parentContext;

  const _ActiveTableSheet({
    required this.table,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext ctx) {
    // Lắng nghe sự thay đổi của đơn hàng ngay tại đây để cập nhật UI realtime
    final orderProvider = ctx.watch<OrderProvider>();
    final tableOrders = orderProvider.orders
        .where((o) =>
            o.tableId == table.id &&
            o.status != OrderStatus.completed &&
            o.status != OrderStatus.cancelled)
        .toList();
    // Sắp xếp theo thời gian tạo
    tableOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: WaiterTheme.appBarGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.table_restaurant_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        Text(
                          '${table.capacity} chỗ  •  ${tableOrders.length} lượt gọi món',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Danh sách các đơn (Orders) ────────────────────────────
              Flexible(
                child: tableOrders.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_rounded,
                                color: Colors.grey.shade300, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Bàn này hiện tại không có đơn hàng nào,\nnhưng hệ thống vẫn báo "Đang dùng".',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            // Nút dọn bàn cưỡng bức
                            _FilledBtn(
                              icon: Icons.cleaning_services_rounded,
                              label: 'Dọn bàn & Đưa về Trống',
                              color: Colors.orange.shade700,
                              onTap: () async {
                                final db = DatabaseService();
                                await db.forceReleaseTable(table.id);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Đã dọn bàn thành công!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: tableOrders.length,
                        itemBuilder: (context, index) {
                          final order = tableOrders[index];
                          return _OrderSection(
                            order: order,
                            orderIndex: index + 1,
                            table: table,
                            parentContext: parentContext,
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // ── Action Nút chung: Gọi thêm món ────────────────────────
              _OutlineBtn(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Gọi thêm món cho bàn',
                color: WaiterTheme.primary,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (_) => OrderingScreen(table: table),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSection extends StatelessWidget {
  final OrderModel order;
  final int orderIndex;
  final TableModel table;
  final BuildContext parentContext;

  const _OrderSection({
    required this.order,
    required this.orderIndex,
    required this.table,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final (statusLabel, statusColor, statusIcon) = _statusInfo(order);
    final isReady = order.status == OrderStatus.ready;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header của đơn
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                Text(
                  'Lượt gọi #$orderIndex',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Danh sách món trong đơn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '${item.quantity}x ',
                        style: const TextStyle(
                          color: WaiterTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.dish.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${_fmtPrice(item.dish.price * item.quantity)}đ',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Footer của đơn (Tổng + Nút hành động)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng đơn này',
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                    Text(
                      '${_fmtPrice(order.totalPrice)}đ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ],
                ),
                const Spacer(),
                if (isReady)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await orderProvider.updateStatus(
                          order.id, OrderStatus.served);
                      if (context.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(
                            content: Text('Đã phục vụ Lượt gọi #$orderIndex! 🍽️'),
                            backgroundColor: const Color(0xFF00B894),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Đã phục vụ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B894),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _statusInfo(OrderModel o) {
    return switch (o.status) {
      OrderStatus.pending => (
          'Chờ tiếp nhận',
          Colors.orange,
          Icons.pending_rounded
        ),
      OrderStatus.preparing => (
          'Đang làm',
          const Color(0xFF42A5F5),
          Icons.soup_kitchen_rounded
        ),
      OrderStatus.ready => (
          'Xong, giao ngay!',
          const Color(0xFF00B894),
          Icons.check_circle_rounded
        ),
      OrderStatus.served => (
          'Đã phục vụ',
          const Color(0xFF6C5CE7),
          Icons.receipt_rounded
        ),
      _ => ('Không xác định', Colors.grey, Icons.help_rounded),
    };
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FilledBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
