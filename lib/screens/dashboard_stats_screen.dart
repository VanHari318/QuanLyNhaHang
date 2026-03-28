import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/order_model.dart';
import '../components/dashboard_card.dart';
import '../components/chart_view.dart';

/// Dashboard thống kê doanh thu – MD3 enhanced with charts
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
  Future<List<MapEntry<String, double>>>? _weekRevenue;

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
      _weekRevenue = _getLast7DaysRevenue(now);
    });
  }

  Future<double> _getMonthRevenue(DateTime month) async {
    double total = 0;
    for (int d = 1; d <= month.day; d++) {
      total +=
          await _db.getRevenueForDate(DateTime(month.year, month.month, d));
    }
    return total;
  }

  Future<List<MapEntry<String, double>>> _getLast7DaysRevenue(
      DateTime today) async {
    final result = <MapEntry<String, double>>[];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final rev = await _db.getRevenueForDate(day);
      result.add(MapEntry('${day.day}/${day.month}', rev));
    }
    return result;
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
              // Date chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.today_rounded,
                      color: cs.onPrimaryContainer, size: 16),
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

              // KPI cards row
              Row(children: [
                Expanded(
                  child: FutureBuilder<double>(
                    future: _todayRevenue,
                    builder: (_, snap) => DashboardCard(
                      icon: Icons.today_rounded,
                      title: 'Hôm nay',
                      value: '${_fmtPrice(snap.data ?? 0)}đ',
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<double>(
                    future: _monthRevenue,
                    builder: (_, snap) => DashboardCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Tháng này',
                      value: '${_fmtPrice(snap.data ?? 0)}đ',
                      color: Colors.teal,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Line Chart: 7-day revenue trend ──────────────────────
              _ChartCard(
                title: '📈 Doanh thu 7 ngày qua',
                child: FutureBuilder<List<MapEntry<String, double>>>(
                  future: _weekRevenue,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SimpleLineChart(
                      points: snap.data!,
                      lineColor: cs.primary,
                      height: 140,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Bar Chart: Top dishes ─────────────────────────────────
              _ChartCard(
                title: '🏆 Top 5 Món Bán Chạy',
                child: FutureBuilder<List<MapEntry<String, int>>>(
                  future: _topDishes,
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text('Chưa có dữ liệu',
                              style:
                                  TextStyle(color: cs.onSurfaceVariant)),
                        ),
                      );
                    }
                    return SimpleBarChart(
                      data: snap.data!
                          .map((e) => MapEntry(e.key, e.value.toDouble()))
                          .toList(),
                      barColor: cs.primary,
                      unit: ' suất',
                      height: 160,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Order status summary ──────────────────────────────────
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
                  final now = DateTime.now();
                  final today = snap.data!.where((o) =>
                      o.createdAt.year == now.year &&
                      o.createdAt.month == now.month &&
                      o.createdAt.day == now.day).toList();

                  final counts = <OrderStatus, int>{};
                  for (final o in today) {
                    counts[o.status] = (counts[o.status] ?? 0) + 1;
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: OrderStatus.values
                        .map((s) => _StatusBadge(
                            status: s, count: counts[s] ?? 0))
                        .toList(),
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

  String _fmtPrice(double price) {
    final s = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── Chart card wrapper ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

Color _statusColor(OrderStatus s, ColorScheme cs) => switch (s) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.preparing => Colors.blue,
      OrderStatus.ready => Colors.teal,
      OrderStatus.served => Colors.purple,
      OrderStatus.completed => Colors.green,
      OrderStatus.cancelled => cs.error,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Chờ',
      OrderStatus.preparing => 'Đang làm',
      OrderStatus.ready => 'Sẵn sàng',
      OrderStatus.served => 'Phục vụ xong',
      OrderStatus.completed => 'Hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
    };
