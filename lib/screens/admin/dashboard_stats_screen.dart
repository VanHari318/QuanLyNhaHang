import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/order_model.dart';
import '../../components/dashboard_card.dart';
import '../../components/chart_view.dart';
import '../../theme/admin_theme.dart';

/// Dashboard thống kê doanh thu – Haidilao Premium Dark
class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  final _db = DatabaseService();
  DateTime _selectedDate = DateTime.now();

  Future<DashboardStatsData>? _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _statsFuture = _db.getDetailedDashboardStats(_selectedDate, _selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      appBar: AppBar(
        title: const Text('Thống Kê Doanh Thu'),
        backgroundColor: AdminColors.bgPrimary(context),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_rounded, color: AdminColors.textSecondary(context)),
            tooltip: 'Chọn ngày',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AdminColors.crimson,
        backgroundColor: AdminColors.bgElevated(context),
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
                  color: AdminColors.bgElevated(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminColors.borderDefault(context)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.today_rounded,
                      color: AdminColors.crimson, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: AdminText.bodyMedium(context).copyWith(color: AdminColors.textPrimary(context)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              FutureBuilder<DashboardStatsData>(
                future: _statsFuture,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator(color: AdminColors.crimson)),
                    );
                  }
                  
                  if (snap.hasError) {
                    return _buildErrorWidget(snap.error.toString());
                  }

                  if (!snap.hasData) {
                    return Center(child: Text('Không tìm thấy dữ liệu.', style: TextStyle(color: AdminColors.textSecondary(context))));
                  }

                  final data = snap.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KPI cards row
                      SizedBox(
                        height: 140,
                        child: Row(children: [
                          Expanded(
                            child: DashboardCard(
                              icon: Icons.today_rounded,
                              title: 'Hôm nay',
                              value: '${_fmtPrice(data.todayRevenue)}đ',
                              color: AdminColors.crimson,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardCard(
                              icon: Icons.calendar_month_rounded,
                              title: 'Tháng này',
                              value: '${_fmtPrice(data.monthRevenue)}đ',
                              color: AdminColors.teal,
                              onTap: () => _showMonthlyDetail(data.dailyRevenue),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),

                      // ── Line Chart: 7-day revenue trend ──────────────────────
                        _ChartCard(
                          title: '📈 Doanh thu 7 ngày qua',
                          child: SimpleLineChart(
                            points: data.weeklyRevenueTrend,
                            lineColor: AdminColors.crimsonBright,
                            textColor: AdminColors.textSecondary(context),
                            gridColor: AdminColors.borderMuted(context),
                            height: 140,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Bar Chart: Top dishes ─────────────────────────────────
                      _ChartCard(
                        title: '🏆 Top 5 Món Bán Chạy',
                        child: data.topDishes.isEmpty 
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text('Chưa có dữ liệu tháng này',
                                    style: TextStyle(color: AdminColors.textSecondary(context))),
                              ),
                            )
                          : SimpleBarChart(
                              data: data.topDishes
                                  .map((e) => MapEntry(e.key, e.value.toDouble()))
                                  .toList(),
                              barColor: AdminColors.gold,
                              textColor: AdminColors.textSecondary(context),
                              unit: ' suất',
                              height: 160,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // ── Order status summary ──────────────────────────────────
                      Text('📊 Trạng thái đơn hàng hôm nay',
                          style: AdminText.h2(context)),
                      const SizedBox(height: 12),
                      StreamBuilder<List<OrderModel>>(
                        stream: _db.getOrders(),
                        builder: (ctx, orderSnap) {
                          if (!orderSnap.hasData) {
                            return const Center(child: CircularProgressIndicator(color: AdminColors.crimson));
                          }
                          final todayOrders = orderSnap.data!.where((o) =>
                              o.createdAt.year == _selectedDate.year &&
                              o.createdAt.month == _selectedDate.month &&
                              o.createdAt.day == _selectedDate.day).toList();

                          final counts = <OrderStatus, int>{};
                          for (final o in todayOrders) {
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
                    ],
                  );
                }
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
      builder: (context, child) {
        return Theme(
          data: AdminTheme.darkTheme.copyWith(
            colorScheme: AdminTheme.darkTheme.colorScheme.copyWith(
              primary: AdminColors.crimson,
            ),
          ),
          child: child!,
        );
      },
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: AdminColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Lỗi tải dữ liệu', style: TextStyle(color: AdminColors.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(error, textAlign: TextAlign.center, style: TextStyle(color: AdminColors.textMuted(context), fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: FilledButton.styleFrom(backgroundColor: AdminColors.bgElevated(context), foregroundColor: AdminColors.textPrimary(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthlyDetail(List<MapEntry<String, double>> dailyData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AdminColors.bgPrimary(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminColors.textMuted(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('Doanh thu tháng ${_selectedDate.month}',
                        style: AdminText.h1(context)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AdminColors.textSecondary(context)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _ChartCard(
                      title: 'Biểu đồ thu nhập tháng',
                      child: SimpleLineChart(
                        points: dailyData,
                        lineColor: AdminColors.teal,
                        textColor: AdminColors.textSecondary(context),
                        gridColor: AdminColors.borderMuted(context),
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Bảng kê hàng ngày', 
                      style: AdminText.h2(context)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AdminColors.bgCard(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AdminColors.borderDefault(context)),
                      ),
                      child: Column(
                        children: dailyData.reversed.map((e) => Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AdminColors.teal.withValues(alpha: 0.15),
                                child: Text(e.key, style: const TextStyle(color: AdminColors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              title: Text('Ngày ${e.key}/${_selectedDate.month}', style: TextStyle(color: AdminColors.textPrimary(context))),
                              trailing: Text('${_fmtPrice(e.value)}đ', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminColors.gold)),
                            ),
                            if (dailyData.indexOf(e) != dailyData.length - 1) 
                              Divider(height: 1, indent: 70, color: AdminColors.borderMuted(context)),
                          ],
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chart card wrapper ────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.bgCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.borderDefault(context)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3, 
                height: 16,
                decoration: BoxDecoration(
                  color: AdminColors.crimson,
                  borderRadius: BorderRadius.circular(2),
                )
              ),
              const SizedBox(width: 8),
              Text(title, style: AdminText.h3(context)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
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
    final color = _statusColor(status);
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

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending => AdminColors.warning,
      OrderStatus.preparing => AdminColors.info,
      OrderStatus.ready => AdminColors.teal,
      OrderStatus.served => AdminColors.purple,
      OrderStatus.completed => AdminColors.success,
      OrderStatus.cancelled => AdminColors.error,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Chờ',
      OrderStatus.preparing => 'Đang làm',
      OrderStatus.ready => 'Sẵn sàng',
      OrderStatus.served => 'Phục vụ xong',
      OrderStatus.completed => 'Hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
    };
