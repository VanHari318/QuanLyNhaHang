import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/order_model.dart';
import '../../services/database_service.dart';
import '../../theme/admin_theme.dart';

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
      final res = await http.get(url, headers: {'User-Agent': 'QuanLyNhaHangAdminAppThemeDark/1.0'}).timeout(const Duration(seconds: 4));
      
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
  if (fallback.isNotEmpty && !fallback.toLowerCase().contains('ngẫu nhiên')) {
    return fallback;
  }
  return 'Tọa độ: ${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}';
}

/// Màn hình quản lý đơn hàng – Giao diện 1 Tab với lưới Lọc Trạng Thái
class OrderManagementScreen extends StatefulWidget {
  final OrderStatus? initialStatus;
  final DateTime? initialDate;

  const OrderManagementScreen({
    super.key,
    this.initialStatus,
    this.initialDate,
  });

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _db = DatabaseService();
  late OrderStatus? _selectedStatus; // null = "Tất cả"
  late DateTime? _selectedDate;     // null = "Tất cả"
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng'),
        backgroundColor: AdminColors.bgPrimary(context),
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
              style: AdminText.bodyMedium(context),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn hoặc bàn số...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AdminColors.bgElevated(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),
          
          // Thanh lọc trạng thái và ngày
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(context, null, 'Tất cả'),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, OrderStatus.preparing, 'Đang làm', AdminColors.info),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, OrderStatus.ready, 'Sẵn sàng', AdminColors.teal),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, OrderStatus.completed, 'Hoàn thành', AdminColors.success),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, OrderStatus.cancelled, 'Đã hủy', AdminColors.error),
                    ],
                  ),
                ),
              ),
              // Nút lọc ngày
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IntrinsicWidth(
                  child: ActionChip(
                    avatar: Icon(
                      _selectedDate == null ? Icons.calendar_today_rounded : Icons.event_available_rounded,
                      size: 18,
                      color: _selectedDate == null ? AdminColors.textSecondary(context) : Colors.white,
                    ),
                    label: Text(_selectedDate == null ? 'Ngày' : '${_selectedDate!.day}/${_selectedDate!.month}'),
                    onPressed: () => _selectDate(context),
                    backgroundColor: _selectedDate == null ? AdminColors.bgElevated(context) : AdminColors.crimson,
                    labelStyle: TextStyle(
                      color: _selectedDate == null ? AdminColors.textSecondary(context) : Colors.white,
                      fontWeight: _selectedDate == null ? FontWeight.w500 : FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: _selectedDate == null ? AdminColors.borderDefault(context) : AdminColors.crimson),
                  ),
                ),
              ),
              if (_selectedDate != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () => setState(() => _selectedDate = null),
                    tooltip: 'Xóa lọc ngày',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Danh sách đơn hàng realtime
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _db.getOrders(status: _selectedStatus),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AdminColors.error),
                        const SizedBox(height: 16),
                        Text('Lỗi nạp đơn hàng từ Firebase', style: TextStyle(color: AdminColors.textPrimary(context))),
                        const SizedBox(height: 8),
                        Text(snapshot.error.toString(), style: TextStyle(fontSize: 12, color: AdminColors.textMuted(context)), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AdminColors.crimson));
                }
                var orders = snapshot.data!;
                
                // Lọc thêm theo ngày nếu có
                if (_selectedDate != null) {
                  orders = orders.where((o) {
                    return o.createdAt.year == _selectedDate!.year &&
                           o.createdAt.month == _selectedDate!.month &&
                           o.createdAt.day == _selectedDate!.day;
                  }).toList();
                }

                // Lọc thêm theo chuỗi tìm kiếm nếu có
                if (_searchQuery.isNotEmpty) {
                  orders = orders.where((o) {
                    final searchStr = '${o.id} ${o.tableId ?? ""} ${o.customerNote ?? ""} ${o.type.name}'.toLowerCase();
                    return searchStr.contains(_searchQuery);
                  }).toList();
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 64, color: AdminColors.borderMuted(context)),
                        const SizedBox(height: 12),
                        Text(
                          _selectedStatus == null && _selectedDate == null 
                            ? 'Không có đơn hàng nào' 
                            : 'Không tìm thấy đơn hàng phù hợp',
                          style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _FullOrderCard(
                    order: orders[i],
                    db: _db,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, OrderStatus? status, String label, [Color? activeColor]) {
    final isSelected = _selectedStatus == status;
    final color = activeColor ?? AdminColors.crimson;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = status);
        }
      },
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.15),
      backgroundColor: AdminColors.bgElevated(context),
      labelStyle: TextStyle(
        color: isSelected ? color : AdminColors.textSecondary(context),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? color.withValues(alpha: 0.3) : AdminColors.borderDefault(context)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: AdminTheme.darkTheme.copyWith(
            colorScheme: AdminTheme.darkTheme.colorScheme.copyWith(
              primary: AdminColors.crimson,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }
}

// ── Full order card (Haidilao Premium Dark Style) ───────────────────────────
class _FullOrderCard extends StatefulWidget {
  final OrderModel order;
  final DatabaseService db;

  const _FullOrderCard({
    required this.order,
    required this.db,
  });

  @override
  State<_FullOrderCard> createState() => _FullOrderCardState();
}

class _FullOrderCardState extends State<_FullOrderCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final db = widget.db;
    final statusColor = _statusColor(order.status);
    final isOnline = order.type == OrderType.online;

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.bgCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.borderDefault(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.1),
                  statusColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(bottom: BorderSide(color: AdminColors.borderDefault(context))),
            ),
            child: Row(
              children: [
                // Icon Loại đơn
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isOnline ? AdminColors.info : AdminColors.crimson).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOnline ? Icons.delivery_dining_rounded : Icons.table_restaurant_rounded,
                    size: 20,
                    color: isOnline ? AdminColors.info : AdminColors.crimson,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online (#Mã: ${order.id})' : '${order.tableId ?? "?"}',
                        style: AdminText.h3(context).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AdminColors.textSecondary(context)),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(order.createdAt),
                            style: AdminText.caption(context),
                          ),
                          if (!isOnline) ...[
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: AdminColors.textMuted(context))),
                            const SizedBox(width: 8),
                            Text(
                              'Đơn: ${order.id.length > 5 ? order.id.substring(order.id.length - 5) : order.id}',
                              style: AdminText.caption(context),
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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: order.items.map((item) {
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 12),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: AdminColors.bgElevated(context),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: AdminColors.borderMuted(context)),
                         ),
                         child: Text(
                           '${item.quantity}x',
                           style: TextStyle(
                             color: AdminColors.textPrimary(context),
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
                               style: TextStyle(
                                 fontSize: 14,
                                 fontWeight: FontWeight.w600,
                                 color: AdminColors.textPrimary(context),
                               ),
                             ),
                             if (item.note != null && item.note!.isNotEmpty)
                               Padding(
                                 padding: const EdgeInsets.only(top: 4),
                                 child: Text(
                                   'Chú thích: ${item.note}',
                                   style: TextStyle(
                                     fontSize: 12, 
                                     color: Theme.of(context).brightness == Brightness.dark ? AdminColors.gold : AdminColors.crimson, 
                                     fontStyle: FontStyle.italic
                                   ),
                                 ),
                               ),
                           ],
                         ),
                       ),
                       Text(
                         '${_formatPrice(item.dish.price * item.quantity)}đ',
                         style: TextStyle(
                           fontWeight: FontWeight.w700,
                           fontSize: 14,
                           color: AdminColors.textPrimary(context),
                         ),
                       ),
                     ],
                   ),
                 );
              }).toList(),
            ),
          ),
          
          // Location (Online only)
          if (isOnline && order.location != null && order.location!.address.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AdminColors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_rounded, size: 20, color: AdminColors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Địa chỉ giao hàng',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.orange),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: _fetchRealAddress(order.location!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text('Đang tải địa chỉ từ bản đồ...', style: TextStyle(fontSize: 13, color: AdminColors.textSecondary(context), fontStyle: FontStyle.italic));
                            }
                            return Text(
                              snapshot.data ?? order.location!.address,
                              style: TextStyle(fontSize: 13, color: AdminColors.textPrimary(context), height: 1.3),
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
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatPrice(order.totalPrice)}đ',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark ? AdminColors.gold : AdminColors.crimson,
                        fontSize: 20,
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
                          style: IconButton.styleFrom(
                            backgroundColor: AdminColors.bgElevated(context),
                            foregroundColor: AdminColors.textPrimary(context),
                          ),
                          onPressed: () => _showMapSheet(context, order),
                        ),
                      
                      // Action logic
                      if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) ...[
                        TextButton(
                          onPressed: () {
                            _showCancelConfirm(context);
                          },
                          style: TextButton.styleFrom(foregroundColor: AdminColors.error),
                          child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        FilledButton(
                          onPressed: _isUpdating ? null : () => _proceedNextStatus(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminColors.crimson,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isUpdating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_nextActionText(order.status), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ] else if (order.status == OrderStatus.completed) 
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           decoration: BoxDecoration(
                             color: AdminColors.success.withValues(alpha: 0.15),
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                           ),
                           child: const Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.check_circle_rounded, color: AdminColors.success, size: 16),
                               SizedBox(width: 6),
                               Text('Đã xong', style: TextStyle(color: AdminColors.success, fontWeight: FontWeight.w700)),
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
        backgroundColor: AdminColors.bgCard(context),
        title: Text('Xác nhận hủy đơn', style: TextStyle(color: AdminColors.textPrimary(context))),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này không?', style: TextStyle(color: AdminColors.textSecondary(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Không', style: TextStyle(color: AdminColors.textSecondary(context))),
          ),
           FilledButton(
            onPressed: _isUpdating ? null : () async {
              setState(() => _isUpdating = true);
              try {
                Navigator.pop(ctx);
                await widget.db.updateOrderStatus(widget.order.id, OrderStatus.cancelled, order: widget.order);
              } finally {
                if (mounted) setState(() => _isUpdating = false);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
            child: _isUpdating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Hủy đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }

  void _proceedNextStatus(BuildContext context) async {
    OrderStatus nextStatus;
    switch (widget.order.status) {
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

    setState(() => _isUpdating = true);
    try {
      await widget.db.updateOrderStatus(widget.order.id, nextStatus, order: widget.order);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
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
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: BoxDecoration(
            color: AdminColors.bgPrimary(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AdminColors.bgCard(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: AdminColors.borderDefault(context))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: AdminColors.info),
                    const SizedBox(width: 8),
                    Text('Bản đồ giao hàng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AdminColors.textPrimary(context))),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: AdminColors.textSecondary(context)),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              
              // Address Info
              Container(
                color: AdminColors.bgCard(context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, color: AdminColors.crimson, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _fetchRealAddress(loc),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text(
                              'Đang tải địa chỉ từ bản đồ...',
                              style: TextStyle(fontSize: 14, color: AdminColors.textSecondary(context), fontStyle: FontStyle.italic),
                            );
                          }
                          return Text(
                            snapshot.data ?? (loc.address.isNotEmpty ? loc.address : 'Tọa độ: $lat, $lng'),
                            style: TextStyle(fontSize: 14, color: AdminColors.textPrimary(context), fontWeight: FontWeight.w500),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Map
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      // Order Management screen map might not have a dedicated controller exposed to state.
                      // Usually we need a MapController to dynamically zoom here.
                      // Let's check or simply leave it alone because the user is referring to the location screen map!
                    }
                  },
                  child: FlutterMap(
                    options: MapOptions(
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                        scrollWheelVelocity: 0.015,
                      ),
                      initialCenter: point,
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: Theme.of(context).brightness == Brightness.dark 
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
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
                          child: const Icon(Icons.location_on, color: AdminColors.crimsonBright, size: 50),
                        ),
                      ],
                    ),
                  ],
                ),
              ), // Đóng Listener
            ), // Đóng Expanded
              
            // Footer Link
              Container(
                color: AdminColors.bgCard(context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Copy Link OSM', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: AdminColors.bgElevated(context),
                          foregroundColor: AdminColors.textPrimary(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AdminColors.borderDefault(context))),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: osmUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Đã copy link bản đồ!', style: TextStyle(color: AdminColors.textPrimary(context)))),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Đã kiểm tra', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          backgroundColor: AdminColors.crimson,
                          foregroundColor: Colors.white,
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

Color _statusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending => AdminColors.warning,
      OrderStatus.preparing => AdminColors.info,
      OrderStatus.ready => AdminColors.teal,
      OrderStatus.served => AdminColors.purple,
      OrderStatus.completed => AdminColors.success,
      OrderStatus.cancelled => AdminColors.error,
    };

String _statusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pending => 'Chờ xử lý',
      OrderStatus.preparing => 'Đang làm',
      OrderStatus.ready => 'Sẵn sàng',
      OrderStatus.served => 'Đã phục vụ',
      OrderStatus.completed => 'Hoàn thành',
      OrderStatus.cancelled => 'Đã hủy',
    };
