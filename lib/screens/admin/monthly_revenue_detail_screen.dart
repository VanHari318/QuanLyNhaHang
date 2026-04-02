import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/order_model.dart';
import '../../components/chart_view.dart';

/// Màn hình chi tiết doanh thu theo tháng - Biểu đồ & Danh sách ngày
class MonthlyRevenueDetailScreen extends StatefulWidget {
  final DateTime month;

  const MonthlyRevenueDetailScreen({super.key, required this.month});

  @override
  State<MonthlyRevenueDetailScreen> createState() => _MonthlyRevenueDetailScreenState();
}

class _MonthlyRevenueDetailScreenState extends State<MonthlyRevenueDetailScreen> {
  final _db = DatabaseService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchMonthlyStats();
  }

  Future<Map<String, dynamic>> _fetchMonthlyStats() async {
    final firstDay = DateTime(widget.month.year, widget.month.month, 1);
    final lastDay = DateTime(widget.month.year, widget.month.month + 1, 0, 23, 59, 59);
    
    final orders = await _db.getOrdersInRange(firstDay, lastDay);
    
    double totalRevenue = 0;
    int totalOrders = 0;
    final dailyMap = <int, double>{};
    
    // Khởi tạo tất cả các ngày trong tháng = 0
    final daysInMonth = lastDay.day;
    for (int i = 1; i <= daysInMonth; i++) {
      dailyMap[i] = 0.0;
    }

    for (final o in orders) {
      if (o.status == OrderStatus.completed) {
        totalRevenue += o.totalPrice;
        dailyMap[o.createdAt.day] = (dailyMap[o.createdAt.day] ?? 0) + o.totalPrice;
      }
      totalOrders++;
    }

    // Chuyển đổi sang list MapEntry cho biểu đồ
    final chartData = dailyMap.entries.map((e) => MapEntry('${e.key}', e.value)).toList();
    
    // Danh sách ngày có doanh thu (sắp xếp giảm dần theo ngày)
    final listData = dailyMap.entries
        .where((e) => e.value > 0)
        .toList()
        ..sort((a, b) => b.key.compareTo(a.key));

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'chartData': chartData,
      'listData': listData,
      'daysInMonth': daysInMonth,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthLabel = 'Tháng ${widget.month.month}/${widget.month.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết $monthLabel'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final totalRevenue = data['totalRevenue'] as double;
          final totalOrders = data['totalOrders'] as int;
          final chartData = data['chartData'] as List<MapEntry<String, double>>;
          final listData = data['listData'] as List<MapEntry<int, double>>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tóm tắt KPI
                _SummaryCard(
                  totalRevenue: totalRevenue,
                  totalOrders: totalOrders,
                  cs: cs,
                ),
                const SizedBox(height: 24),

                // 2. Biểu đồ xu hướng
                Text('📈 Biểu đồ doanh thu hàng ngày',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
                    child: SimpleLineChart(
                      points: chartData,
                      lineColor: Colors.teal,
                      height: 180,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Danh sách chi tiết các ngày
                Text('📋 Danh sách theo ngày',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (listData.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Không có doanh thu trong tháng này'),
                  ))
                else
                  ...listData.map((e) => _DayRevenueTile(
                    day: e.key,
                    month: widget.month.month,
                    revenue: e.value,
                    cs: cs,
                  )),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
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

class _SummaryCard extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final ColorScheme cs;

  const _SummaryCard({required this.totalRevenue, required this.totalOrders, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng doanh thu tháng', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${_fmtPrice(totalRevenue)}đ',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text('$totalOrders đơn hàng', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
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

class _DayRevenueTile extends StatelessWidget {
  final int day;
  final int month;
  final double revenue;
  final ColorScheme cs;

  const _DayRevenueTile({required this.day, required this.month, required this.revenue, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withValues(alpha: 0.1),
          child: Text('$day', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ),
        title: Text('Ngày $day tháng $month', style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text('+${_fmtPrice(revenue)}đ',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
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
