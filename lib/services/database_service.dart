import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../models/category_model.dart';
import '../models/inventory_model.dart';
import '../models/chatbot_model.dart';

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

  Stream<List<OrderModel>> getOrders({OrderType? type}) {
    Query<Map<String, dynamic>> q = _orders.orderBy('createdAt', descending: true);
    if (type != null) q = q.where('type', isEqualTo: type.name);
    return q.snapshots().map(
      (s) => s.docs.map((d) => OrderModel.fromMap(d.data())).toList(),
    );
  }

  Future<void> placeOrder(OrderModel order) async {
    await _orders.doc(order.id).set(order.toMap());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({'status': status.name});
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
    batch.update(_inventory.doc(item.id), {'quantity': item.quantity});
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

  // ─── DASHBOARD STATS ─────────────────────────────────────────────────────────

  /// Doanh thu theo ngày (lọc orders completed trong ngày đó)
  Future<double> getRevenueForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _orders
        .where('status', isEqualTo: OrderStatus.completed.name)
        .where('createdAt', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('createdAt', isLessThan: end.toIso8601String())
        .get();
    return snap.docs.fold<double>(
      0,
      (sum, d) => sum + ((d.data()['totalPrice'] ?? 0) as num).toDouble(),
    );
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
