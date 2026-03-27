import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';

/// Màn hình quản lý đơn hàng – MD3, tab Tại bàn / Online
class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_bar_rounded), text: 'Tại bàn'),
            Tab(icon: Icon(Icons.delivery_dining_rounded), text: 'Online (GPS)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OrderList(stream: _db.getOrders(type: OrderType.dine_in), db: _db),
          _OrderList(stream: _db.getOrders(type: OrderType.online), db: _db),
        ],
      ),
    );
  }
}

// ── Order list per tab ────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final Stream<List<OrderModel>> stream;
  final DatabaseService db;

  const _OrderList({required this.stream, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text('Không có đơn hàng',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) =>
              _OrderCard(order: orders[i], db: db),
        );
      },
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final DatabaseService db;

  const _OrderCard({required this.order, required this.db});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status, cs);

    return Card(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.type == OrderType.dine_in
                          ? '🪑 ${order.tableId ?? "Bàn?"}'
                          : '🛵 Giao hàng',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    if (order.location != null && order.location!.address.isNotEmpty)
                      Text(order.location!.address,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Text('${item.quantity}×',
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(item.dish.name)),
                          Text(
                              '${_formatPrice(item.dish.price * item.quantity)}đ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          // Footer: total + action
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Text('Tổng: ${_formatPrice(order.totalPrice)}đ',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              _StatusDropdown(order: order, db: db),
            ]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - '
        '${dt.day}/${dt.month}/${dt.year}';
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
}

// ── Status dropdown ───────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final OrderModel order;
  final DatabaseService db;

  const _StatusDropdown({required this.order, required this.db});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<OrderStatus>(
      value: order.status,
      underline: const SizedBox(),
      isDense: true,
      items: OrderStatus.values
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(_statusLabel(s),
                    style: TextStyle(
                        color:
                            _statusColor(s, Theme.of(context).colorScheme),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
      onChanged: (s) {
        if (s != null) db.updateOrderStatus(order.id, s);
      },
    );
  }
}

Color _statusColor(OrderStatus s, ColorScheme cs) {
  return switch (s) {
    OrderStatus.pending => Colors.orange,
    OrderStatus.preparing => Colors.blue,
    OrderStatus.ready => Colors.teal,
    OrderStatus.completed => Colors.green,
    OrderStatus.cancelled => cs.error,
  };
}

String _statusLabel(OrderStatus s) {
  return switch (s) {
    OrderStatus.pending => 'Chờ xử lý',
    OrderStatus.preparing => 'Đang làm',
    OrderStatus.ready => 'Sẵn sàng',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
  };
}
