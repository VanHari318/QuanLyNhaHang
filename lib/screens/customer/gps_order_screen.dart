import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/order_model.dart';
import '../../models/dish_model.dart';
import '../../services/database_service.dart';
<<<<<<< HEAD
=======
import '../../providers/inventory_provider.dart';
>>>>>>> 6690387 (sua loi)

class GPSOrderScreen extends StatefulWidget {
  const GPSOrderScreen({super.key});

  @override
  State<GPSOrderScreen> createState() => _GPSOrderScreenState();
}

class _GPSOrderScreenState extends State<GPSOrderScreen> {
  int _currentStep = 0; // 0: Menu, 1: Map/Details, 2: Payment
  
  final MapController _mapController = MapController();
  LatLng? _currentP;
  LatLng? _restaurantP;
  double _distanceKm = 0.0;
  bool _isLoadingLoc = false;
  bool _isOrdering = false;
  
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _db = DatabaseService();

  List<OrderItem> _onlineItems = [];
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    _initLocation();
    
    // Auto-fill from Profile
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLoc = true);
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        if (p == LocationPermission.denied) {
           setState(() => _isLoadingLoc = false);
           return;
        }
      }
      
      final config = await _db.getRestaurantConfig().first;
      if (config != null) {
        _restaurantP = LatLng((config['lat'] as num).toDouble(), (config['lng'] as num).toDouble());
      }

      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentP = LatLng(pos.latitude, pos.longitude);
          _updateDistance();
          _isLoadingLoc = false;
        });
        _mapController.move(_currentP!, 15);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLoc = false);
    }
  }

  void _updateDistance() {
    if (_restaurantP != null && _currentP != null) {
      _distanceKm = Geolocator.distanceBetween(
        _restaurantP!.latitude, _restaurantP!.longitude, 
        _currentP!.latitude, _currentP!.longitude
      ) / 1000;
    }
  }

  void _startOrder(List<OrderItem> items) {
    setState(() {
      _onlineItems = items;
      _currentStep = 1;
    });
  }

  Future<void> _completeOrder() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin và chọn thanh toán')));
      return;
    }

    setState(() => _isOrdering = true);
    final auth = context.read<AuthProvider>();

    try {
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: OrderType.online,
        items: _onlineItems,
        totalPrice: _onlineItems.fold(0.0, (sum, item) => sum + (item.dish.price * item.quantity)),
        status: OrderStatus.pending,
        customerId: auth.user?.id,
        customerNote: 'Người nhận: ${_nameCtrl.text}\nSĐT: ${_phoneCtrl.text}\nLưu ý: ${_noteCtrl.text}',
        paymentMethod: _paymentMethod,
        location: OrderLocation(
          lat: _currentP?.latitude ?? 0,
          lng: _currentP?.longitude ?? 0,
          address: 'Giao tận nơi (GPS)',
        ),
      );

      await _db.placeOrder(order);
      
      if (mounted) {
        setState(() {
          _isOrdering = false;
          _currentStep = 0;
          _onlineItems = [];
          _paymentMethod = null;
          _nameCtrl.clear();
          _phoneCtrl.clear();
          _noteCtrl.clear();
        });
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
        title: const Text('Đặt hàng thành công!'),
        content: const Text('Đơn hàng của bạn đã được gửi đi. Bạn có thể theo dõi trong mục Lịch sử.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đồng ý')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle(), style: const TextStyle(fontWeight: FontWeight.w900)),
        leading: _currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)) : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(cs),
      ),
    );
  }

  String _stepTitle() => switch (_currentStep) {
    0 => 'Chọn món giao hàng',
    1 => 'Địa chỉ giao hàng',
    2 => 'Thanh toán & Xác nhận',
    _ => 'Đặt hàng',
  };

  Widget _buildBody(ColorScheme cs) {
    return switch (_currentStep) {
      0 => _buildMenuStep(cs),
      1 => _buildMapStep(cs),
      2 => _buildPaymentStep(cs),
      _ => const SizedBox(),
    };
  }

  // ── STEP 0: MENU ──────────────────────────────────────────────────────────
  Widget _buildMenuStep(ColorScheme cs) {
    final menu = context.watch<MenuProvider>();
<<<<<<< HEAD
=======
    final inventory = context.watch<InventoryProvider>().items;
>>>>>>> 6690387 (sua loi)
    final dishes = menu.allItems.where((d) => d.isAvailable).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: cs.primaryContainer.withValues(alpha: 0.3),
          child: Row(children: [
            Icon(Icons.tips_and_updates_outlined, color: cs.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Chọn món "Mua ngay" để đặt món cực nhanh.', style: TextStyle(fontSize: 12))),
          ]),
        ),
        Expanded(
<<<<<<< HEAD
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dishes.length,
            itemBuilder: (_, i) => _OnlineDishCard(
              dish: dishes[i], 
              onBuyNow: (qty) => _startOrder([OrderItem(dish: dishes[i], quantity: qty)]),
=======
          child: RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
            itemCount: dishes.length,
            itemBuilder: (_, i) {
              final dish = dishes[i];
              final isOutOfStock = menu.isOutOfStock(dish.id, inventory);
              return _OnlineDishCard(
                dish: dish, 
                isOutOfStock: isOutOfStock,
                onBuyNow: (qty) => _startOrder([OrderItem(dish: dish, quantity: qty)]),
                );
              },
>>>>>>> 6690387 (sua loi)
            ),
          ),
        ),
      ],
    );
  }

  // ── STEP 1: MAP ───────────────────────────────────────────────────────────
  Widget _buildMapStep(ColorScheme cs) {
    final bool isTooFar = _distanceKm > 10.0;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentP ?? const LatLng(21.0285, 105.8542), 
                  initialZoom: 15,
                  onTap: (_, p) {
                    setState(() {
                      _currentP = p;
                      _updateDistance();
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mrdoanh.vilaiquan.app',
                  ),
                  if (_restaurantP != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(point: _restaurantP!, radius: 10000, useRadiusInMeter: true, color: Colors.red.withValues(alpha: 0.05), borderColor: Colors.red.withValues(alpha: 0.2), borderStrokeWidth: 1),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_restaurantP != null) Marker(point: _restaurantP!, width: 40, height: 40, child: const Icon(Icons.restaurant_rounded, color: Colors.red, size: 30)),
                      if (_currentP != null) Marker(point: _currentP!, width: 50, height: 50, child: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 40)),
                    ],
                  ),
                ],
              ),
              if (_isLoadingLoc) const Center(child: CircularProgressIndicator()),
              Positioned(top: 16, right: 16, child: FloatingActionButton.small(onPressed: _initLocation, child: const Icon(Icons.my_location_rounded))),
              Positioned(
                top: 16, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    const Text('Chạm vào bản đồ để chọn vị trí giao', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(isTooFar ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: isTooFar ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(isTooFar ? 'Ngoài phạm vi (10km)' : 'Khoảng cách: ${_distanceKm.toStringAsFixed(1)} km', style: TextStyle(fontWeight: FontWeight.bold, color: isTooFar ? Colors.red : Colors.green)),
              ]),
              const SizedBox(height: 16),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên người nhận', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_android_outlined))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isTooFar ? null : () => setState(() => _currentStep = 2),
                  child: const Text('Tiếp tục: Thanh toán'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 2: PAYMENT ───────────────────────────────────────────────────────
  Widget _buildPaymentStep(ColorScheme cs) {
    final subtotal = _onlineItems.fold(0.0, (sum, item) => sum + (item.dish.price * item.quantity));
    final deliveryFee = _distanceKm * 5000; // 5k/km

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Card(
            elevation: 0, color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(children: _onlineItems.map((it) => ListTile(
              title: Text(it.dish.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${it.quantity} x ${_fmtPrice(it.dish.price)}đ'),
              trailing: Text('${_fmtPrice(it.dish.price * it.quantity)}đ'),
            )).toList()),
          ),
          const SizedBox(height: 24),
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          _PaymentTile(id: 'COD', label: 'Tiền mặt (COD)', icon: Icons.money_rounded, selected: _paymentMethod == 'COD', onSelect: (v) => setState(() => _paymentMethod = v)),
          _PaymentTile(id: 'Bank', label: 'Chuyển khoản NH', icon: Icons.account_balance_rounded, selected: _paymentMethod == 'Bank', onSelect: (v) => setState(() => _paymentMethod = v)),
          _PaymentTile(id: 'Momo', label: 'Ví Momo', icon: Icons.account_balance_wallet_rounded, selected: _paymentMethod == 'Momo', onSelect: (v) => setState(() => _paymentMethod = v)),
          const SizedBox(height: 24),
          TextField(controller: _noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Lưu ý giao hàng', border: OutlineInputBorder())),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16)),
            Text('${_fmtPrice(subtotal + deliveryFee)}đ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FloatingActionButton.extended(
              onPressed: _isOrdering ? null : _completeOrder,
              label: _isOrdering ? const CircularProgressIndicator(color: Colors.white) : const Text('XÁC NHẬN ĐẶT HÀNG'),
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _OnlineDishCard extends StatefulWidget {
  final DishModel dish;
<<<<<<< HEAD
  final Function(int) onBuyNow;
  const _OnlineDishCard({required this.dish, required this.onBuyNow});
=======
  final bool isOutOfStock;
  final Function(int) onBuyNow;
  const _OnlineDishCard({required this.dish, required this.onBuyNow, this.isOutOfStock = false});
>>>>>>> 6690387 (sua loi)
  @override
  State<_OnlineDishCard> createState() => _OnlineDishCardState();
}

class _OnlineDishCardState extends State<_OnlineDishCard> {
  int _qty = 1;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
<<<<<<< HEAD
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
=======
    return Opacity(
      opacity: widget.isOutOfStock ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
>>>>>>> 6690387 (sua loi)
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: widget.dish.imageUrl.isNotEmpty ? Image.network(widget.dish.imageUrl, width: 80, height: 80, fit: BoxFit.cover) : Container(width: 80, height: 80, color: cs.surfaceContainerHighest)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
<<<<<<< HEAD
=======
            if (widget.isOutOfStock)
              const Text('HẾT MÓN', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
>>>>>>> 6690387 (sua loi)
            Text('${widget.dish.price.toInt()}đ', style: TextStyle(fontWeight: FontWeight.w900, color: cs.primary, fontSize: 15)),
            const SizedBox(height: 8),
            Row(children: [
              _QtyBtn(idx: -1, onTap: () => setState(() => _qty = (_qty > 1 ? _qty - 1 : 1))),
              SizedBox(width: 32, child: Center(child: Text('$_qty', style: const TextStyle(fontWeight: FontWeight.bold)))),
              _QtyBtn(idx: 1, onTap: () => setState(() => _qty++)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add_shopping_cart_rounded, size: 20, color: cs.primary),
<<<<<<< HEAD
                onPressed: () {
=======
                onPressed: widget.isOutOfStock ? null : () {
>>>>>>> 6690387 (sua loi)
                  context.read<CartProvider>().addItem(widget.dish, quantity: _qty);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Đã thêm ${_qty} ${widget.dish.name} vào giỏ hàng'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ));
                },
              ),
<<<<<<< HEAD
              _ActionBtn(label: 'Mua ngay', color: cs.primary, onTap: () => widget.onBuyNow(_qty)),
=======
              _ActionBtn(
                label: 'Mua ngay', 
                color: widget.isOutOfStock ? Colors.grey : cs.primary, 
                onTap: widget.isOutOfStock ? null : () => widget.onBuyNow(_qty)
              ),
>>>>>>> 6690387 (sua loi)
            ]),
          ])),
        ]),
      ),
<<<<<<< HEAD
=======
    ),
>>>>>>> 6690387 (sua loi)
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final int idx;
  final VoidCallback onTap;
  const _QtyBtn({required this.idx, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(idx == 1 ? Icons.add : Icons.remove, size: 16, color: cs.primary),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
<<<<<<< HEAD
  final VoidCallback onTap;
=======
  final VoidCallback? onTap;
>>>>>>> 6690387 (sua loi)
  const _ActionBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final Function(String) onSelect;
  const _PaymentTile({required this.id, required this.label, required this.icon, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => onSelect(id),
      leading: Icon(icon, color: selected ? cs.primary : null),
      title: Text(label),
      trailing: Radio<String>(value: id, groupValue: selected ? id : '', onChanged: (v) => onSelect(v!)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5))),
    );
  }
}

