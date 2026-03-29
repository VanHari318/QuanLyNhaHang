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

/// Lớp service tương tác với Firestore – project: quan-ly-nha-hang-20f37
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  Stream<List<OrderModel>> getOrders({OrderType? type, OrderStatus? status}) {
    // Dùng query đơn giản để tránh lỗi Firestore Composite Index
    // Sort được thực hiện client-side sau khi nhận data
    Query<Map<String, dynamic>> q = _orders;
    if (type != null) q = q.where('type', isEqualTo: type.name);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map((s) {
      final result = <OrderModel>[];
      for (final doc in s.docs) {
        try {
          result.add(OrderModel.fromMap(doc.data()));
        } catch (_) {
          // Bỏ qua document lỗi format, không crash toàn stream
        }
      }
      // Sort client-side theo createdAt mới nhất
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    });
  }

  Future<void> placeOrder(OrderModel order) async {
    await _orders.doc(order.id).set(order.toMap());
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

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    // Tự động trừ kho nếu đơn hàng chuyển sang hoàn thành (completed)
    if (status == OrderStatus.completed) {
      final orderDoc = await _orders.doc(orderId).get();
      if (orderDoc.exists) {
        final order = OrderModel.fromMap(orderDoc.data()!);
        // Kiểm tra tránh trừ 2 lần (nếu status cũ đã là completed rồi thì bỏ qua)
        if (order.status != OrderStatus.completed) {
          await _deductInventoryForOrder(order);
        }
      }
    }
    await _orders.doc(orderId).update({'status': status.name});
  }

  Future<void> _deductInventoryForOrder(OrderModel order) async {
    final batch = _db.batch();
    
    // Quét từng món trong đơn hàng
    for (final item in order.items) {
      final dishId = item.dish.id;
      final qty = item.quantity;
      
      // 1. Lấy công thức nấu 100 suất
      final recipeDoc = await _bulkIngredients.doc(dishId).get();
      if (!recipeDoc.exists) continue;
      
      final recipeData = recipeDoc.data()!;
      final servings = (recipeData['servings'] as num?)?.toInt() ?? 100;
      final ingredients = recipeData['ingredients'] as List<dynamic>? ?? [];
      
      // 2. Tính lượng nguyên liệu trừ đi và update inventory
      for (final ing in ingredients) {
        final name = ing['name'] as String;
        final totalNeeded100 = (ing['total_quantity'] as num).toDouble();
        final unitStr = ing['unit'] as String;
        
        // Tính định mức 1 suất -> nhân với số lượng đặt
        double deductAmount = (totalNeeded100 / servings) * qty;
        
        // Quy đổi sang kg/lít nếu nguyên liệu dùng đơn vị > 1000g/ml
        if (totalNeeded100 >= 1000 && (unitStr == 'g' || unitStr == 'ml')) {
          deductAmount = deductAmount / 1000;
        }

        // 3. Tìm nguyên liệu thực tế trong kho (theo tên chuẩn xác)
        final invQuery = await _inventory.where('name', isEqualTo: name).limit(1).get();
        if (invQuery.docs.isNotEmpty) {
          final invDoc = invQuery.docs.first;
          final currentQty = (invDoc.data()['quantity'] as num).toDouble();
          
          final newQty = currentQty - deductAmount;
          batch.update(invDoc.reference, {'quantity': newQty < 0 ? 0 : newQty});
          
          // 4. Ghi log tự động xuất kho
          final logId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + invDoc.id + '_' + math.Random().nextInt(100).toString();
          final log = InventoryLogModel(
             id: logId,
             itemId: invDoc.id,
             itemName: name,
             type: InventoryLogType.export,
             quantity: deductAmount,
             note: 'Auto xuất món ${item.dish.name} (SL: $qty)'
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
    for (final doc in snap.docs) {
      try {
        final order = OrderModel.fromMap(doc.data());
        final d = order.createdAt;
        if (d.year == date.year && d.month == date.month && d.day == date.day) {
          total += order.totalPrice;
        }
      } catch (_) {}
    }
    return total;
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
