import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/inventory_model.dart';
import '../models/chatbot_model.dart';
import '../models/recipe_model.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Lớp service tương tác với Firestore – project: quan-ly-nha-hang-20f37
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  // ─── COLLECTION REFERENCES ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _tables    => _db.collection('tables');
  CollectionReference<Map<String, dynamic>> get _users     => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _dishes    => _db.collection('dishes');
  CollectionReference<Map<String, dynamic>> get _categories => _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _orders    => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _inventory => _db.collection('inventory');
  CollectionReference<Map<String, dynamic>> get _invLogs   => _db.collection('inventory_logs');
  CollectionReference<Map<String, dynamic>> get _chatbot   => _db.collection('chatbot_data');
  CollectionReference<Map<String, dynamic>> get _bulkIngredients => _db.collection('bulk_ingredients_100');
  DocumentReference<Map<String, dynamic>>   get _config   => _db.collection('config').doc('restaurant');

  // ─── RESTAURANT CONFIG (Geofencing) ─────────────────────────────────────────

  Stream<Map<String, dynamic>?> getRestaurantConfig() {
    return _config.snapshots().map((s) => s.exists ? s.data() : null);
  }

  Future<void> setRestaurantLocation(double lat, double lng, double radiusMeters) async {
    await _config.set({
      'lat': lat,
      'lng': lng,
      'radiusMeters': radiusMeters,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── TABLES ─────────────────────────────────────────────────────────────────

  Stream<List<TableModel>> getTables() {
    return _tables.orderBy('id').snapshots().map(
      (s) => s.docs.map((d) => TableModel.fromMap(d.data())).toList(),
    );
  }

  Future<void> saveTable(TableModel table) async {
    await _tables.doc(table.id).set(table.toMap());
  }

  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    await _tables.doc(tableId).update({'status': status.name});
  }

  // ─── USERS ───────────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).update(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Stream<List<UserModel>> getAllStaff() {
    return _users
        .where('role', whereNotIn: ['admin', 'customer'])
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  Stream<List<UserModel>> getAllCustomers() {
    return _users
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  // ─── CATEGORIES ──────────────────────────────────────────────────────────────

  Stream<List<CategoryModel>> getCategories() {
    return _categories.snapshots().map(
      (s) => s.docs.map((d) => CategoryModel.fromMap(d.data())).toList(),
    );
  }

  Future<void> saveCategory(CategoryModel cat) async {
    await _categories.doc(cat.id).set(cat.toMap());
  }

  Future<void> deleteCategory(String id) async {
    await _categories.doc(id).delete();
  }

  // ─── DISHES ──────────────────────────────────────────────────────────────────

  Stream<List<DishModel>> getDishes({String? category}) {
    Query<Map<String, dynamic>> q = _dishes;
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    return q.orderBy('createdAt', descending: true).snapshots().map(
      (s) => s.docs.map((d) => DishModel.fromMap(d.data())).toList(),
    );
  }

  Future<void> saveDish(DishModel dish) async {
    await _dishes.doc(dish.id).set(dish.toMap());
  }

  Future<void> updateDish(DishModel dish) async {
    await _dishes.doc(dish.id).update(dish.toMap());
  }

  Future<void> deleteDish(String id) async {
    await _dishes.doc(id).delete();
  }

  Future<void> toggleBestSeller(String id, bool isBestSeller) async {
    await _dishes.doc(id).update({'isBestSeller': isBestSeller});
  }

  Future<void> toggleDishAvailability(String id, bool isAvailable) async {
    await _dishes.doc(id).update({'isAvailable': isAvailable});
  }

  // ─── ORDERS ──────────────────────────────────────────────────────────────────

  Stream<List<OrderModel>> getOrders({OrderType? type, OrderStatus? status, int limit = 300}) {
    // Dùng query đơn giản, sắp xếp client-side để tránh lỗi Firestore Index nếu không cần thiết
    Query<Map<String, dynamic>> q = _orders;
    if (type != null) q = q.where('type', isEqualTo: type.name);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    q = q.limit(limit); // Giới hạn để tránh load quá nhiều document gây chậm

    return q.snapshots().map((s) {
      final result = <OrderModel>[];
      for (final doc in s.docs) {
        try {
          result.add(OrderModel.fromMap(doc.data()));
        } catch (e) {
          debugPrint('Lỗi nạp Order: $e');
        }
      }
      // Ưu tiên sắp xếp thời gian mới nhất tại máy khách
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    });
  }

  Future<void> placeOrder(OrderModel order) async {
    await _orders.doc(order.id).set(order.toMap());
    
    // Tự động chuyển bàn sang "Đang phục vụ" nếu là dine_in
    if (order.type == OrderType.dine_in && order.tableId != null) {
      await updateTableStatus(order.tableId!, TableStatus.occupied);
    }
  }

  /// Stream tất cả đơn trong cùng 1 session (theo sessionId)
  Stream<List<OrderModel>> getOrdersBySession(String sessionId) {
    return _orders
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((s) {
      final result = <OrderModel>[];
      for (final doc in s.docs) {
        try {
          result.add(OrderModel.fromMap(doc.data()));
        } catch (_) {}
      }
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return result;
    });
  }

  /// Stream đơn của 1 khách cụ thể tại 1 bàn cụ thể (lọc local, bỏ qua sessionId để chống lỗi reload)
  Stream<List<OrderModel>> getOrdersByCustomerAndTable(String customerId, String tableId) {
    return _orders
        .where('tableId', isEqualTo: tableId)
        .snapshots()
        .map((s) {
      final result = <OrderModel>[];
      for (final doc in s.docs) {
        try {
          final order = OrderModel.fromMap(doc.data());
          if (order.customerId == customerId) {
            result.add(order);
          }
        } catch (_) {}
      }
      result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return result;
    });
  }

  /// Stream TẤT CẢ đơn hàng của 1 khách (để làm Lịch sử)
  Stream<List<OrderModel>> getAllOrdersByCustomer(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((s) {
      final result = <OrderModel>[];
      for (final doc in s.docs) {
        try {
          result.add(OrderModel.fromMap(doc.data()));
        } catch (_) {}
      }
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Mới nhất lên đầu
      return result;
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status, {OrderModel? order}) async {
    OrderModel? currentOrder = order;
    
    if (currentOrder == null) {
      final orderDoc = await _orders.doc(orderId).get();
      if (!orderDoc.exists) return;
      currentOrder = OrderModel.fromMap(orderDoc.data()!);
    }

    // 1. Tự động trừ kho nếu đơn hàng chuyển sang chuyển sang hoàn thành (completed)
    if (status == OrderStatus.completed) {
      // Kiểm tra tránh trừ 2 lần (nếu status cũ đã là completed rồi thì bỏ qua)
      if (currentOrder.status != OrderStatus.completed) {
        await _deductInventoryForOrder(currentOrder);
      }
    }

    // 2. Cập nhật status đơn hàng chính
    await _orders.doc(orderId).update({'status': status.name});

    // 3. Tự động trả bàn – Đã xóa bỏ để nhân viên dọn bàn thủ công (Tránh lỗi khách ngồi tiếp gọi món mới)
    // if ((status == OrderStatus.completed || status == OrderStatus.cancelled) && ... ) { ... }
  }

  Future<void> _deductInventoryForOrder(OrderModel order) async {
    final batch = _db.batch();
    final Map<String, Map<String, dynamic>> recipeCache = {};
    
    // Quét từng món trong đơn hàng
    for (final item in order.items) {
      final dishId = item.dish.id;
      final qty = item.quantity;
      
      // 1. Lấy công thức nấu (dùng cache nếu có)
      if (!recipeCache.containsKey(dishId)) {
        final recipeDoc = await _bulkIngredients.doc(dishId).get();
        if (recipeDoc.exists) {
          recipeCache[dishId] = recipeDoc.data()!;
        } else {
          recipeCache[dishId] = {}; // Đánh dấu không có công thức
        }
      }
      
      final recipeData = recipeCache[dishId]!;
      if (recipeData.isEmpty) continue;
      
      final servings = (recipeData['servings'] as num?)?.toDouble() ?? 100.0;
      final ingredients = recipeData['ingredients'] as List<dynamic>? ?? [];
      
      // 2. Tính lượng nguyên liệu trừ đi và update inventory
      for (final ing in ingredients) {
        final name = ing['name'] as String;
        final totalQuantityInRecipe = (ing['total_quantity'] as num).toDouble();
        final unitInRecipe = (ing['unit'] as String? ?? '').toLowerCase().trim();
        
        // Tính định mức cho số lượng đặt: (tổng lượng trong CT / số suất của CT) * số lượng khách đặt
        double deductAmount = (totalQuantityInRecipe / servings) * qty;
        
        // 3. Tìm nguyên liệu thực tế trong kho (theo tên chuẩn xác)
        final invQuery = await _inventory.where('name', isEqualTo: name).limit(1).get();
        if (invQuery.docs.isNotEmpty) {
          final invDoc = invQuery.docs.first;
          final currentQtyInStock = (invDoc.data()['quantity'] as num? ?? 0).toDouble();
          final unitInStock = (invDoc.data()['unit'] as String? ?? '').toLowerCase().trim();
          
          // 4. Quy đổi đơn vị THÔNG MINH
          const kgUnits = ['kg', 'kí', 'kilogram', 'kilôgam', 'ký', 'kilo'];
          const gUnits = ['g', 'gam', 'gram'];
          const lUnits = ['lít', 'lit', 'l', 'litre', 'liter'];
          const mlUnits = ['ml', 'mililit', 'milliliter', 'mili'];

          // Nếu công thức dùng G/GAM nhưng kho dùng KG/KÍ -> chia 1000
          if (gUnits.contains(unitInRecipe) && kgUnits.contains(unitInStock)) {
            deductAmount = deductAmount / 1000;
          }
          // Nếu công thức dùng ML nhưng kho dùng LÍT -> chia 1000
          else if (mlUnits.contains(unitInRecipe) && lUnits.contains(unitInStock)) {
            deductAmount = deductAmount / 1000;
          }
          // Trường hợp ngược lại: Kho dùng G nhưng công thức dùng KG -> nhân 1000
          else if (kgUnits.contains(unitInRecipe) && gUnits.contains(unitInStock)) {
            deductAmount = deductAmount * 1000;
          }
          // Kho dùng ML nhưng công thức dùng LÍT -> nhân 1000
          else if (lUnits.contains(unitInRecipe) && mlUnits.contains(unitInStock)) {
            deductAmount = deductAmount * 1000;
          }

          final newQty = currentQtyInStock - deductAmount;
          batch.update(invDoc.reference, {'quantity': newQty < 0 ? 0 : newQty});
          
          // 5. Ghi log tự động xuất kho
          final logId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + invDoc.id + '_' + math.Random().nextInt(100).toString();
          final log = InventoryLogModel(
             id: logId,
             itemId: invDoc.id,
             itemName: name,
             type: InventoryLogType.export,
             quantity: deductAmount,
             note: 'Auto xuất cho món ${item.dish.name} (SL: $qty). Trừ $deductAmount $unitInStock.'
          );
          batch.set(_invLogs.doc(logId), log.toMap());
        }
      }
    }
    await batch.commit();
  }

  // ─── INVENTORY ───────────────────────────────────────────────────────────────

  Stream<List<InventoryModel>> getInventory() {
    return _inventory.orderBy('name').snapshots().map(
      (s) => s.docs.map((d) => InventoryModel.fromMap(d.data())).toList(),
    );
  }

  Future<void> saveInventoryItem(InventoryModel item) async {
    await _inventory.doc(item.id).set(item.toMap());
  }

  Future<void> deleteInventoryItem(String id) async {
    await _inventory.doc(id).delete();
  }

  /// Nhập hoặc xuất kho: cập nhật quantity + ghi log
  Future<void> adjustInventory(InventoryModel item, InventoryLogModel log) async {
    final batch = _db.batch();
    batch.set(_inventory.doc(item.id), {'quantity': item.quantity}, SetOptions(merge: true));
    batch.set(_invLogs.doc(log.id), log.toMap());
    await batch.commit();
  }

  Stream<List<InventoryLogModel>> getInventoryLogs(String itemId) {
    return _invLogs
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => InventoryLogModel.fromMap(d.data())).toList());
  }

  // ─── RECIPE ──────────────────────────────────────────────────────────────────

  /// Lấy công thức nấu của một món ăn (null nếu chưa có)
  Future<DishRecipeModel?> getDishRecipe(String dishId) async {
    final doc = await _bulkIngredients.doc(dishId).get();
    if (!doc.exists || doc.data() == null) return null;
    return DishRecipeModel.fromMap(doc.data()!);
  }

  /// Lưu công thức nấu (tạo mới hoặc ghi đè)
  Future<void> saveDishRecipe(String dishId, DishRecipeModel recipe) async {
    final batch = _db.batch();
    
    for (final ing in recipe.ingredients) {
      final invQuery = await _inventory.where('name', isEqualTo: ing.name).limit(1).get();
      if (invQuery.docs.isEmpty) {
        final newId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + math.Random().nextInt(100).toString();
        final newItem = InventoryModel(
          id: newId,
          name: ing.name,
          quantity: 0,
          unit: ing.unit,
        );
        batch.set(_inventory.doc(newId), newItem.toMap());
      }
    }
    
    batch.set(_bulkIngredients.doc(dishId), recipe.toMap());
    await batch.commit();
  }

  /// Xóa công thức khi xóa món ăn
  Future<void> deleteRecipe(String dishId) async {
    await _bulkIngredients.doc(dishId).delete();
  }
  Future<Map<String, DishRecipeModel>> getAllDishRecipes() async {
    final snap = await _bulkIngredients.get();
    return {
      for (var doc in snap.docs)
        doc.id: DishRecipeModel.fromMap(doc.data())
    };
  }

  // ─── CHATBOT ─────────────────────────────────────────────────────────────────

  Stream<List<ChatBotModel>> getChatBotData() {
    return _chatbot.snapshots().map(
      (s) => s.docs.map((d) => ChatBotModel.fromMap(d.data())).toList(),
    );
  }

  Future<void> saveChatBotEntry(ChatBotModel entry) async {
    await _chatbot.doc(entry.id).set(entry.toMap());
  }

  Future<void> deleteChatBotEntry(String id) async {
    await _chatbot.doc(id).delete();
  }


  /// Tổng doanh thu ngày cụ thể (filter client-side, tránh Composite Index)
  Future<double> getRevenueForDate(DateTime date) async {
    // Lấy tất cả completed orders rồi filter theo ngày phía client
    final snap = await _orders
        .where('status', isEqualTo: OrderStatus.completed.name)
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      final order = OrderModel.fromMap(doc.data());
      if (order.createdAt.year == date.year &&
          order.createdAt.month == date.month &&
          order.createdAt.day == date.day) {
        total += order.totalPrice;
      }
    }
    return total;
  }

  /// Lấy doanh thu từng ngày trong 1 tháng (hiệu quả hơn gọi lẻ tẻ)
  Future<List<MapEntry<String, double>>> getMonthlyDailyRevenue(DateTime month) async {
    final stats = await getDetailedDashboardStats(month, DateTime.now());
    return stats.dailyRevenue;
  }

  /// Cấu trúc chứa toàn bộ thông tin thống kê Dashboard
  /// Giúp nạp 1 lần duy nhất thay vì gọi nhiều hàm lẻ tẻ gây chậm/hết hạn mức Firebase
  Future<DashboardStatsData> getDetailedDashboardStats(DateTime month, DateTime selectedDate) async {
    // Xác định khoảng thời gian đầu tháng và cuối tháng
    final startOfMonth = DateTime(month.year, month.month, 1);
    final nextMonth = month.month == 12 ? 1 : month.month + 1;
    final yearOfNextMonth = month.month == 12 ? month.year + 1 : month.year;
    final endOfMonth = DateTime(yearOfNextMonth, nextMonth, 0, 23, 59, 59);

    // Load tất cả đơn rồi filter client-side để tránh lỗi so sánh kiểu
    // (một số đơn cũ lưu createdAt dạng ISO String, đơn mới dùng Timestamp)
    // Firestore không thể so sánh chéo 2 kiểu → trả rỗng mà không báo lỗi
    final snap = await _orders.limit(2000).get();

    // Lọc theo khoảng tháng phía client
    final docsInMonth = snap.docs.where((doc) {
      try {
        final raw = doc.data()['createdAt'];
        DateTime dt;
        if (raw is String) {
          dt = DateTime.tryParse(raw) ?? DateTime(1970);
        } else if (raw != null) {
          dt = (raw as Timestamp).toDate();
        } else {
          return false;
        }
        return !dt.isBefore(startOfMonth) && !dt.isAfter(endOfMonth);
      } catch (_) {
        return false;
      }
    }).toList();

    double monthTotal = 0;
    double todayTotal = 0;
    final Map<int, double> dailyMap = {};
    final Map<String, int> dishFreq = {};
    
    final now = DateTime.now();
    final currentMonth = month.month;
    final currentYear = month.year;

    for (var doc in docsInMonth) {
      try {
        final order = OrderModel.fromMap(doc.data());

        // Chỉ tính toán doanh thu cho đơn hoàn thành
        if (order.status != OrderStatus.completed) continue;

        final orderDate = order.createdAt;
        monthTotal += order.totalPrice;

        // Thống kê theo ngày
        final day = orderDate.day;
        dailyMap[day] = (dailyMap[day] ?? 0) + order.totalPrice;

        // Doanh thu ngày được chọn (mặc định là hôm nay)
        if (orderDate.day == selectedDate.day &&
            orderDate.month == selectedDate.month &&
            orderDate.year == selectedDate.year) {
          todayTotal += order.totalPrice;
        }

        for (final item in order.items) {
          final name = item.dish.name;
          final qty = item.quantity;
          dishFreq[name] = (dishFreq[name] ?? 0) + qty;
        }
      } catch (e) {
        debugPrint('Lỗi parse order trong stats: $e');
      }
    }

    // Tạo danh sách 7 ngày gần nhất (từ selectedDate trở về trước)
    final last7Days = <MapEntry<String, double>>[];
    for (int i = 6; i >= 0; i--) {
      final d = selectedDate.subtract(Duration(days: i));
      // Chỉ lấy nếu cùng tháng/năm (đơn giản hóa)
      if (d.month == currentMonth && d.year == currentYear) {
        last7Days.add(MapEntry('${d.day}/${d.month}', dailyMap[d.day] ?? 0));
      } else {
        last7Days.add(MapEntry('${d.day}/${d.month}', 0));
      }
    }

    // Tạo danh sách toàn bộ ngày trong tháng cho biểu đồ chi tiết
    final fullMonth = <MapEntry<String, double>>[];
    final lastDay = (currentMonth == now.month && currentYear == now.year) 
        ? now.day 
        : DateTime(currentYear, currentMonth + 1, 0).day;
    for (int d = 1; d <= lastDay; d++) {
      fullMonth.add(MapEntry('$d', dailyMap[d] ?? 0));
    }

    // Sắp xếp món ăn bán chạy
    final sortedDishes = dishFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DashboardStatsData(
      todayRevenue: todayTotal,
      monthRevenue: monthTotal,
      weeklyRevenueTrend: last7Days,
      dailyRevenue: fullMonth,
      topDishes: sortedDishes.take(5).toList(),
    );
  }

  /// Bộ phân tích số thông minh (Ưu tiên chấm là thập phân theo yêu cầu 100.00)
  static double parseVnNum(String text) {
    String t = text.trim();
    if (t.isEmpty) return 0;

    // Nếu gõ kiểu 1.000,50 -> Chuyển thành 1000.50
    if (t.contains('.') && t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      // Nếu chỉ có dấu phẩy (1,5 hoặc 1,000)
      // Theo yêu cầu mới dot là thập phân, nên ta vẫn hỗ trợ phẩy là thập phân nếu chỉ có 1 dấu
      t = t.replaceAll(',', '.');
    }

    // Nếu lúc này vẫn còn nhiều dấu chấm (1.000.000) -> Coi là ngăn cách hàng nghìn
    if ('.'.allMatches(t).length > 1) {
      t = t.replaceAll('.', '');
    }

    return double.tryParse(t) ?? 0;
  }

  /// Top 5 món bán chạy (đếm tần suất xuất hiện trong orders completed)
  Future<List<MapEntry<String, int>>> getTopDishes({int limit = 5}) async {
    final snap = await _orders
        .where('status', isEqualTo: OrderStatus.completed.name)
        .get();
    final Map<String, int> freq = {};
    for (final doc in snap.docs) {
      final items = (doc.data()['items'] as List<dynamic>? ?? []);
      for (final item in items) {
        final name = (item['dish']?['name'] ?? '') as String;
        final qty = (item['quantity'] ?? 1) as int;
        freq[name] = (freq[name] ?? 0) + qty;
      }
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }
}

class DashboardStatsData {
  final double todayRevenue;
  final double monthRevenue;
  final List<MapEntry<String, double>> weeklyRevenueTrend;
  final List<MapEntry<String, double>> dailyRevenue;
  final List<MapEntry<String, int>> topDishes;

  DashboardStatsData({
    required this.todayRevenue,
    required this.monthRevenue,
    required this.weeklyRevenueTrend,
    required this.dailyRevenue,
    required this.topDishes,
  });
}
