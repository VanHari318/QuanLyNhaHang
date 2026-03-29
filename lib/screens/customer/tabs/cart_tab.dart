import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/order_model.dart';
import '../../../models/dish_model.dart';
import '../../../services/database_service.dart';

class CartTab extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const CartTab({super.key, this.onSwitchTab});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  int _currentStep = 0; // 0: Review, 1: Location, 2: Payment
  
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

  Future<void> _submitOrder() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin và chọn thanh toán')));
      return;
    }

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    setState(() => _isOrdering = true);

    try {
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: cart.tableId != null ? OrderType.dine_in : OrderType.online,
        items: cart.items.entries.map((e) => OrderItem(dish: e.key, quantity: e.value)).toList(),
        totalPrice: cart.totalPrice,
        status: OrderStatus.pending,
        customerId: auth.user?.id,
        tableId: cart.tableId,
        sessionId: cart.sessionId,
        customerNote: 'Người nhận: ${_nameCtrl.text}\nSĐT: ${_phoneCtrl.text}\nLưu ý: ${_noteCtrl.text}',
        paymentMethod: _paymentMethod,
        location: OrderLocation(
          lat: _currentP?.latitude ?? 0,
          lng: _currentP?.longitude ?? 0,
          address: 'Giao tận nơi (Giỏ hàng)',
        ),
      );

      await _db.placeOrder(order);
      
      if (mounted) {
        cart.clear();
        setState(() {
          _isOrdering = false;
          _currentStep = 0;
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
        content: const Text('Đơn hàng từ giỏ hàng đã được gửi đi. Bạn có thể theo dõi trong mục Lịch sử.'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Đồng ý')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cs = Theme.of(context).colorScheme;

    if (cart.items.isEmpty && _currentStep == 0) {
      return _buildEmpty(cs);
    }

    return Scaffold(
      appBar: _currentStep > 0 ? AppBar(
        title: Text(_currentStep == 1 ? 'Vị trí giao hàng' : 'Thanh toán & Xác nhận'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)),
      ) : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(cs, cart),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs, CartProvider cart) {
    return switch (_currentStep) {
      0 => _buildReviewStep(cs, cart),
      1 => _buildLocationStep(cs),
      2 => _buildPaymentStep(cs, cart),
      _ => const SizedBox(),
    };
  }

  // ── STEP 0: REVIEW ────────────────────────────────────────────────────────
  Widget _buildReviewStep(ColorScheme cs, CartProvider cart) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: cart.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, index) {
              final dish = cart.items.keys.elementAt(index);
              final qty = cart.items[dish]!;
              return _CartItemTile(dish: dish, qty: qty, cart: cart);
            },
          ),
        ),
        _buildSummary(cart),
      ],
    );
  }

  // ── STEP 1: LOCATION ──────────────────────────────────────────────────────
  Widget _buildLocationStep(ColorScheme cs) {
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
                  onTap: (_, p) => setState(() { _currentP = p; _updateDistance(); }),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mrdoanh.vilaiquan.app',
                  ),
                  if (_restaurantP != null)
                     MarkerLayer(markers: [
                        Marker(point: _restaurantP!, width: 40, height: 40, child: const Icon(Icons.restaurant_rounded, color: Colors.red, size: 30)),
                        if (_currentP != null) Marker(point: _currentP!, width: 50, height: 50, child: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 40)),
                     ]),
                ],
              ),
              Positioned(top: 16, right: 16, child: FloatingActionButton.small(onPressed: () { _initLocation(); if(_currentP != null) _mapController.move(_currentP!, 15); }, child: const Icon(Icons.my_location_rounded))),
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
              SizedBox(width: double.infinity, child: FilledButton(onPressed: isTooFar ? null : () => setState(() => _currentStep = 2), child: const Text('Tiếp tục: Thanh toán'))),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 2: PAYMENT ───────────────────────────────────────────────────────
  Widget _buildPaymentStep(ColorScheme cs, CartProvider cart) {
    final subtotal = cart.totalPrice;
    final deliveryFee = _distanceKm * 5000;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết đơn từ giỏ hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Card(
            elevation: 0, color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(children: cart.items.entries.map((e) => ListTile(
              title: Text(e.key.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${e.value} món'),
              trailing: Text('${_fmtPrice(e.key.price * e.value)}đ'),
            )).toList()),
          ),
          const SizedBox(height: 24),
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          _PaymentTile(id: 'COD', label: 'Tiền mặt (COD)', selected: _paymentMethod == 'COD', onSelect: (v) => setState(() => _paymentMethod = v)),
          _PaymentTile(id: 'Bank', label: 'Chuyển khoản NH', selected: _paymentMethod == 'Bank', onSelect: (v) => setState(() => _paymentMethod = v)),
          _PaymentTile(id: 'Momo', label: 'Ví Momo', selected: _paymentMethod == 'Momo', onSelect: (v) => setState(() => _paymentMethod = v)),
          const SizedBox(height: 24),
          TextField(controller: _noteCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Lưu ý giao hàng', border: OutlineInputBorder())),
          const Divider(height: 48),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16)),
            Text('${_fmtPrice(subtotal + deliveryFee)}đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.primary)),
          ]),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _isOrdering ? null : _submitOrder, child: _isOrdering ? const CircularProgressIndicator(color: Colors.white) : const Text('XÁC NHẬN THANH TOÁN'))),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: cs.outlineVariant),
          const SizedBox(height: 16),
          const Text('Giỏ hàng đang trống', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSummary(CartProvider cart) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tạm tính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('${_fmtPrice(cart.totalPrice)}đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: cs.primary)),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => setState(() => _currentStep = 1), child: const Text('Tiến hành đặt giao hàng'))),
        ],
      ),
    );
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _CartItemTile extends StatelessWidget {
  final DishModel dish;
  final int qty;
  final CartProvider cart;
  const _CartItemTile({required this.dish, required this.qty, required this.cart});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(dish.imageUrl, width: 85, height: 85, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 85, height: 85, color: cs.surfaceContainerHighest))),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(dish.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text('${_fmtPrice(dish.price)}đ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        Row(children: [
          _circleBtn(Icons.remove, () => cart.removeItem(dish)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold))),
          _circleBtn(Icons.add, () => cart.addItem(dish)),
          const Spacer(),
          IconButton(onPressed: () { for(int i=0; i<qty; i++) cart.removeItem(dish); }, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20)),
        ]),
      ])),
    ]);
  }
  Widget _circleBtn(IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle), child: Icon(icon, size: 16)));
  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _PaymentTile extends StatelessWidget {
  final String id;
  final String label;
  final bool selected;
  final Function(String) onSelect;
  const _PaymentTile({required this.id, required this.label, required this.selected, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RadioListTile<String>(
      title: Text(label), value: id, groupValue: selected ? id : '', onChanged: (v) => onSelect(v!),
      activeColor: cs.primary, contentPadding: EdgeInsets.zero,
    );
  }
}

