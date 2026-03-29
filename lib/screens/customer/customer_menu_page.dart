import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/dish_model.dart';
import '../../models/order_model.dart';
import '../../models/category_model.dart';
import '../../providers/menu_provider.dart';
import '../../providers/table_provider.dart';
import '../../models/table_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'qr_scanner_screen.dart';
import '../../services/database_service.dart';
import 'dart:math' as math;

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
  String? _customerId;
  bool _isLoadingId = true;
  String _selectedCategory = '';
  final _db = DatabaseService();
  bool _isOrdering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initCustomerId();
  }

  Future<void> _initCustomerId() async {
    // Ưu tiên dùng Auth UID nếu đã đăng nhập khách hàng
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      if (mounted) {
        setState(() {
          _customerId = auth.user!.id;
          _isLoadingId = false;
        });
      }
      return;
    }

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

  bool get _isBrowseMode => widget.tableId.isEmpty;

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;
    if (_isBrowseMode) return;

    // ── GPS Geofencing (15m radius for dine-in) ───────────────────────────
    final config = await _db.getRestaurantConfig().first;
    if (config != null) {
      final restaurantLat = (config['lat'] as num).toDouble();
      final restaurantLng = (config['lng'] as num).toDouble();
      final allowedRadius = (config['radiusMeters'] as num?)?.toDouble() ?? 15.0;

      setState(() => _isOrdering = true);

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
        );
        final distanceM = Geolocator.distanceBetween(restaurantLat, restaurantLng, pos.latitude, pos.longitude);

        if (distanceM > allowedRadius) {
          if (mounted) {
            setState(() => _isOrdering = false);
            _showGpsDialog('Ngoài Phạm Vi Quán', 'Bạn đang cách nhà hàng khoảng ${distanceM.round()}m.', icon: Icons.location_off_rounded, iconColor: Colors.red);
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isOrdering = false);
          _showGpsDialog('Lỗi Vị Trí', 'Không thể xác định vị trí của bạn.', icon: Icons.gps_off_rounded);
        }
        return;
      }
    }

    final items = cart.items.entries
        .map((e) => OrderItem(dish: e.key, quantity: e.value))
        .toList();

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OrderType.dine_in,
      tableId: widget.tableId,
      sessionId: widget.sessionId,
      customerId: _customerId, 
      items: items,
      totalPrice: cart.totalPrice,
      status: OrderStatus.pending,
    );

    await _db.placeOrder(order);

    // Update table status
    if (mounted) {
       context.read<TableProvider>().updateStatus(widget.tableId, TableStatus.occupied);
    }

    if (mounted) {
      cart.clear(); // Clear global cart
      setState(() => _isOrdering = false);
      _tabController.animateTo(1); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã gửi đơn! Phục vụ sẽ xác nhận ngay.')));
    }
  }

  void _showGpsDialog(String title, String message,
      {IconData icon = Icons.warning_rounded, Color iconColor = Colors.orange}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(icon, color: iconColor, size: 44),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thực đơn', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            Text(_isBrowseMode ? 'Bấm để quét bàn' : 'Bàn ${widget.tableId}', 
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: cs.primary,
          indicatorWeight: 4,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 24),
          tabs: const [
            Tab(text: 'Menu'),
            Tab(text: 'Đơn hàng'),
            Tab(text: 'Lịch sử'),
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
              canOrder: !_isBrowseMode,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (c) => setState(() => _selectedCategory = c),
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
      bottomNavigationBar: _isBrowseMode 
          ? _BrowsePrompt(onScan: () async {
              // (keeping scan logic)
          })
          : (cart.items.isEmpty ? null : _CartSummary(
              count: cart.totalCount,
              total: cart.totalPrice,
              isOrdering: _isOrdering,
              onOrder: _placeOrder,
            )),
    );
  }

  String _tableNameFromId(String id) {
    if (id.isEmpty) return 'Chế độ xem';
    final num = id.replaceAll('table_', '');
    return 'Bàn $num';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CÁC COMPONENT CON (đã tách ra để code gọn hơn)
// ─────────────────────────────────────────────────────────────────────────────

class _CartSummary extends StatelessWidget {
  final int count;
  final double total;
  final bool isOrdering;
  final VoidCallback onOrder;

  const _CartSummary({
    required this.count,
    required this.total,
    required this.isOrdering,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count món đã chọn', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  Text('${_fmtPrice(total)}đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: isOrdering ? null : onOrder,
              icon: isOrdering 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
              label: const Text('Gửi đơn'),
              style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
            ),
          ],
        ),
      ),
    );
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

class _BrowsePrompt extends StatelessWidget {
  final VoidCallback onScan;
  const _BrowsePrompt({required this.onScan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bạn đang xem thực đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Quét mã tại bàn để đặt món', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Quét mã'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  final bool canOrder;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;

  const _MenuTab({
    required this.canOrder,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final cart = context.watch<CartProvider>();
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
        // Category Chips
        SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final isSelected = cat.id == selectedCategory;
              return FilterChip(
                selected: isSelected,
                label: Text(cat.name),
                onSelected: (_) => onCategoryChanged(cat.id),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
        
        // Dish List
        Expanded(
          child: dishes.isEmpty
              ? Center(child: Text('Không có món nào', style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: dishes.length,
                  itemBuilder: (_, i) {
                    final dish = dishes[i];
                    final qty = cart.items[dish] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DishCard(
                        dish: dish, 
                        qty: qty, 
                        canOrder: canOrder, 
                        onAdd: () => cart.addItem(dish), 
                        onRemove: () => cart.removeItem(dish)
                      ),
                    );
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
  final bool canOrder;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _DishCard({
    required this.dish,
    required this.qty,
    required this.canOrder,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            Hero(
              tag: 'dish_${dish.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: dish.imageUrl.isNotEmpty
                    ? Image.network(dish.imageUrl, width: 90, height: 90, fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => _imgPlaceholder(cs))
                    : _imgPlaceholder(cs),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (dish.isBestSeller) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('HOT 🔥', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  if (dish.description.isNotEmpty)
                    Text(dish.description, maxLines: 1, overflow: TextOverflow.ellipsis, 
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_fmtPrice(dish.price)}đ', 
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: cs.primary)),
                      
                      if (canOrder)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: qty == 0 
                            ? IconButton.filled(
                                onPressed: onAdd,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
                              )
                            : Row(children: [
                                _QtyBtn(icon: Icons.remove_rounded, color: Colors.grey.shade400, onTap: onRemove),
                                SizedBox(
                                  width: 32,
                                  child: Center(child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold))),
                                ),
                                _QtyBtn(icon: Icons.add_rounded, color: cs.primary, onTap: onAdd),
                              ]),
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

  Widget _imgPlaceholder(ColorScheme cs) => Container(width: 90, height: 90, color: cs.surfaceContainerHighest, child: Icon(Icons.fastfood_rounded, color: cs.outlineVariant, size: 32));
  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

// ── STATUS TAB ───────────────────────────────────────────────────────────────
class _OrderStatusTab extends StatelessWidget {
  final String tableId;
  final String customerId;
  final DatabaseService db;
  const _OrderStatusTab({required this.tableId, required this.customerId, required this.db});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<List<OrderModel>>(
      stream: db.getAllOrdersByCustomer(customerId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        
        // Lọc các đơn đang xử lý (chưa hoàn thành/hủy)
        final orders = snap.data!.where((o) => 
          o.status != OrderStatus.completed && o.status != OrderStatus.cancelled
        ).toList();

        if (orders.isEmpty) return _buildEmpty(cs, 'Chưa có đơn hàng nào đang xử lý');
        
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _OrderBatch(order: orders[i], batchNo: orders.length - i),
        );
      },
    );
  }

  Widget _buildEmpty(ColorScheme cs, String msg) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
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
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
            const Spacer(),
            Text('Đợt $batchNo', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: order.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Text('${item.quantity}x', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
              const SizedBox(width: 10),
              Text(item.dish.name),
            ]),
          )).toList()),
        ),
      ]),
    );
  }

  (Color, IconData, String) _statusInfo(OrderStatus s, ColorScheme cs) => switch (s) {
    OrderStatus.pending => (Colors.orange, Icons.hourglass_empty_rounded, 'Chờ xác nhận'),
    OrderStatus.preparing => (Colors.blue, Icons.soup_kitchen_rounded, 'Bếp đang làm'),
    OrderStatus.ready => (Colors.teal, Icons.room_service_rounded, 'Xong – Chờ phục vụ'),
    OrderStatus.served => (Colors.purple, Icons.check_circle_rounded, 'Đã phục vụ'),
    _ => (Colors.grey, Icons.info_outline_rounded, s.name),
  };
}

// ── HISTORY TAB ──────────────────────────────────────────────────────────────
class _InvoiceHistoryTab extends StatefulWidget {
  final String tableId;
  final String customerId;
  final DatabaseService db;
  const _InvoiceHistoryTab({required this.tableId, required this.customerId, required this.db});

  @override
  State<_InvoiceHistoryTab> createState() => _InvoiceHistoryTabState();
}

class _InvoiceHistoryTabState extends State<_InvoiceHistoryTab> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(
          onPressed: () async {
            final pick = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
            if (pick != null) setState(() => _range = pick);
          },
          icon: const Icon(Icons.date_range_rounded),
          label: Text(_range == null ? 'Lọc theo ngày' : '${_fmtDate(_range!.start)} - ${_fmtDate(_range!.end)}'),
        ),
      ),
      Expanded(
        child: StreamBuilder<List<OrderModel>>(
          stream: widget.db.getAllOrdersByCustomer(widget.customerId),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            var list = snap.data!.where((o) => o.status == OrderStatus.completed).toList();
            if (_range != null) {
              list = list.where((o) => o.createdAt.isAfter(_range!.start) && o.createdAt.isBefore(_range!.end.add(const Duration(days: 1)))).toList();
            }
            if (list.isEmpty) return const Center(child: Text('Chưa có lịch sử giao dịch'));
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => ListTile(
                tileColor: cs.surface,
                title: Text('Đơn ngày ${_fmtDate(list[i].createdAt)}'),
                subtitle: Text('Tổng: ${_fmtPrice(list[i].totalPrice)}đ'),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          },
        ),
      ),
    ]);
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
