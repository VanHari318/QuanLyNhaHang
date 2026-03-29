import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/order_model.dart';
import '../../services/database_service.dart';

class GPSOrderScreen extends StatefulWidget {
  const GPSOrderScreen({super.key});

  @override
  State<GPSOrderScreen> createState() => _GPSOrderScreenState();
}

class _GPSOrderScreenState extends State<GPSOrderScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentP;
  LatLng? _restaurantP;
  double _distanceKm = 0.0;
  bool _isLoading = true;
  bool _isOrdering = false;
  
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final config = await _db.getRestaurantConfig().first;
      if (config != null) {
        _restaurantP = LatLng((config['lat'] as num).toDouble(), (config['lng'] as num).toDouble());
      }

      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      
      if (mounted) {
        setState(() {
          _currentP = LatLng(pos.latitude, pos.longitude);
          if (_restaurantP != null) {
            _distanceKm = Geolocator.distanceBetween(_restaurantP!.latitude, _restaurantP!.longitude, _currentP!.latitude, _currentP!.longitude) / 1000;
          }
          _isLoading = false;
        });
        _mapController.move(_currentP!, 15);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _placeOnlineOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giỏ hàng trống! Vui lòng chọn món.')));
      return;
    }
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên và số điện thoại.')));
      return;
    }

    setState(() => _isOrdering = true);

    try {
      final order = OrderModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: OrderType.online,
        items: cart.items.entries.map((e) => OrderItem(dish: e.key, quantity: e.value)).toList(),
        totalPrice: cart.totalPrice,
        status: OrderStatus.pending,
        customerId: auth.user?.id,
        customerNote: 'Người nhận: ${_nameCtrl.text}\nSĐT: ${_phoneCtrl.text}\nLưu ý: ${_noteCtrl.text}',
        location: OrderLocation(
          lat: _currentP?.latitude ?? 0,
          lng: _currentP?.longitude ?? 0,
          address: 'Giao tận nơi (GPS)',
        ),
      );

      await _db.placeOrder(order);
      
      if (mounted) {
        cart.clear();
        setState(() => _isOrdering = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã đặt hàng Online thành công!')));
        // Logic: Redirect to history or tracking
      }
    } catch (e) {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... building UI (same as before but connect _placeOnlineOrder)
    final bool isTooFar = _distanceKm > 10.0;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đặt hàng Online', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(initialCenter: _currentP ?? const LatLng(21.0285, 105.8542), initialZoom: 15),
                children: [
                   TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.app'),
                  if (_restaurantP != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(point: _restaurantP!, radius: 10000, useRadiusInMeter: true, color: Colors.red.withValues(alpha: 0.1), borderColor: Colors.red.withValues(alpha: 0.3), borderStrokeWidth: 2),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_restaurantP != null) Marker(point: _restaurantP!, width: 40, height: 40, child: const Icon(Icons.restaurant_rounded, color: Colors.red, size: 40)),
                      if (_currentP != null) Marker(point: _currentP!, width: 40, height: 40, child: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 40)),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isTooFar ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: isTooFar ? Colors.red : Colors.green),
                          const SizedBox(width: 8),
                          Text(isTooFar ? 'Ngoài phạm vi giao hàng (10km)' : 'Trong phạm vi giao hàng', style: TextStyle(fontWeight: FontWeight.bold, color: isTooFar ? Colors.red : Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Khoảng cách: ${_distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const Divider(height: 24),
                      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên người nhận', prefixIcon: Icon(Icons.person_outline))),
                      const SizedBox(height: 8),
                      TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_android_outlined))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: (isTooFar || _isOrdering || cart.items.isEmpty) ? null : _placeOnlineOrder,
                          child: _isOrdering 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Xác nhận đặt hàng'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(top: 16, right: 16, child: FloatingActionButton.small(onPressed: _initLocation, child: const Icon(Icons.my_location_rounded))),
            ],
          ),
    );
  }
}

