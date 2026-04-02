import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/order_model.dart';
import '../../services/database_service.dart';

/// Cache địa chỉ tránh gọi API OpenStreetMap liên tục
final Map<String, String> _geocodedAddressCache = {};
final Map<String, Future<String>> _inFlightRequests = {};
Future<void> _nominatimLock = Future.value();

Future<String> _fetchRealAddress(OrderLocation loc) {
  final key = '${loc.lat},${loc.lng}';
  
  if (_geocodedAddressCache.containsKey(key)) {
    return Future.value(_geocodedAddressCache[key]!);
  }

  if (_inFlightRequests.containsKey(key)) {
    return _inFlightRequests[key]!;
  }

  final futureStr = _enqueueNominatim(loc, key);

  _inFlightRequests[key] = futureStr;
  futureStr.whenComplete(() {
    _inFlightRequests.remove(key);
  });

  return futureStr;
}

Future<String> _enqueueNominatim(OrderLocation loc, String key) async {
  final oldLock = _nominatimLock;
  
  _nominatimLock = () async {
    try {
      await oldLock;
    } catch (_) {}

    if (_geocodedAddressCache.containsKey(key)) return;

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${loc.lat}&lon=${loc.lng}&zoom=16&addressdetails=1&accept-language=vi');
      final res = await http.get(url, headers: {'User-Agent': 'QuanLyNhaHangAdminApp/1.0'}).timeout(const Duration(seconds: 4));
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          String cleaned = displayName.replaceAll(', Việt Nam', '');
          _geocodedAddressCache[key] = cleaned;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải Nominatim: $e');
    }
    
    // Nominatim yêu cầu 1 request/giây, delay 1.1s để an toàn tuyệt đối
    await Future.delayed(const Duration(milliseconds: 1100));
  }();

  try {
    await _nominatimLock;
  } catch (_) {}

  if (_geocodedAddressCache.containsKey(key)) {
    return _geocodedAddressCache[key]!;
  }

  final fallback = loc.address;
  if (fallback.toLowerCase().contains('tp hcm') || fallback.toLowerCase().contains('ngẫu nhiên') || fallback.toLowerCase().contains('ho chi minh')) {
    return 'Tọa độ: ${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}';
  }
  return fallback.isNotEmpty ? fallback : 'Tọa độ: ${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}';
}

/// Màn hình quản lý đơn hàng – Giao diện 1 Tab với lưới Lọc Trạng Thái
class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _db = DatabaseService();
  OrderStatus? _selectedStatus; // null = "Tất cả"
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng'),
        backgroundColor: cs.surfaceContainerLowest,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Làm mới',
          )
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn hoặc bàn số...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          
          // Thanh lọc trạng thái ngang
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(null, 'Tất cả'),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.pending, 'Chờ xử lý', Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.preparing, 'Đang làm', Colors.blue),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.ready, 'Sẵn sàng', Colors.teal),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.completed, 'Hoàn thành', Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.cancelled, 'Đã hủy', cs.error),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Danh sách đơn hàng realtime
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _db.getOrders(status: _selectedStatus),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var orders = snapshot.data!;
                
                // Lọc thêm theo chuỗi tìm kiếm nếu có
                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((o) {
                    final searchStr = '${o.id} ${o.tableId ?? ""} ${o.customerNote ?? ""} ${o.type.name}'.toLowerCase();
                    return searchStr.contains(_searchQuery);
                  }).toList();
                }

                return RefreshIndicator(
                  onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
                  child: orders.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height - 300,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_rounded, size: 64, color: cs.outlineVariant),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedStatus == null ? 'Không có đơn hàng nào' : 'Không có đơn (${_statusLabel(_selectedStatus!)})',
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _FullOrderCard(
                            order: orders[i],
                            db: _db,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(OrderStatus? status, String label, [Color? activeColor]) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedStatus == status;
    final color = activeColor ?? cs.primary;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = status);
        }
      },
      showCheckmark: false,
      selectedColor: color,
      backgroundColor: cs.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : cs.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected ? BorderSide(color: color) : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ── Full order card (Haidilao style) ──────────────────────────────────────────
class _FullOrderCard extends StatelessWidget {
  final OrderModel order;
  final DatabaseService db;

  const _FullOrderCard({
    required this.order,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(order.status, cs);
    final isOnline = order.type == OrderType.online;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (Có gradient nhẹ của màu trạng thái)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Icon Loại đơn (Nhỏ gọn theo yêu cầu: Bàn vs Online)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isOnline ? cs.secondary : cs.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline ? Icons.delivery_dining_rounded : Icons.table_restaurant_rounded,
                    size: 20,
                    color: isOnline ? cs.secondary : cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online (Mã: ${order.id})' : 'Bàn ${order.tableId ?? "?"}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(order.createdAt),
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                          if (!isOnline) ...[
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: cs.onSurfaceVariant)),
                            const SizedBox(width: 8),
                            Text(
                              'Đơn: ${order.id.length > 5 ? order.id.substring(order.id.length - 5) : order.id}',
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ]
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: Text(
                    _statusLabel(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Danh sách món ăn
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: order.items.map((item) {
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                         decoration: BoxDecoration(
                           color: cs.surfaceContainerHighest,
                           borderRadius: BorderRadius.circular(6),
                         ),
                         child: Text(
                           '${item.quantity}x',
                           style: TextStyle(
                             color: cs.onSurface,
                             fontWeight: FontWeight.w800,
                             fontSize: 13,
                           ),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               item.dish.name,
                               style: const TextStyle(
                                 fontSize: 14,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                             if (item.note != null && item.note!.isNotEmpty)
                               Text(
                                 'Chú thích: ${item.note}',
                                 style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontStyle: FontStyle.italic),
                               ),
                           ],
                         ),
                       ),
                       Text(
                         '${_formatPrice(item.dish.price * item.quantity)}đ',
                         style: const TextStyle(
                           fontWeight: FontWeight.w600,
                           fontSize: 14,
                         ),
                       ),
                     ],
                   ),
                 );
              }).toList(),
            ),
          ),
          
          if (isOnline && order.location != null && order.location!.address.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.secondary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.location_on_rounded, size: 20, color: cs.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa chỉ giao hàng',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.secondary),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: _fetchRealAddress(order.location!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text('Đang tải địa chỉ từ bản đồ...', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic));
                            }
                            return Text(
                              snapshot.data ?? order.location!.address,
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
                            );
                          }
                        ),
                      ]
                    ),
                  ),
                ],
              ),
            ),
            
          const Divider(height: 1),
          
          // Footer (Tổng tiền + Action Buttons)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng cộng',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '${_formatPrice(order.totalPrice)}đ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Nút Map (chỉ hiện online)
                      if (isOnline && order.location != null && order.location!.lat != 0) 
                        IconButton.filledTonal(
                          icon: const Icon(Icons.map_rounded),
                          tooltip: 'Xem bản đồ',
                          onPressed: () => _showMapSheet(context, order),
                        ),
                      
                      // Action logic
                      if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
                        TextButton(
                          onPressed: () {
                            _showCancelConfirm(context);
                          },
                          style: TextButton.styleFrom(foregroundColor: cs.error),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () => _proceedNextStatus(context),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_nextActionText(order.status)),
                        ),
                      ] else if (order.status == OrderStatus.completed) 
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           decoration: BoxDecoration(
                             color: Colors.green.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: const Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                               SizedBox(width: 6),
                               Text('Đã xong', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                             ],
                           ),
                         )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              db.updateOrderStatus(order.id, OrderStatus.cancelled);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Hủy đơn'),
          ),
        ],
      )
    );
  }

  void _proceedNextStatus(BuildContext context) {
    OrderStatus nextStatus;
    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = OrderStatus.preparing;
        break;
      case OrderStatus.preparing:
        nextStatus = OrderStatus.ready;
        break;
      case OrderStatus.ready:
        nextStatus = OrderStatus.served;
        break;
      case OrderStatus.served:
        nextStatus = OrderStatus.completed;
        break;
      default:
        return;
    }
    db.updateOrderStatus(order.id, nextStatus);
  }

  String _nextActionText(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending: return 'Bắt đầu làm';
      case OrderStatus.preparing: return 'Đã xong món';
      case OrderStatus.ready: return 'Đã phục vụ';
      case OrderStatus.served: return 'Hoàn tất đơn';
      default: return 'Xong';
    }
  }

  void _showMapSheet(BuildContext context, OrderModel order) {
    final loc = order.location!;
    final lat = loc.lat;
    final lng = loc.lng;
    final point = LatLng(lat, lng);
    final osmUrl = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng&zoom=16';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text('Bản đồ giao hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              
              // Address Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _fetchRealAddress(loc),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text(
                              'Đang tải địa chỉ từ bản đồ...',
                              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                            );
                          }
                          return Text(
                            snapshot.data ?? (loc.address.isNotEmpty ? loc.address : 'Tọa độ: $lat, $lng'),
                            style: TextStyle(fontSize: 14, color: cs.onSurface, fontWeight: FontWeight.w500),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Map
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 16.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.mrdoanh.vilaiquan.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 80,
                          height: 80,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Footer Link
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Copy Link OSM'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: cs.surfaceContainerHighest,
                          foregroundColor: cs.onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: osmUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã copy link bản đồ!')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Đã kiểm tra'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: cs.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatPrice(double p) {
    final s = p.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

Color _statusColor(OrderStatus s, ColorScheme cs) => switch (s) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.preparing => Colors.blue,
      OrderStatus.ready => Colors.teal,
      OrderStatus.served => Colors.purple,
      OrderStatus.completed => Colors.green,
      OrderStatus.cancelled => cs.error,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Chờ xử lý',
      OrderStatus.preparing => 'Đang làm',
      OrderStatus.ready => 'Sẵn sàng',
      OrderStatus.served => 'Đã phục vụ',
      OrderStatus.completed => 'Hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
    };
