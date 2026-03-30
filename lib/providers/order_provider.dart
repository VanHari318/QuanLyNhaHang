import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderProvider() {
    _dbService.getOrders().listen((orders) {
      _orders = orders;
      notifyListeners();
    });
  }

  Future<void> placeOrder(OrderModel order) async {
    await _dbService.placeOrder(order);
  }

  Future<void> updateStatus(String orderId, OrderStatus status, {OrderModel? order}) async {
    await _dbService.updateOrderStatus(orderId, status, order: order);
  }
}
