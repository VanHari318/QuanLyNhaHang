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
import '../../../providers/inventory_provider.dart';
import '../../../providers/menu_provider.dart';
import '../../../theme/role_themes.dart';

class CartTab extends StatefulWidget {
  final Function(int)? onSwitchTab;
  const CartTab({super.key, this.onSwitchTab});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> with SingleTickerProviderStateMixin {
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
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  // ── LOCATION ─────────────────────────────────────────────────────────────────
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
        _restaurantP = LatLng(
          (config['lat'] as num).toDouble(),
          (config['lng'] as num).toDouble(),
        );
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
      _distanceKm =
          Geolocator.distanceBetween(
                _restaurantP!.latitude,
                _restaurantP!.longitude,
                _currentP!.latitude,
                _currentP!.longitude,
              ) /
          1000;
    }
  }

  // ── ORDER SUBMIT ──────────────────────────────────────────────────────────────
  Future<void> _submitOrder() async {
    if (_nameCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Vui lòng điền đủ thông tin và chọn thanh toán'),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    setState(() => _isOrdering = true);

    try {
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: OrderType.online, // Luôn là online khi đặt từ Tab Giao hàng
        items: cart.items.entries
            .map((e) => OrderItem(dish: e.key, quantity: e.value))
            .toList(),
        totalPrice: cart.totalPrice,
        status: OrderStatus.pending,
        customerId: auth.user?.id,
        tableId: null,      // Không gắn bàn khi giao hàng
        sessionId: null,    // Không gắn session khi giao hàng
        customerNote:
            'Người nhận: ${_nameCtrl.text}\nSĐT: ${_phoneCtrl.text}\nLưu ý: ${_noteCtrl.text}',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CustomerTheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: CustomerTheme.primary,
            size: 48,
          ),
        ),
        title: const Text('Đặt hàng thành công!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Đơn hàng đã được gửi đi. Bạn có thể theo dõi trong mục Lịch sử.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: CustomerTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tuyệt vời!'),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty && _currentStep == 0) {
      return _buildEmpty();
    }

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      appBar: _currentStep > 0
          ? AppBar(
              flexibleSpace: Container(
                  decoration: const BoxDecoration(
                      gradient: CustomerTheme.appBarGradient)),
              foregroundColor: Colors.white,
              title: Text(
                _currentStep == 1 ? 'Vị trí giao hàng' : 'Thanh toán & Xác nhận',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _currentStep--),
              ),
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(cart),
      ),
    );
  }

  Widget _buildBody(CartProvider cart) {
    return switch (_currentStep) {
      0 => _buildReviewStep(cart),
      1 => _buildLocationStep(),
      2 => _buildPaymentStep(cart),
      _ => const SizedBox(),
    };
  }

  // ── STEP 0: REVIEW ────────────────────────────────────────────────────────────
  Widget _buildReviewStep(CartProvider cart) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.shopping_basket_rounded,
                  color: CustomerTheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Giỏ hàng (${cart.totalCount} món)',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: CustomerTheme.primary,
            onRefresh: () async =>
                await Future.delayed(const Duration(seconds: 1)),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) {
                final dish = cart.items.keys.elementAt(index);
                final qty = cart.items[dish]!;
                final inventory = context.watch<InventoryProvider>().items;
                final menu = context.read<MenuProvider>();
                final isOutOfStock = menu.isOutOfStock(dish.id, inventory);
                return _CartItemTile(
                  dish: dish,
                  qty: qty,
                  cart: cart,
                  isOutOfStock: isOutOfStock,
                );
              },
            ),
          ),
        ),
        _buildSummary(cart),
      ],
    );
  }

  // ── STEP 1: LOCATION ──────────────────────────────────────────────────────────
  Widget _buildLocationStep() {
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
                  onTap: (_, p) => setState(() {
                    _currentP = p;
                    _updateDistance();
                  }),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.mrdoanh.vilaiquan.app',
                  ),
                  if (_restaurantP != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _restaurantP!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.restaurant_rounded,
                              color: CustomerTheme.primary, size: 30),
                        ),
                        if (_currentP != null)
                          Marker(
                            point: _currentP!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_on_rounded,
                                color: Color(0xFF0984E3), size: 40),
                          ),
                      ],
                    ),
                ],
              ),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: CustomerTheme.primary,
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _initLocation();
                    if (_currentP != null) _mapController.move(_currentP!, 15);
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Distance indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: (_distanceKm > 10.0 ? Colors.red : Colors.green)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _distanceKm > 10.0
                          ? Icons.error_rounded
                          : Icons.check_circle_rounded,
                      color:
                          _distanceKm > 10.0 ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _distanceKm > 10.0
                          ? 'Ngoài phạm vi giao hàng (10km)'
                          : 'Khoảng cách: ${_distanceKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _distanceKm > 10.0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên người nhận',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: CustomerTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: CustomerTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_android_outlined,
                      color: CustomerTheme.primary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: CustomerTheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _distanceKm > 10.0
                        ? null
                        : const LinearGradient(
                            colors: [
                              CustomerTheme.primary,
                              CustomerTheme.secondary
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    color: _distanceKm > 10.0 ? Colors.grey.shade200 : null,
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _distanceKm > 10.0
                        ? null
                        : () => setState(() => _currentStep = 2),
                    child: const Text('Tiếp tục: Thanh toán',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── STEP 2: PAYMENT ───────────────────────────────────────────────────────────
  Widget _buildPaymentStep(CartProvider cart) {
    final subtotal = cart.totalPrice;
    final deliveryFee = _distanceKm * 5000;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết đơn hàng',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: cart.items.entries
                  .map((e) => ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: CustomerTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('${e.value}',
                                style: const TextStyle(
                                    color: CustomerTheme.primary,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        title: Text(e.key.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(
                            '${_fmtPrice(e.key.price * e.value)}đ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Phương thức thanh toán',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),
          _PaymentCard(
              id: 'COD',
              label: 'Tiền mặt (COD)',
              icon: Icons.payments_rounded,
              iconColor: const Color(0xFF00B894),
              selected: _paymentMethod == 'COD',
              onSelect: (v) => setState(() => _paymentMethod = v)),
          const SizedBox(height: 10),
          _PaymentCard(
              id: 'Bank',
              label: 'Chuyển khoản NH',
              icon: Icons.account_balance_rounded,
              iconColor: const Color(0xFF0984E3),
              selected: _paymentMethod == 'Bank',
              onSelect: (v) => setState(() => _paymentMethod = v)),
          const SizedBox(height: 10),
          _PaymentCard(
              id: 'Momo',
              label: 'Ví Momo',
              icon: Icons.wallet_rounded,
              iconColor: const Color(0xFFAA00FF),
              selected: _paymentMethod == 'Momo',
              onSelect: (v) => setState(() => _paymentMethod = v)),
          const SizedBox(height: 20),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Lưu ý giao hàng',
              prefixIcon: const Icon(Icons.sticky_note_2_outlined,
                  color: CustomerTheme.primary),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: CustomerTheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Price summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                _priceRow('Tạm tính', subtotal),
                const SizedBox(height: 8),
                _priceRow('Phí giao hàng', deliveryFee),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(
                      '${_fmtPrice(subtotal + deliveryFee)}đ',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: CustomerTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CustomerTheme.primary, CustomerTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isOrdering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded),
                label:
                    Text(_isOrdering ? 'Đang xử lý...' : 'XÁC NHẬN THANH TOÁN',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                onPressed:
                    (_isOrdering ||
                            cart.items.entries.any(
                              (e) => context.read<MenuProvider>().isOutOfStock(
                                    e.key.id,
                                    context
                                        .read<InventoryProvider>()
                                        .items,
                                  ),
                            ))
                        ? null
                        : _submitOrder,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text('${_fmtPrice(amount)}đ',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: CustomerTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: CustomerTheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Giỏ hàng đang trống',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3436)),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy chọn những món ăn yêu thích!',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── SUMMARY BAR ───────────────────────────────────────────────────────────────
  Widget _buildSummary(CartProvider cart) {
    final menu = context.read<MenuProvider>();
    final inventory = context.watch<InventoryProvider>().items;
    bool hasOutOfStock =
        cart.items.entries.any((e) => menu.isOutOfStock(e.key.id, inventory));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasOutOfStock)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Có món đã hết. Xóa món hết hàng để tiếp tục.',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                '${_fmtPrice(cart.totalPrice)}đ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: CustomerTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: hasOutOfStock
                    ? null
                    : const LinearGradient(
                        colors: [
                          CustomerTheme.primary,
                          CustomerTheme.secondary
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                color: hasOutOfStock ? Colors.grey.shade200 : null,
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.delivery_dining_rounded),
                label: const Text('Tiến hành đặt giao hàng',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed:
                    hasOutOfStock ? null : () => setState(() => _currentStep = 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

// ── CART ITEM TILE ────────────────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final DishModel dish;
  final int qty;
  final CartProvider cart;
  final bool isOutOfStock;
  const _CartItemTile({
    required this.dish,
    required this.qty,
    required this.cart,
    this.isOutOfStock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isOutOfStock ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    dish.imageUrl,
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: CustomerTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fastfood_rounded,
                          color: CustomerTheme.primary),
                    ),
                  ),
                ),
                if (isOutOfStock)
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('HẾT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF2D3436)),
                  ),
                  if (isOutOfStock)
                    const Text('Nguyên liệu không đủ',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '${_fmtPrice(dish.price)}đ',
                    style: const TextStyle(
                      color: CustomerTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _circleBtn(
                          Icons.remove,
                          const Color(0xFFFF6B6B),
                          () => cart.removeItem(dish)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('$qty',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ),
                      _circleBtn(
                          Icons.add,
                          CustomerTheme.primary,
                          isOutOfStock ? null : () => cart.addItem(dish)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          for (int i = 0; i < qty; i++) {
                            cart.removeItem(dish);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.red, size: 18),
                        ),
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

  Widget _circleBtn(IconData icon, Color color, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: onTap == null
                ? Colors.grey.shade100
                : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
                color: onTap == null
                    ? Colors.grey.shade200
                    : color.withValues(alpha: 0.4)),
          ),
          child: Icon(icon,
              size: 16, color: onTap == null ? Colors.grey : color),
        ),
      );

  String _fmtPrice(double p) => p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

// ── PAYMENT CARD ──────────────────────────────────────────────────────────────
class _PaymentCard extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final Function(String) onSelect;
  const _PaymentCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? CustomerTheme.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? CustomerTheme.primary
                : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? CustomerTheme.primary
                          : const Color(0xFF2D3436))),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? CustomerTheme.primary
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: selected ? CustomerTheme.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
