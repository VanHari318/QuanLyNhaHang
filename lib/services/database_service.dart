import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/food_item.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // TABLE OPERATIONS
  Stream<List<TableModel>> getTables() {
    return _db.collection('tables').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TableModel.fromMap(doc.data())).toList());
  }

  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    await _db.collection('tables').doc(tableId).update({
      'status': status.toString().split('.').last,
    });
  }

  Future<void> saveTable(TableModel table) async {
    await _db.collection('tables').doc(table.id).set(table.toMap());
  }

  // USER OPERATIONS
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<List<UserModel>> getAllStaff() {
    return _db.collection('users')
        .where('role', isNotEqualTo: 'admin')
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data())).toList());
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // MENU OPERATIONS
  Stream<List<FoodItem>> getMenu() {
    return _db.collection('menu').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => FoodItem.fromMap(doc.data())).toList());
  }

  Future<void> addFoodItem(FoodItem item) async {
    await _db_collection_menu.doc(item.id).set(item.toMap());
  }

  Future<void> updateFoodItem(FoodItem item) async {
    await _db_collection_menu.doc(item.id).update(item.toMap());
  }

  Future<void> deleteFoodItem(String id) async {
    await _db_collection_menu.doc(id).delete();
  }

  CollectionReference<Map<String, dynamic>> get _db_collection_menu => _db.collection('menu');

  // ORDER OPERATIONS
  Stream<List<OrderModel>> getOrders() {
    return _db.collection('orders').orderBy('createdAt', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList());
  }

  Future<void> placeOrder(OrderModel order) async {
    await _db.collection('orders').doc(order.id).set(order.toMap());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status.toString().split('.').last,
    });
  }
}
