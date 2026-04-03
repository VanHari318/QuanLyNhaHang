import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';
import '../theme/role_themes.dart';
import 'waiter/ordering_screen.dart';

void showActiveTableDialog(
    BuildContext context, TableModel table, OrderModel activeOrder) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ActiveTableSheet(
      table: table,
      activeOrder: activeOrder,
      parentContext: context,
    ),
  );
}

class _ActiveTableSheet extends StatelessWidget {
  final TableModel table;
  final OrderModel activeOrder;
  final BuildContext parentContext;

  const _ActiveTableSheet({
    required this.table,
    required this.activeOrder,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext ctx) {
    final orderProvider =
        Provider.of<OrderProvider>(ctx, listen: false);

    final isReady = activeOrder.status == OrderStatus.ready;
    final isPreparing = activeOrder.status == OrderStatus.preparing;
    final isServed = activeOrder.status == OrderStatus.served;
    final isPending = activeOrder.status == OrderStatus.pending;

    final (statusLabel, statusColor, statusIcon) = _statusInfo();

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
                          '${table.capacity} chỗ  •  ${activeOrder.items.length} món',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Items list ────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: activeOrder.items.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) {
                      final item = activeOrder.items[i];
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: WaiterTheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    color: WaiterTheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.dish.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  if (item.note?.isNotEmpty == true)
                                    Text('📝 ${item.note}',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              '${_fmtPrice(item.dish.price * item.quantity)}đ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Total
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: WaiterTheme.appBarGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng cộng:',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '${_fmtPrice(activeOrder.totalPrice)}đ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Action Buttons ────────────────────────────────────────
              // "Gọi thêm món" – always available
              _OutlineBtn(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Gọi thêm món',
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
              const SizedBox(height: 10),

              // Status-dependent primary action
              if (isReady)
                _FilledBtn(
                  icon: Icons.check_circle_rounded,
                  label: 'Xác nhận đã phục vụ',
                  color: const Color(0xFF00B894),
                  onTap: () async {
                    await orderProvider.updateStatus(
                        activeOrder.id, OrderStatus.served);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.room_service_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Đã phục vụ – Chờ thu ngân tính tiền'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF00B894),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                )
              else if (isServed)
                _DisabledBtn(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Chờ thu ngân thanh toán...',
                  color: const Color(0xFF6C5CE7),
                )
              else if (isPreparing)
                _DisabledBtn(
                  icon: Icons.soup_kitchen_rounded,
                  label: 'Bếp đang chế biến...',
                  color: const Color(0xFF42A5F5),
                )
              else if (isPending)
                _DisabledBtn(
                  icon: Icons.pending_rounded,
                  label: 'Đang chờ bếp tiếp nhận...',
                  color: Colors.orange,
                ),
            ],
          ),
        ),
      ),
    );
  }

  (String, Color, IconData) _statusInfo() {
    return switch (activeOrder.status) {
      OrderStatus.pending => (
          'Chờ bếp tiếp nhận',
          Colors.orange,
          Icons.pending_rounded
        ),
      OrderStatus.preparing => (
          'Bếp đang làm',
          const Color(0xFF42A5F5),
          Icons.soup_kitchen_rounded
        ),
      OrderStatus.ready => (
          'Món sẵn sàng!',
          const Color(0xFF00B894),
          Icons.check_circle_rounded
        ),
      OrderStatus.served => (
          'Chờ tính tiền',
          const Color(0xFF6C5CE7),
          Icons.receipt_rounded
        ),
      _ => ('Không xác định', Colors.grey, Icons.help_rounded),
    };
  }

  static String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

// ── BUTTON HELPER WIDGETS ─────────────────────────────────────────────────
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
              color: color.withValues(alpha: 0.35),
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

class _DisabledBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _DisabledBtn(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
