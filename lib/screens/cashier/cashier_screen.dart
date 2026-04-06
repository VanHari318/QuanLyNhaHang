import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/table_provider.dart';
import '../../models/order_model.dart';
import '../../models/table_model.dart';
import '../../models/user_model.dart';
import '../../utils/logout_helper.dart';

/// Màn hình thu ngân – dùng OrderModel API mới (dish thay foodItem, tableId thay tableNumber)
=======
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../theme/role_themes.dart';
import '../../utils/logout_helper.dart';
import '../profile/profile_screen.dart';

/// Màn hình thu ngân – FinTech Clean (Emerald)
>>>>>>> 6690387 (sua loi)
class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final orderProvider = Provider.of<OrderProvider>(context);
<<<<<<< HEAD
    final tableProvider = Provider.of<TableProvider>(context);
    final cs = Theme.of(context).colorScheme;
=======
>>>>>>> 6690387 (sua loi)

    final servedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.served)
        .toList();

<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu Ngân'),
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
      body: servedOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Không có đơn nào chờ thanh toán',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: servedOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = servedOrders[index];
                // tableId hoặc "Online"
                final tableLabel = order.tableId ?? 'Online';
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.table_bar_rounded,
                          color: Colors.green),
                    ),
                    title: Text(tableLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        'Tổng: ${_formatPrice(order.totalPrice)}đ\n${order.items.length} món'),
                    isThreeLine: true,
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        await orderProvider.updateStatus(
                            order.id, OrderStatus.completed);
                        // Trả bàn về trạng thái trống nếu dine-in
                        if (order.tableId != null) {
                          try {
                            final table = tableProvider.tables.firstWhere(
                                (t) => t.id == order.tableId);
                            await tableProvider.updateStatus(
                                table.id, TableStatus.available);
                          } catch (_) {}
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✅ Thanh toán thành công')),
                          );
                        }
                      },
                      child: const Text('Thanh toán'),
                    ),
                    onTap: () => _showDetails(context, order),
                  ),
                );
              },
            ),
    );
  }

  void _showDetails(BuildContext context, OrderModel order) {
    final tableLabel = order.tableId ?? 'Online';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Chi tiết – $tableLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                      '${item.quantity}× ${item.dish.name}  –  ${_formatPrice(item.dish.price * item.quantity)}đ'),
                )),
            const Divider(),
            Text('Tổng: ${_formatPrice(order.totalPrice)}đ',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
=======
    // Gộp đơn theo bàn (Dine-in grouped, Online separate)
    final Map<String, List<OrderModel>> groups = {};
    for (var o in servedOrders) {
      final key = o.tableId ?? 'online_${o.id}';
      if (!groups.containsKey(key)) groups[key] = [];
      groups[key]!.add(o);
    }
    final groupKeys = groups.keys.toList();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: CashierTheme.background,
      appBar: _buildAppBar(context, isAdmin, servedOrders.length),
      body: RefreshIndicator(
        color: CashierTheme.primary,
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: servedOrders.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, groupKeys, groups, orderProvider),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isAdmin, int pendingCount) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        color: Colors.white,
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
                        color: CashierTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: CashierTheme.primary, size: 18),
                    ),
                  ),
                if (isAdmin) const SizedBox(width: 12),
                // Icon + Title
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CashierTheme.primary, CashierTheme.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Thu Ngân',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Color(0xFF2D3436))),
                    if (pendingCount > 0)
                      Text('$pendingCount đơn chờ thanh toán',
                          style: const TextStyle(
                              color: CashierTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    if (pendingCount == 0)
                      Text('Không có đơn chờ',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                _iconBtn(
                  Icons.manage_accounts_rounded,
                  CashierTheme.primary,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen())),
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  Icons.power_settings_new_rounded,
                  Colors.red.shade400,
                  () => LogoutHelper.showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ),
>>>>>>> 6690387 (sua loi)
      ),
    );
  }

<<<<<<< HEAD
  String _formatPrice(double p) {
=======
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
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
                  color: CashierTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 64,
                  color: CashierTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text('Không có đơn chờ thanh toán',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Color(0xFF2D3436))),
              const SizedBox(height: 8),
              Text('Kéo xuống để làm mới danh sách',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  // ── ORDER LIST ─────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, List<String> keys,
      Map<String, List<OrderModel>> groups, OrderProvider orderProvider) {
    double totalPending = 0;
    for (var list in groups.values) {
      for (var o in list) {
        totalPending += o.totalPrice;
      }
    }

    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [CashierTheme.primary, CashierTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CashierTheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Text('Tổng cần thu:',
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const Spacer(),
              Text(
                '${_fmtPrice(totalPending)}đ',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final key = keys[index];
              final orders = groups[key]!;
              return _PaymentCard(
                orders: orders,
                orderProvider: orderProvider,
                onShowDetails: () => _showDetails(context, orders, key),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── DETAIL DIALOG ──────────────────────────────────────────────────────────
  void _showDetails(BuildContext context, List<OrderModel> orders, String key) {
    final tableLabel = key.startsWith('online_') ? 'Đơn Online' : key;
    final allItems = orders.expand((o) => o.items).toList();
    final totalPrice = orders.fold<double>(0, (sum, o) => sum + o.totalPrice);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CashierTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: CashierTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Chi tiết – $tableLabel',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = allItems[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: CashierTheme.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('${item.quantity}',
                                  style: const TextStyle(
                                      color: CashierTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(item.dish.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                          Text(
                              '${_fmtPrice(item.dish.price * item.quantity)}đ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('${_fmtPrice(totalPrice)}đ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: CashierTheme.primary)),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: CashierTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtPrice(double p) {
>>>>>>> 6690387 (sua loi)
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}
<<<<<<< HEAD
=======

// ── PAYMENT CARD WIDGET ────────────────────────────────────────────────────
class _PaymentCard extends StatefulWidget {
  final List<OrderModel> orders;
  final OrderProvider orderProvider;
  final VoidCallback onShowDetails;
  const _PaymentCard({
    required this.orders,
    required this.orderProvider,
    required this.onShowDetails,
  });

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _isPaying = false;

  // ── Payment method dialog ─────────────────────────────────────────────────
  Future<void> _showPaymentDialog() async {
    final methods = [
      _PayMethod(
          icon: Icons.money_rounded,
          label: 'Tiền mặt',
          color: const Color(0xFF00B894),
          value: 'cash'),
      _PayMethod(
          icon: Icons.credit_card_rounded,
          label: 'Thẻ ngân hàng',
          color: const Color(0xFF0984E3),
          value: 'card'),
      _PayMethod(
          icon: Icons.phone_android_rounded,
          label: 'Ví điện tử',
          color: const Color(0xFF6C5CE7),
          value: 'ewallet'),
    ];

    final totalPrice = widget.orders.fold<double>(0, (sum, o) => sum + o.totalPrice);

    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const Text(
                'Chọn phương thức thanh toán',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                'Tổng hóa đơn: ${_fmtPrice(totalPrice)}đ',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ...methods.map((m) => _PayMethodTile(
                    method: m,
                    onTap: () => Navigator.pop(ctx, m.value),
                  )),
            ],
          ),
        ),
      ),
    );

    if (chosen == null || !mounted) return;

    setState(() => _isPaying = true);
    
    try {
      // Thực hiện thanh toán hàng loạt (batch update)
      await Future.wait(widget.orders.map((o) => 
        widget.orderProvider.updateStatus(o.id, OrderStatus.completed)));

      if (mounted) {
        final label = methods.firstWhere((m) => m.value == chosen).label;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Thanh toán $label thành công cho ${widget.orders.length} đơn! 🎉'),
              ],
            ),
            backgroundColor: CashierTheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableLabel = widget.orders.first.tableId ?? 'Online';
    final isOnline = widget.orders.first.tableId == null;
    final totalPrice = widget.orders.fold<double>(0, (sum, o) => sum + o.totalPrice);
    final totalItems = widget.orders.fold<int>(0, (sum, o) => sum + o.items.length);

    return GestureDetector(
      onTap: widget.onShowDetails,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: const Border(
            left: BorderSide(color: CashierTheme.primary, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: CashierTheme.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF6C5CE7).withValues(alpha: 0.1)
                      : CashierTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOnline
                      ? Icons.delivery_dining_rounded
                      : Icons.point_of_sale_rounded,
                  color: isOnline
                      ? const Color(0xFF6C5CE7)
                      : CashierTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tableLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Color(0xFF2D3436))),
                    const SizedBox(height: 3),
                    Text('$totalItems món (${widget.orders.length} đợt gọi)',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              // Amount + Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_fmtPrice(totalPrice)}đ',
                    style: const TextStyle(
                      color: CashierTheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isPaying ? null : _showPaymentDialog,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _isPaying
                            ? null
                            : const LinearGradient(
                                colors: [
                                  CashierTheme.primary,
                                  CashierTheme.primaryLight
                                ],
                              ),
                        color: _isPaying ? Colors.grey.shade200 : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _isPaying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: CashierTheme.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payments_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Thanh toán',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

// ── PAYMENT METHOD MODEL ───────────────────────────────────────────────────
class _PayMethod {
  final IconData icon;
  final String label;
  final Color color;
  final String value;
  const _PayMethod(
      {required this.icon,
      required this.label,
      required this.color,
      required this.value});
}

// ── PAYMENT METHOD TILE ────────────────────────────────────────────────────
class _PayMethodTile extends StatelessWidget {
  final _PayMethod method;
  final VoidCallback onTap;
  const _PayMethodTile({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: method.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: method.color.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: method.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, color: method.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                method.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: method.color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: method.color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
>>>>>>> 6690387 (sua loi)
