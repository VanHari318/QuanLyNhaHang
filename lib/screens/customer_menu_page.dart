import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/category_model.dart';
import '../providers/menu_provider.dart';
import '../providers/table_provider.dart';
import '../models/table_model.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import 'qr_scanner_screen.dart';

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

  double get _totalPrice =>
      _cart.entries.fold(0, (sum, e) => sum + (e.key.price * e.value));

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  bool get _isBrowseMode => widget.tableId.isEmpty;

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    if (_isBrowseMode) return;

    // ── Kiểm tra vị trí GPS (Geofencing) ────────────────────────────────────
    final config = await _db.getRestaurantConfig().first;
    if (config != null) {
      final restaurantLat = (config['lat'] as num).toDouble();
      final restaurantLng = (config['lng'] as num).toDouble();
      final allowedRadius = (config['radiusMeters'] as num?)?.toDouble() ?? 15.0;

      // Hiện loading trong khi kiểm tra GPS
      setState(() => _isOrdering = true);

      // Kiểm tra/xin quyền
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isOrdering = false);
          _showGpsDialog(
            '⚠️ Cần Quyền Vị Trí',
            'Vui lòng cấp quyền truy cập vị trí để xác nhận bạn đang ở trong quán.',
            icon: Icons.location_off_rounded,
            iconColor: Colors.orange,
          );
        }
        return;
      }

      // Lấy vị trí – nếu lỗi thì CHẶN (không cho đặt im lặng)
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        final distanceM = Geolocator.distanceBetween(
          restaurantLat, restaurantLng,
          pos.latitude, pos.longitude,
        );

        if (distanceM > allowedRadius) {
          if (mounted) {
            setState(() => _isOrdering = false);
            _showGpsDialog(
              '❌ Ngoài Phạm Vi Quán',
              'Bạn đang cách nhà hàng khoảng ${distanceM.round()}m.\n'
              'Chỉ có thể đặt món khi ở trong phạm vi ${allowedRadius.round()}m của quán.',
              icon: Icons.location_off_rounded,
              iconColor: Colors.red,
            );
          }
          return;
        }
        // Trong phạm vi → tiếp tục đặt món
      } catch (e) {
        // GPS lỗi/timeout → CHẶN an toàn, không cho đặt lén
        if (mounted) {
          setState(() => _isOrdering = false);
          _showGpsDialog(
            '⚠️ Không Lấy Được Vị Trí',
            'Không thể xác định vị trí của bạn.\nVui lòng bật GPS và thử lại.',
            icon: Icons.gps_off_rounded,
            iconColor: Colors.orange,
          );
        }
        return;
      }
    }
    // ────────────────────────────────────────────────────────────────────────

    setState(() => _isOrdering = true);

    final items = _cart.entries
        .map((e) => OrderItem(dish: e.key, quantity: e.value))
        .toList();

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: OrderType.dine_in,
      tableId: widget.tableId,
      sessionId: widget.sessionId,
      customerId: _customerId, // Gắn ID định danh máy hoặc UID
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
                Text(_isBrowseMode ? 'Chế độ xem' : _tableNameFromId(widget.tableId),
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
              canOrder: !_isBrowseMode,
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
      // Bottom navigation (Cart or Scan prompt)
      bottomNavigationBar: _isBrowseMode 
          ? _BrowsePrompt(onScan: () async {
              final result = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );
              if (result != null && context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerMenuPage(
                      tableId: result['tableId']!,
                      sessionId: result['sessionId']!,
                    ),
                  ),
                );
              }
            })
          : (_cart.isEmpty ? null : _CartSummary(
              count: _cartCount,
              total: _totalPrice,
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
  final Map<DishModel, int> cart;
  final bool canOrder;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;
  final void Function(DishModel) onAdd;
  final void Function(DishModel) onRemove;

  const _MenuTab({
    required this.cart,
    required this.canOrder,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: dishes.isEmpty
              ? Center(child: Text('Không có món nào', style: TextStyle(color: cs.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: dishes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final dish = dishes[i];
                    final qty = cart[dish] ?? 0;
                    return _DishCard(dish: dish, qty: qty, canOrder: canOrder, onAdd: onAdd, onRemove: onRemove);
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
  final void Function(DishModel) onAdd;
  final void Function(DishModel) onRemove;

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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: dish.imageUrl.isNotEmpty
                  ? Image.network(dish.imageUrl, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder(cs))
                  : _imgPlaceholder(cs),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    if (dish.isBestSeller) const Text('🔥', style: TextStyle(fontSize: 14)),
                  ]),
                  if (dish.description.isNotEmpty)
                    Text(dish.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_fmtPrice(dish.price)}đ', style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
                      if (canOrder)
                        Row(children: [
                          if (qty > 0) ...[
                            _QtyBtn(icon: Icons.remove_rounded, color: cs.error, onTap: () => onRemove(dish)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          _QtyBtn(icon: Icons.add_rounded, color: cs.primary, onTap: () => onAdd(dish)),
                        ]),
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

  Widget _imgPlaceholder(ColorScheme cs) => Container(width: 72, height: 72, color: cs.surfaceContainerHighest, child: Icon(Icons.fastfood_rounded, color: cs.outlineVariant, size: 32));
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
    if (tableId.isEmpty) return _buildEmpty(cs, 'Bạn chưa quét mã bàn');

    return StreamBuilder<List<OrderModel>>(
      stream: db.getOrdersByCustomerAndTable(customerId, tableId),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).toList();

        if (orders.isEmpty) return _buildEmpty(cs, 'Chưa có đơn hàng nào');
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _OrderBatch(order: orders[i], batchNo: i + 1),
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
