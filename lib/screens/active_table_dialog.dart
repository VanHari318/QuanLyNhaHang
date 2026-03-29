import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../providers/order_provider.dart';

void showActiveTableDialog(BuildContext context, TableModel table, OrderModel activeOrder) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final orderProvider = Provider.of<OrderProvider>(ctx, listen: false);

      final isReady = activeOrder.status == OrderStatus.ready;
      final isPreparing = activeOrder.status == OrderStatus.preparing;
      final isServed = activeOrder.status == OrderStatus.served;

      String statusText = 'Chờ xử lý';
      Color statusColor = Colors.orange;

      if (isPreparing) {
        statusText = 'Bếp đang làm';
        statusColor = Colors.blue;
      } else if (isReady) {
        statusText = 'Món đã sẵn sàng!';
        statusColor = Colors.teal;
      } else if (isServed) {
        statusText = 'Đã phục vụ, chờ tính tiền';
        statusColor = Colors.purple;
      }

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.table_restaurant_rounded, color: cs.onErrorContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.name,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Đang phục vụ',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Order Items List
              const Text('Danh sách món:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeOrder.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = activeOrder.items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text('${item.quantity}×', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.dish.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                if (item.note?.isNotEmpty == true)
                                  Text(item.note!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (isReady)
                FilledButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Xác nhận đã phục vụ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: () async {
                    await orderProvider.updateStatus(activeOrder.id, OrderStatus.served);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật: Bàn đang chờ thu ngân thanh toán')),
                      );
                    }
                  },
                )
              else if (isServed)
                FilledButton.icon(
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text('Nhắc Thu Ngân thanh toán'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.outlineVariant,
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng báo lại với Thu Ngân để nhận tiền')),
                    );
                  },
                )
              else
                FilledButton.icon(
                  icon: const Icon(Icons.soup_kitchen_rounded),
                  label: const Text('Bếp đang xử lý...'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.outlineVariant,
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: null, // Disabled
                ),
            ],
          ),
        ),
      );
    },
  );
}
