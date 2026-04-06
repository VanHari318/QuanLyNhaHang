<<<<<<< HEAD
import 'package:flutter/material.dart';
=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
>>>>>>> 6690387 (sua loi)
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
<<<<<<< HEAD
import '../../utils/logout_helper.dart';

/// Màn hình bếp – dùng OrderModel API mới (item.dish thay item.foodItem)
=======
import '../../theme/role_themes.dart';
import '../../utils/logout_helper.dart';
import '../profile/profile_screen.dart';

/// Màn hình bếp – Dark Command (Deep Orange on Charcoal)
>>>>>>> 6690387 (sua loi)
class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final orderProvider = Provider.of<OrderProvider>(context);
<<<<<<< HEAD
    final cs = Theme.of(context).colorScheme;
=======
>>>>>>> 6690387 (sua loi)

    final activeOrders = orderProvider.orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.preparing)
<<<<<<< HEAD
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bếp'),
        leading: isAdmin
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),
      body: activeOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Không có đơn hàng đang chờ',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: activeOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final order = activeOrders[i];
                final tableLabel = order.tableId ?? 'Online';
                final isPending = order.status == OrderStatus.pending;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tableLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            _StatusChip(status: order.status),
                          ],
                        ),
                        const Divider(height: 16),
                        // Items – dùng item.dish thay item.foodItem
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Text('${item.quantity}×',
                                    style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.dish.name)),
                                if (item.note?.isNotEmpty == true)
                                  Text('📝 ${item.note}',
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 12)),
                              ]),
                            )),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: isPending
                              ? FilledButton.icon(
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Bắt đầu làm'),
                                  onPressed: () => orderProvider.updateStatus(
                                      order.id, OrderStatus.preparing),
                                )
                              : FilledButton.icon(
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Xong'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () => orderProvider.updateStatus(
                                      order.id, OrderStatus.ready),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
=======
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // oldest first

    // Force dark status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ));

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: KitchenTheme.background,
        colorScheme: const ColorScheme.dark(
          primary: KitchenTheme.primary,
          surface: KitchenTheme.surface,
        ),
      ),
      child: Scaffold(
        backgroundColor: KitchenTheme.background,
        appBar: _buildAppBar(context, isAdmin, activeOrders.length),
        body: RefreshIndicator(
          color: KitchenTheme.primary,
          backgroundColor: KitchenTheme.surface,
          onRefresh: () async =>
              await Future.delayed(const Duration(seconds: 1)),
          child: activeOrders.isEmpty
              ? _buildEmpty(context)
              : _buildTicketList(context, activeOrders, orderProvider),
        ),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isAdmin, int activeCount) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        decoration: const BoxDecoration(
          gradient: KitchenTheme.appBarGradient,
          border: Border(
            bottom: BorderSide(
                color: KitchenTheme.surfaceVariant, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (isAdmin)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KitchenTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: KitchenTheme.onBackground, size: 18),
                    ),
                  ),
                if (isAdmin) const SizedBox(width: 12),
                // Flame icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [KitchenTheme.primary, Color(0xFFFF5722)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.whatshot_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Bếp',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: KitchenTheme.onBackground)),
                    Text(
                      activeCount > 0
                          ? '$activeCount đơn đang xử lý'
                          : 'Đang chờ đơn mới',
                      style: TextStyle(
                        color: activeCount > 0
                            ? KitchenTheme.primary
                            : KitchenTheme.onSurfaceDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _darkIconBtn(
                  Icons.badge_rounded,
                  KitchenTheme.onSurfaceDim,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(width: 6),
                _darkIconBtn(
                  Icons.exit_to_app_rounded,
                  Colors.red.shade400,
                  () => LogoutHelper.showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: KitchenTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 150,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: KitchenTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.soup_kitchen_rounded,
                  size: 64,
                  color: KitchenTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Không có đơn hàng đang chờ',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: KitchenTheme.onBackground),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kéo xuống để làm mới',
                style: TextStyle(
                    color: KitchenTheme.onSurfaceDim, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TICKET LIST ────────────────────────────────────────────────────────────
  Widget _buildTicketList(BuildContext context, List<OrderModel> orders,
      OrderProvider orderProvider) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final order = orders[i];
        return _KitchenTicket(order: order, orderProvider: orderProvider);
      },
>>>>>>> 6690387 (sua loi)
    );
  }
}

<<<<<<< HEAD
class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.pending => (Colors.orange, 'Chờ xử lý'),
      OrderStatus.preparing => (Colors.blue, 'Đang làm'),
      OrderStatus.ready => (Colors.teal, 'Sẵn sàng'),
      OrderStatus.served => (Colors.purple, 'Đã phục vụ'),
      _ => (Colors.grey, status.name),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
=======
// ── KITCHEN TICKET WIDGET (Stateful for timer) ────────────────────────────
class _KitchenTicket extends StatefulWidget {
  final OrderModel order;
  final OrderProvider orderProvider;
  const _KitchenTicket({required this.order, required this.orderProvider});

  @override
  State<_KitchenTicket> createState() => _KitchenTicketState();
}

class _KitchenTicketState extends State<_KitchenTicket> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30s to update elapsed display
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _elapsedLabel() {
    final diff = DateTime.now().difference(widget.order.createdAt);
    if (diff.inMinutes < 1) return 'Vừa vào';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    return '${diff.inHours}g${diff.inMinutes % 60}p';
  }

  /// Green < 10min, Amber 10–20min, Red > 20min
  Color _urgencyColor() {
    final mins =
        DateTime.now().difference(widget.order.createdAt).inMinutes;
    if (mins < 10) return const Color(0xFF00B894);
    if (mins < 20) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final tableLabel = widget.order.tableId ?? 'Online';
    final isPending = widget.order.status == OrderStatus.pending;
    final (statusColor, statusLabel) = _statusInfo(widget.order.status);
    final urgency = _urgencyColor();
    final elapsedMins =
        DateTime.now().difference(widget.order.createdAt).inMinutes;

    return Container(
      decoration: KitchenTheme.ticketDecoration,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ticket top accent bar ──────────────────────────────────────
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [urgency, urgency.withValues(alpha: 0.5)],
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Table icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KitchenTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.table_restaurant_rounded,
                    color: KitchenTheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tableLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: KitchenTheme.onBackground,
                      ),
                    ),
                    Text(
                      '${widget.order.items.length} món',
                      style: const TextStyle(
                        color: KitchenTheme.onSurfaceDim,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Elapsed time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: urgency.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: urgency.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        elapsedMins >= 20
                            ? Icons.warning_rounded
                            : Icons.timer_outlined,
                        color: urgency,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _elapsedLabel(),
                        style: TextStyle(
                          color: urgency,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: KitchenTheme.surfaceVariant,
          ),

          // ── Items list ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: widget.order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Quantity badge
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: KitchenTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              color: KitchenTheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dish name
                      Expanded(
                        child: Text(
                          item.dish.name,
                          style: const TextStyle(
                            color: KitchenTheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Note
                      if (item.note?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '📝 ${item.note}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Action Row ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: KitchenTheme.surfaceVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Order time info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vào lúc ${_timeLabel(widget.order.createdAt)}',
                      style: const TextStyle(
                        color: KitchenTheme.onSurfaceDim,
                        fontSize: 11,
                      ),
                    ),
                    if (elapsedMins >= 20)
                      const Text(
                        '⚠️ Quá lâu!',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (isPending)
                  _ActionBtn(
                    icon: Icons.bolt_rounded,
                    label: 'Bắt đầu làm',
                    color: KitchenTheme.primary,
                    onTap: () => widget.orderProvider.updateStatus(
                        widget.order.id, OrderStatus.preparing),
                  )
                else
                  _ActionBtn(
                    icon: Icons.done_all_rounded,
                    label: 'Hoàn thành',
                    color: const Color(0xFF00B894),
                    onTap: () => widget.orderProvider.updateStatus(
                        widget.order.id, OrderStatus.ready),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  (Color, String) _statusInfo(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending =>
        (const Color(0xFFFFB300), 'Chờ xử lý'),
      OrderStatus.preparing =>
        (const Color(0xFF42A5F5), 'Đang làm'),
      OrderStatus.ready =>
        (const Color(0xFF00B894), 'Sẵn sàng'),
      OrderStatus.served =>
        (const Color(0xFFAB47BC), 'Đã phục vụ'),
      _ => (KitchenTheme.onSurfaceDim, status.name),
    };
  }
}

// ── ACTION BUTTON ──────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
>>>>>>> 6690387 (sua loi)
    );
  }
}
