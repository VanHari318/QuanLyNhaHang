import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/database_service.dart';
import '../../theme/admin_theme.dart';

/// Màn hình Admin: thiết lập vị trí và bán kính nhà hàng (Geofencing) – Haidilao Premium Dark
class RestaurantLocationScreen extends StatefulWidget {
  const RestaurantLocationScreen({super.key});

  @override
  State<RestaurantLocationScreen> createState() => _RestaurantLocationScreenState();
}

class _RestaurantLocationScreenState extends State<RestaurantLocationScreen> {
  final _db = DatabaseService();
  final _mapController = MapController();


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
            const SnackBar(
              content: Text('⚠️ Cần cấp quyền vị trí để sử dụng tính năng này', style: TextStyle(color: Colors.white)),
              backgroundColor: AdminColors.warning,
            ),
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
          SnackBar(
            content: Text('Lỗi lấy vị trí: $e', style: TextStyle(color: AdminColors.textPrimary(context))),
            backgroundColor: AdminColors.error,
          ),
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
            content: Text('✅ Đã lưu vị trí nhà hàng!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu: $e', style: TextStyle(color: AdminColors.textPrimary(context))),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      appBar: AppBar(
        backgroundColor: AdminColors.bgPrimary(context),
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Icon(Icons.map_rounded, size: 22, color: AdminColors.teal),
            SizedBox(width: 10),
            Text('Vị Trí Nhà Hàng',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      body: !_isLoaded
          ? const Center(child: CircularProgressIndicator(color: AdminColors.crimson))
          : Column(
              children: [
                // ── Bản đồ (60% màn hình) ────────────────────────────────
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            final delta = pointerSignal.scrollDelta.dy;
                            final currentZoom = _mapController.camera.zoom;
                            // dy > 0 means scroll down, usually zoom out. dy < 0 means scroll up, zoom in.
                            final newZoom = currentZoom - (delta > 0 ? 0.5 : -0.5);
                            _mapController.move(_pinLocation, newZoom.clamp(5.0, 20.0));
                          }
                        },
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                              scrollWheelVelocity: 0.015, // Tăng tốc độ zoom bằng chuột giữa
                            ),
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
                            // Bản đồ Haidilao Style - Đổi style theo theme!
                            TileLayer(
                              urlTemplate: Theme.of(context).brightness == Brightness.dark 
                                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                  : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                              subdomains: const ['a', 'b', 'c', 'd'],
                              userAgentPackageName: 'com.mrdoanh.vilaiquan.app',
                            ),
  
                            // Vòng tròn geofence
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _pinLocation,
                                  radius: _radius,
                                  useRadiusInMeter: true,
                                  color: AdminColors.teal.withValues(alpha: 0.18),
                                  borderColor: AdminColors.teal.withValues(alpha: 0.7),
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
                                          color: AdminColors.teal,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(color: AdminColors.teal.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)
                                          ],
                                        ),
                                        child: const Text('🍽️',
                                            style: TextStyle(fontSize: 10)),
                                      ),
                                      const Icon(Icons.location_pin,
                                          color: AdminColors.teal, size: 36),
                                    ],
                                  ),
                                ),
                              ],
                            ),
  
                            // Attribution
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution('OpenStreetMap contributors\nTiles © CartoDB Carto', textStyle: TextStyle(color: AdminColors.textMuted(context), fontSize: 10)),
                              ],
                              popupBackgroundColor: AdminColors.bgElevated(context),
                            ),
                          ],
                        ),
                      ),

                      // Nút "Về vị trí tôi"
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: FloatingActionButton.small(
                          heroTag: 'gps_btn',
                          backgroundColor: AdminColors.bgCard(context),
                          foregroundColor: AdminColors.gold,
                          tooltip: 'Lấy vị trí hiện tại',
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AdminColors.borderDefault(context))),
                          onPressed: _isLocating ? null : _getCurrentLocation,
                          child: _isLocating
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.gold),
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
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AdminColors.bgPrimary(context).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AdminColors.borderDefault(context)),
                            ),
                            child: Text(
                              '👆 Chạm vào bản đồ để di chuyển ghim (Nhà Hàng)',
                              style: TextStyle(color: AdminColors.textPrimary(context), fontSize: 12, fontWeight: FontWeight.bold),
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AdminColors.bgCard(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AdminColors.borderDefault(context)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AdminColors.teal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.pin_drop_rounded,
                                    color: AdminColors.teal, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vĩ độ (Lat): ${_pinLocation.latitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                          fontFamily: 'monospace',
                                          color: AdminColors.textPrimary(context),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Kinh độ (Lng): ${_pinLocation.longitude.toStringAsFixed(6)}',
                                      style: TextStyle(
                                          fontFamily: 'monospace',
                                          color: AdminColors.textPrimary(context),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Slider bán kính (10 - 30m)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AdminColors.bgCard(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AdminColors.borderDefault(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.radar_rounded,
                                      color: AdminColors.teal, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bán kính cho phép đặt món: ',
                                    style: TextStyle(
                                        color: AdminColors.textSecondary(context),
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AdminColors.teal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_radius.round()}m',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AdminColors.teal),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Slider(
                                value: _radius,
                                min: 10.0,
                                max: 30.0,
                                divisions: 20,
                                activeColor: AdminColors.teal,
                                inactiveColor: AdminColors.bgElevated(context),
                                label: '${_radius.round()}m',
                                onChanged: (v) => setState(() => _radius = v),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('10m', style: TextStyle(color: AdminColors.textMuted(context), fontSize: 11)),
                                  Text('30m', style: TextStyle(color: AdminColors.textMuted(context), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nút hành động
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AdminColors.borderDefault(context)),
                                  foregroundColor: AdminColors.textPrimary(context),
                                  backgroundColor: AdminColors.bgElevated(context),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: _isLocating
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(strokeWidth: 2, color: AdminColors.textPrimary(context)))
                                    : Icon(Icons.my_location_rounded, size: 20, color: AdminColors.gold),
                                label: const Text('GPS Gốc'),
                                onPressed:
                                    _isLocating ? null : _getCurrentLocation,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AdminColors.crimson,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.save_rounded, size: 20),
                                label: const Text('Lưu Vị Trí & Khóa Tọa Độ', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _isSaving ? null : _saveLocation,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Ghi chú
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AdminColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '💡 Mẹo: Mở Google Maps → nhấn giữ vào địa điểm → chép tọa độ đỏ bên dưới, sau đó thao tác thu phóng bản đồ tại đây để chỉnh vị trí chốt.',
                            style: TextStyle(
                                color: AdminColors.textSecondary(context), fontSize: 12),
                          ),
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
