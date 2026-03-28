import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/category_model.dart';
import '../providers/menu_provider.dart';
import '../providers/table_provider.dart';
import '../models/table_model.dart';
import '../services/database_service.dart';

/// Trang Menu của Khách – mở khi quét mã QR
/// URL: /menu?tableId=table_3&sessionId=table_3_0930
class CustomerMenuPage extends StatefulWidget {
  final String tableId;
  final String sessionId;

  const CustomerMenuPage({
    super.key,
    required this.tableId,
    required this.sessionId,
  });

  @override
  State<CustomerMenuPage> createState() => _CustomerMenuPageState();
}

class _CustomerMenuPageState extends State<CustomerMenuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<DishModel, int> _cart = {};
  bool _isOrdering = false;
  String _selectedCategory = '';
  final _db = DatabaseService();

  String? _customerId;
  bool _isLoadingId = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initCustomerId();
  }

  Future<void> _initCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('customer_device_id');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString('customer_device_id', id);
    }
    if (mounted) {
      setState(() {
        _customerId = id;
        _isLoadingId = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _totalPrice =>
      _cart.entries.fold(0, (sum, e) => sum + (e.key.price * e.value));

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _isOrdering = true);

    final items = _cart.entries
        .map((e) => OrderItem(dish: e.key, quantity: e.value))
        .toList();

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OrderType.dine_in,
      tableId: widget.tableId,
      sessionId: widget.sessionId,
      customerId: _customerId, // Gắn ID định danh máy
      items: items,
      totalPrice: _totalPrice,
      status: OrderStatus.pending,
    );

    await _db.placeOrder(order);

    // Cập nhật bàn sang trạng thái occupied
    if (mounted) {
      try {
        await context
            .read<TableProvider>()
            .updateStatus(widget.tableId, TableStatus.occupied);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _cart.clear();
        _isOrdering = false;
      });
      _tabController.animateTo(1); // Chuyển sang tab Đơn hàng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã gửi đơn! Phục vụ sẽ xác nhận ngay.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.restaurant_rounded, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vị Lai Quán',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(_tableNameFromId(widget.tableId),
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            const Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Menu'),
            const Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Đơn hàng'),
            const Tab(icon: Icon(Icons.history_rounded), text: 'Lịch sử HD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_isLoadingId)
            const Center(child: CircularProgressIndicator())
          else ...[
            _MenuTab(
              cart: _cart,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
              onAdd: (d) => setState(() => _cart[d] = (_cart[d] ?? 0) + 1),
              onRemove: (d) => setState(() {
                if ((_cart[d] ?? 0) <= 1) {
                  _cart.remove(d);
                } else {
                  _cart[d] = _cart[d]! - 1;
                }
              }),
            ),
            _OrderStatusTab(
              tableId: widget.tableId,
              customerId: _customerId ?? '',
              db: _db,
            ),
            _InvoiceHistoryTab(
              tableId: widget.tableId,
              customerId: _customerId ?? '',
              db: _db,
            ),
          ],
        ],
      ),
      // Bottom cart bar
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Cart summary
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_cartCount món đã chọn',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                          Text(
                            '${_formatPrice(_totalPrice)}đ',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                    // Order button
                    FilledButton.icon(
                      onPressed: _isOrdering ? null : _placeOrder,
                      icon: _isOrdering
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: const Text('Gửi đơn'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _tableNameFromId(String id) {
    // table_1 → Bàn 1
    final num = id.replaceAll('table_', '');
    return 'Bàn $num';
  }

  String _formatPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

// ── Tab 1: Menu ───────────────────────────────────────────────────────────────
class _MenuTab extends StatelessWidget {
  final Map<DishModel, int> cart;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;
  final void Function(DishModel) onAdd;
  final void Function(DishModel) onRemove;

  const _MenuTab({
    required this.cart,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final cs = Theme.of(context).colorScheme;

    final categories = [
      const CategoryModel(id: '', name: 'Tất cả'),
      ...CategoryModel.defaults,
    ];

    var dishes = menuProvider.allItems.where((d) => d.isAvailable).toList();
    if (selectedCategory.isNotEmpty) {
      dishes = dishes.where((d) => d.category == selectedCategory).toList();
    }

    return Column(
      children: [
        // Category filter
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final isSelected = cat.id == selectedCategory;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Dish list
        Expanded(
          child: dishes.isEmpty
              ? Center(
                  child: Text('Không có món nào',
                      style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: dishes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final dish = dishes[i];
                    final qty = cart[dish] ?? 0;
                    return _DishCard(
                        dish: dish, qty: qty, onAdd: onAdd, onRemove: onRemove);
                  },
                ),
        ),
      ],
    );
  }
}

class _DishCard extends StatelessWidget {
  final DishModel dish;
  final int qty;
  final void Function(DishModel) onAdd;
  final void Function(DishModel) onRemove;

  const _DishCard(
      {required this.dish,
      required this.qty,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: dish.imageUrl.isNotEmpty
                  ? Image.network(dish.imageUrl,
                      width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(cs))
                  : _imgPlaceholder(cs),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(dish.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      if (dish.isBestSeller)
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  if (dish.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(dish.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_fmtPrice(dish.price)}đ',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: cs.primary),
                      ),
                      // Qty controls
                      Row(
                        children: [
                          if (qty > 0) ...[
                            _QtyBtn(
                              icon: Icons.remove_rounded,
                              color: cs.error,
                              onTap: () => onRemove(dish),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('$qty',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: cs.primary)),
                            ),
                          ],
                          _QtyBtn(
                            icon: Icons.add_rounded,
                            color: cs.primary,
                            onTap: () => onAdd(dish),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder(ColorScheme cs) => Container(
        width: 72,
        height: 72,
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.fastfood_rounded, color: cs.outlineVariant, size: 32),
      );

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── Tab 2: Order Status ───────────────────────────────────────────────────────
class _OrderStatusTab extends StatelessWidget {
  final String tableId;
  final String customerId;
  final DatabaseService db;

  const _OrderStatusTab({required this.tableId, required this.customerId, required this.db});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<OrderModel>>(
      stream: db.getOrdersByCustomerAndTable(customerId, tableId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snap.data!
            .where((o) =>
                o.status != OrderStatus.completed &&
                o.status != OrderStatus.cancelled)
            .toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: cs.outlineVariant),
                const SizedBox(height: 16),
                Text('Chưa có đơn hàng nào\nHãy chọn món từ tab Menu!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _OrderBatch(order: orders[i], batchNo: i + 1),
        );
      },
    );
  }
}

class _OrderBatch extends StatelessWidget {
  final OrderModel order;
  final int batchNo;

  const _OrderBatch({required this.order, required this.batchNo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (statusColor, statusIcon, statusText) = _statusInfo(order.status, cs);

    return Card(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: statusColor),
                ),
                const Spacer(),
                Text('Đợt $batchNo',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text('${item.quantity}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                        fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.dish.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _statusInfo(OrderStatus s, ColorScheme cs) =>
      switch (s) {
        OrderStatus.pending => (
            Colors.orange,
            Icons.hourglass_empty_rounded,
            'Chờ xác nhận'
          ),
        OrderStatus.preparing => (
            Colors.blue,
            Icons.soup_kitchen_rounded,
            'Bếp đang làm'
          ),
        OrderStatus.ready => (
            Colors.teal,
            Icons.room_service_rounded,
            'Đã xong – Chờ phục vụ'
          ),
        OrderStatus.served => (
            Colors.purple,
            Icons.check_circle_rounded,
            'Đã được phục vụ'
          ),
        _ => (Colors.grey, Icons.info_outline_rounded, s.name),
      };
}

// ── Tab 3: Invoice ────────────────────────────────────────────────────────────
class _InvoiceTab extends StatelessWidget {
  final String tableId;
  final String customerId;
  final DatabaseService db;

  const _InvoiceTab({required this.tableId, required this.customerId, required this.db});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<OrderModel>>(
      stream: db.getOrdersByCustomerAndTable(customerId, tableId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snap.data!;
        if (allOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined,
                    size: 64, color: cs.outlineVariant),
                const SizedBox(height: 16),
                Text('Chưa có hóa đơn',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 15)),
              ],
            ),
          );
        }

        // Tổng hợp tất cả món đã được phục vụ hoặc hoàn thành TRONG 12 GIỜ QUA (chống dính đơn cũ)
        final now = DateTime.now();
        final billingOrders = allOrders
            .where((o) =>
                (o.status == OrderStatus.served ||
                 o.status == OrderStatus.completed) &&
                now.difference(o.createdAt).inHours < 12)
            .toList();

        final isPaid = allOrders.any((o) => o.status == OrderStatus.completed && now.difference(o.createdAt).inHours < 12);

        // Gom tất cả items
        final Map<String, _BillLine> billMap = {};
        for (final order in billingOrders) {
          for (final item in order.items) {
            final key = item.dish.id;
            if (billMap.containsKey(key)) {
              billMap[key] = _BillLine(
                name: item.dish.name,
                unitPrice: item.dish.price,
                qty: billMap[key]!.qty + item.quantity,
              );
            } else {
              billMap[key] = _BillLine(
                name: item.dish.name,
                unitPrice: item.dish.price,
                qty: item.quantity,
              );
            }
          }
        }

        final billLines = billMap.values.toList();
        final total =
            billLines.fold(0.0, (s, l) => s + l.unitPrice * l.qty);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🍽️ Vị Lai Quán',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Hóa đơn – ${_tableName(tableId)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Status badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isPaid ? Colors.green : Colors.orange),
                  ),
                  child: Text(
                    isPaid ? '✅ Đã thanh toán' : '⏳ Chưa thanh toán',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isPaid ? Colors.green : Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bill lines
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...billLines.map((line) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(child: Text(line.name)),
                                Text(
                                  '${line.qty} × ${_fmtPrice(line.unitPrice)}đ',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '${_fmtPrice(line.unitPrice * line.qty)}đ',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        children: [
                          const Text('TỔNG CỘNG',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          const Spacer(),
                          Text(
                            '${_fmtPrice(total)}đ',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: cs.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (!isPaid && billingOrders.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Hóa đơn sẽ hiển thị sau khi phục vụ đã mang món ra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _tableName(String id) {
    final num = id.replaceAll('table_', '');
    return 'Bàn $num';
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _InvoiceHistoryTab extends StatefulWidget {
  final String tableId;
  final String customerId;
  final DatabaseService db;

  const _InvoiceHistoryTab({
    required this.tableId,
    required this.customerId,
    required this.db,
  });

  @override
  State<_InvoiceHistoryTab> createState() => _InvoiceHistoryTabState();
}

class _InvoiceHistoryTabState extends State<_InvoiceHistoryTab> {
  DateTimeRange? _selectedDateRange;

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _tableName(String id) {
    final num = id.replaceAll('table_', '');
    return 'Bàn $num';
  }

  String _fmtPrice(double p) {
    final s = p.toInt().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header bộ lọc
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedDateRange == null
                      ? 'Lịch sử ăn uống'
                      : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _selectedDateRange = null),
                ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Chọn ngày'),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    initialDateRange: _selectedDateRange,
                  );
                  if (range != null) {
                    setState(() => _selectedDateRange = range);
                  }
                },
              )
            ],
          ),
        ),
        const Divider(height: 1),

        // Danh sách
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
            stream: widget.db.getAllOrdersByCustomer(widget.customerId),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allOrders = snap.data!;
              if (allOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded,
                          size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 16),
                      Text('Chưa có lịch sử ăn uống',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 15)),
                    ],
                  ),
                );
              }

              // 1. Phân loại theo bộ lọc thời gian
              List<OrderModel> validOrders = allOrders;
              if (_selectedDateRange != null) {
                final startDate = _selectedDateRange!.start;
                final endDate =
                    _selectedDateRange!.end.add(const Duration(days: 1));
                validOrders = allOrders
                    .where((o) =>
                        o.createdAt.isAfter(startDate) &&
                        o.createdAt.isBefore(endDate))
                    .toList();
              }

              // Lọc chỉ lấy món đã phục vụ/hoàn thành
              validOrders = validOrders
                  .where((o) =>
                      o.status == OrderStatus.served ||
                      o.status == OrderStatus.completed)
                  .toList();

              if (validOrders.isEmpty) {
                return const Center(
                    child: Text('Không có đơn hàng nào thỏa mãn'));
              }

              // 2. Gom nhóm theo Ngày -> sau đó theo Bàn
              final Map<String, Map<String, List<OrderModel>>> grouped = {};
              for (var o in validOrders) {
                final dateStr = _formatDate(o.createdAt);
                final tbId = o.tableId ?? 'online';

                grouped.putIfAbsent(dateStr, () => {});
                grouped[dateStr]!.putIfAbsent(tbId, () => []).add(o);
              }

              // Sort chuỗi ngày (mới nhất lên đầu)
              final sortedDates = grouped.keys.toList()
                ..sort((a, b) {
                  final pA = a.split('/');
                  final pB = b.split('/');
                  final dA = DateTime(int.parse(pA[2]), int.parse(pA[1]), int.parse(pA[0]));
                  final dB = DateTime(int.parse(pB[2]), int.parse(pB[1]), int.parse(pB[0]));
                  return dB.compareTo(dA);
                });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedDates.length,
                itemBuilder: (context, i) {
                  final date = sortedDates[i];
                  final tableMap = grouped[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Ngày
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          '📅 Ngày $date',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: cs.primary),
                        ),
                      ),
                      // Các hoá đơn trong ngày
                      ...tableMap.entries.map((e) =>
                          _buildSingleInvoiceCard(date, e.key, e.value, cs)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleInvoiceCard(
      String dateStr, String tbId, List<OrderModel> tOrders, ColorScheme cs) {
    if (tOrders.isEmpty) return const SizedBox();

    final isPaid = tOrders.any((o) => o.status == OrderStatus.completed);
    final Map<String, _BillLine> billMap = {};
    for (final order in tOrders) {
      for (final item in order.items) {
        final key = item.dish.id;
        if (billMap.containsKey(key)) {
          billMap[key] = _BillLine(
            name: item.dish.name,
            unitPrice: item.dish.price,
            qty: billMap[key]!.qty + item.quantity,
          );
        } else {
          billMap[key] = _BillLine(
            name: item.dish.name,
            unitPrice: item.dish.price,
            qty: item.quantity,
          );
        }
      }
    }

    final billLines = billMap.values.toList();
    final total = billLines.fold(0.0, (s, l) => s + l.unitPrice * l.qty);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bill
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hóa đơn – ${_tableName(tbId)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 15),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? 'Đã thu' : 'Chưa thu',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...billLines.map((line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(line.name)),
                          Text(
                            '${line.qty} × ${_fmtPrice(line.unitPrice)}đ',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${_fmtPrice(line.unitPrice * line.qty)}đ',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  children: [
                    const Text('TỔNG CỘNG',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const Spacer(),
                    Text(
                      '${_fmtPrice(total)}đ',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: cs.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillLine {
  final String name;
  final double unitPrice;
  final int qty;
  const _BillLine(
      {required this.name, required this.unitPrice, required this.qty});
}
