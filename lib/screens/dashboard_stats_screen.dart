import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/order_model.dart';

/// Dashboard thống kê doanh thu – MD3
class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  final _db = DatabaseService();
  DateTime _selectedDate = DateTime.now();

  Future<double>? _todayRevenue;
  Future<double>? _monthRevenue;
  Future<List<MapEntry<String, int>>>? _topDishes;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final now = DateTime.now();
    setState(() {
      _todayRevenue = _db.getRevenueForDate(_selectedDate);
      _monthRevenue = _getMonthRevenue(now);
      _topDishes = _db.getTopDishes(limit: 5);
    });
  }

  Future<double> _getMonthRevenue(DateTime month) async {
    double total = 0;
    for (int d = 1; d <= month.day; d++) {
      total += await _db.getRevenueForDate(DateTime(month.year, month.month, d));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê Doanh Thu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Chọn ngày',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.today_rounded, color: cs.onPrimaryContainer, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Revenue cards
              Row(children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.today_rounded,
                    label: 'Hôm nay',
                    color: cs.primary,
                    future: _todayRevenue!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Tháng này',
                    color: Colors.teal,
                    future: _monthRevenue!,
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Top dishes
              Text('🏆 Top 5 Món Bán Chạy',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              FutureBuilder<List<MapEntry<String, int>>>(
                future: _topDishes,
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Chưa có dữ liệu đơn hàng hoàn thành',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                    );
                  }
                  final maxQty = snap.data!.first.value;
                  return Column(
                    children: List.generate(snap.data!.length, (i) {
                      final entry = snap.data![i];
                      final ratio = maxQty > 0 ? entry.value / maxQty : 0.0;
                      final colors = [
                        Colors.amber,
                        Colors.grey,
                        Colors.brown,
                        cs.primary,
                        cs.secondary,
                      ];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            // Rank
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: colors[i].withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('#${i + 1}',
                                    style: TextStyle(
                                        color: colors[i],
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(colors[i]),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${entry.value} suất',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ]),
                        ),
                      );
                    }),
                  );
                },
              ),

              // Realtime orders summary
              const SizedBox(height: 24),
              Text('📊 Trạng thái đơn hàng hôm nay',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              StreamBuilder<List<OrderModel>>(
                stream: _db.getOrders(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final today = snap.data!.where((o) {
                    final now = DateTime.now();
                    return o.createdAt.year == now.year &&
                        o.createdAt.month == now.month &&
                        o.createdAt.day == now.day;
                  }).toList();

                  final counts = <OrderStatus, int>{};
                  for (final o in today) {
                    counts[o.status] = (counts[o.status] ?? 0) + 1;
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: OrderStatus.values.map((s) {
                      final count = counts[s] ?? 0;
                      return _StatusBadge(status: s, count: count);
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _selectedDate = picked;
      _loadStats();
    }
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Future<double> future;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 10),
            FutureBuilder<double>(
              future: future,
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2));
                }
                return Text(
                  _formatPrice(snap.data!) + 'đ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color, fontWeight: FontWeight.w800),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  final int count;

  const _StatusBadge({required this.status, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(status, cs);
    final label = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$count',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
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
    OrderStatus.pending => 'Chờ',
    OrderStatus.preparing => 'Đang làm',
    OrderStatus.ready => 'Sẵn sàng',
    OrderStatus.completed => 'Hoàn thành',
    OrderStatus.cancelled => 'Đã hủy',
  };
}
