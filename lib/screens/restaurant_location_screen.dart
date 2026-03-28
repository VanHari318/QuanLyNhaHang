import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';

/// Màn hình Admin: thiết lập vị trí và bán kính nhà hàng (Geofencing)
class RestaurantLocationScreen extends StatefulWidget {
  const RestaurantLocationScreen({super.key});

  @override
  State<RestaurantLocationScreen> createState() => _RestaurantLocationScreenState();
}

class _RestaurantLocationScreenState extends State<RestaurantLocationScreen> {
  final _db = DatabaseService();
  final _mapController = MapController();

  // Vị trí mặc định: TP.HCM
  LatLng _pinLocation = const LatLng(10.7769, 106.7009);
  double _radius = 15.0; // mét
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final config = await _db.getRestaurantConfig().first;
    if (config != null && mounted) {
      final lat = (config['lat'] as num).toDouble();
      final lng = (config['lng'] as num).toDouble();
      final radius = (config['radiusMeters'] as num?)?.toDouble() ?? 15.0;
      setState(() {
        _pinLocation = LatLng(lat, lng);
        _radius = radius.clamp(10.0, 30.0);
        _isLoaded = true;
      });
      // Chờ bản đồ sẵn sàng rồi mới move
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _mapController.move(_pinLocation, 18.0);
        }
      });
    } else {
      setState(() => _isLoaded = true);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ Cần cấp quyền vị trí để sử dụng tính năng này')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _pinLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_pinLocation, 19.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lấy vị trí: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _saveLocation() async {
    setState(() => _isSaving = true);
    try {
      await _db.setRestaurantLocation(
        _pinLocation.latitude,
        _pinLocation.longitude,
        _radius,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu vị trí nhà hàng!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.map_rounded, size: 22),
            SizedBox(width: 10),
            Text('Vị Trí Nhà Hàng',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Bản đồ (60% màn hình) ────────────────────────────────
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pinLocation,
                          initialZoom: 18.0,
                          maxZoom: 20.0,
                          minZoom: 5.0,
                          // Khi tap vào bản đồ, di chuyển ghim
                          onTap: (tapPos, latlng) {
                            setState(() => _pinLocation = latlng);
                          },
                        ),
                        children: [
                          // Lớp tile bản đồ OpenStreetMap
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.quanlynhahang.app',
                          ),

                          // Vòng tròn geofence
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _pinLocation,
                                radius: _radius,
                                useRadiusInMeter: true,
                                color: cs.primary.withValues(alpha: 0.18),
                                borderColor: cs.primary.withValues(alpha: 0.7),
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),

                          // Ghim vị trí nhà hàng
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _pinLocation,
                                width: 50,
                                height: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('🍽️',
                                          style: TextStyle(fontSize: 10)),
                                    ),
                                    Icon(Icons.location_pin,
                                        color: cs.primary, size: 36),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Attribution
                          const RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution('OpenStreetMap contributors'),
                            ],
                          ),
                        ],
                      ),

                      // Nút "Về vị trí tôi"
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'gps_btn',
                          backgroundColor: cs.surface,
                          foregroundColor: cs.primary,
                          tooltip: 'Lấy vị trí hiện tại',
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          child: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ),

                      // Hint tap to move pin
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '👆 Chạm vào bản đồ để di chuyển ghim',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bảng điều khiển (40% còn lại) ───────────────────────
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hiển thị tọa độ
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(Icons.pin_drop_rounded,
                                    color: cs.primary, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lat: ${_pinLocation.latitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Lng: ${_pinLocation.longitude.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Slider bán kính (10 - 30m)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.radar_rounded,
                                        color: cs.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bán kính cho phép đặt món: ',
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      '${_radius.round()}m',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: cs.primary),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _radius,
                                  min: 10.0,
                                  max: 30.0,
                                  divisions: 20,
                                  label: '${_radius.round()}m',
                                  onChanged: (v) => setState(() => _radius = v),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('10m', style: TextStyle(color: cs.outlineVariant, fontSize: 11)),
                                    Text('30m', style: TextStyle(color: cs.outlineVariant, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Nút hành động
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: _isLocating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.my_location_rounded),
                                label: const Text('GPS Hiện Tại'),
                                onPressed:
                                    _isLocating ? null : _getCurrentLocation,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.save_rounded),
                                label: const Text('Lưu Vị Trí'),
                                onPressed: _isSaving ? null : _saveLocation,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        // Ghi chú
                        Text(
                          '💡 Mẹo: Mở Google Maps → nhấn giữ vào địa điểm → chép tọa độ đỏ bên dưới, sau đó bấm vào bản đồ cho ghim dịch về vị trí đó.',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
