import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../theme/admin_theme.dart';

/// Compact dark order card – used in Admin Dashboard feed
class OrderItemCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderItemCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = order.type == OrderType.online;
    final Color statusColor = _statusColor(order.status);
    final String shortId = order.id.length > 8
        ? order.id.substring(order.id.length - 8)
        : order.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.bgCard(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.borderDefault(context), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Status indicator bar ──────────────────────────────────────
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Type icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? AdminColors.info.withValues(alpha: 0.14)
                              : AdminColors.crimsonSubtle(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline
                              ? Icons.delivery_dining_rounded
                              : Icons.table_restaurant_rounded,
                          size: 16,
                          color: isOnline
                              ? AdminColors.info
                              : AdminColors.crimson,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Order info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOnline
                                  ? 'Online #$shortId'
                                  : (order.tableId ?? 'Đơn chung'),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(order.createdAt),
                              style: AdminText.caption(context),
                            ),
                          ],
                        ),
                      ),
                      // Price + status pill
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_fmtPrice(order.totalPrice)}đ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).brightness == Brightness.dark ? AdminColors.gold : AdminColors.crimson,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _StatusPill(order.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.pending   => AdminColors.warning,
        OrderStatus.preparing => AdminColors.info,
        OrderStatus.ready     => AdminColors.teal,
        OrderStatus.served    => AdminColors.purple,
        OrderStatus.completed => AdminColors.success,
        OrderStatus.cancelled => AdminColors.error,
      };

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = '${dt.day}/${dt.month}/${dt.year}';
    return '$h:$m · $d';
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Tiny pill badge for order status
class _StatusPill extends StatelessWidget {
  final OrderStatus status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = _data();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (String, Color) _data() => switch (status) {
        OrderStatus.pending   => ('CHỜ XỬ LÝ', AdminColors.warning),
        OrderStatus.preparing => ('ĐANG LÀM', AdminColors.info),
        OrderStatus.ready     => ('SẴN SÀNG', AdminColors.teal),
        OrderStatus.served    => ('ĐÃ PHỤC VỤ', AdminColors.purple),
        OrderStatus.completed => ('HOÀN THÀNH', AdminColors.success),
        OrderStatus.cancelled => ('ĐÃ HỦY', AdminColors.error),
      };
}
