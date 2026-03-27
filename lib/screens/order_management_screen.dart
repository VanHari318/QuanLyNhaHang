import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          _OrderList(
              stream: _db.getOrders(type: OrderType.dine_in), db: _db),
          _OrderList(
              stream: _db.getOrders(type: OrderType.online), db: _db,
              showMap: true),
        ],
      ),
    );
  }
}

// ── Order list per tab ────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final Stream<List<OrderModel>> stream;
  final DatabaseService db;
  final bool showMap;

  const _OrderList({
    required this.stream,
    required this.db,
    this.showMap = false,
  });

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
                    color:
                        Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 12),
                Text('Không có đơn hàng',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (ctx, i) => _FullOrderCard(
            order: orders[i],
            db: db,
            showMap: showMap,
          ),
        );
      },
    );
  }
}

// ── Full order card ───────────────────────────────────────────────────────────
class _FullOrderCard extends StatelessWidget {
  final OrderModel order;
  final DatabaseService db;
  final bool showMap;

  const _FullOrderCard({
    required this.order,
    required this.db,
    this.showMap = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status, cs);

    return Card(
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.type == OrderType.dine_in
                          ? '🪑 ${order.tableId ?? "Tại Bàn"}'
                          : '🛵 Giao hàng online',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (order.location != null &&
                        order.location!.address.isNotEmpty)
                      Text(order.location!.address,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    Text(
                      _formatTime(order.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
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
          // Footer: total + actions
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(children: [
              Text('Tổng: ${_formatPrice(order.totalPrice)}đ',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              // Map button for online orders
              if (showMap &&
                  order.location != null &&
                  order.location!.lat != 0) ...[
                IconButton(
                  icon: const Icon(Icons.map_outlined, size: 20),
                  tooltip: 'Xem bản đồ',
                  onPressed: () => _showMapSheet(context, order),
                  color: Colors.teal,
                ),
                const SizedBox(width: 4),
              ],
              _StatusDropdown(order: order, db: db),
            ]),
          ),
        ],
      ),
    );
  }

  void _showMapSheet(BuildContext context, OrderModel order) {
    final loc = order.location!;
    final lat = loc.lat;
    final lng = loc.lng;
    final osmUrl =
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=16';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.teal, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vị trí khách hàng',
                            style: Theme.of(ctx)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (loc.address.isNotEmpty)
                          Text(loc.address,
                              style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                // Coordinates
                _CoordRow(
                    label: 'Vĩ độ (Lat)', value: lat.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _CoordRow(
                    label: 'Kinh độ (Lng)', value: lng.toStringAsFixed(6)),
                const SizedBox(height: 20),
                // OSM link
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.link_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(osmUrl,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: osmUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã copy link OSM Map!')),
                        );
                        Navigator.pop(ctx);
                      },
                      tooltip: 'Copy link',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Mở OpenStreetMap'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: osmUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '📋 Link đã copy – dán vào trình duyệt để xem bản đồ')),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}'
        ':${dt.minute.toString().padLeft(2, '0')} - '
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

// ── Coordinate row ────────────────────────────────────────────────────────────
class _CoordRow extends StatelessWidget {
  final String label;
  final String value;

  const _CoordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]);
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
                        color: _statusColor(
                            s, Theme.of(context).colorScheme),
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

Color _statusColor(OrderStatus s, ColorScheme cs) => switch (s) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.preparing => Colors.blue,
      OrderStatus.ready => Colors.teal,
      OrderStatus.completed => Colors.green,
      OrderStatus.cancelled => cs.error,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Chờ xử lý',
      OrderStatus.preparing => 'Đang làm',
      OrderStatus.ready => 'Sẵn sàng',
      OrderStatus.completed => 'Hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
    };
