import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../models/order_model.dart';

class CartProvider with ChangeNotifier {
  final Map<DishModel, int> _items = {};
  String? _tableId;
  String? _sessionId;

  Map<DishModel, int> get items => _items;
  String? get tableId => _tableId;
  String? get sessionId => _sessionId;

  void setTableConfig(String tid, String sid) {
    _tableId = tid;
    _sessionId = sid;
    notifyListeners();
  }

  int get totalCount => _items.values.fold(0, (sum, qty) => sum + qty);

  double get totalPrice => _items.entries.fold(0, (sum, entry) => sum + (entry.key.price * entry.value));

  void addItem(DishModel dish, {int quantity = 1}) {
    if (_items.containsKey(dish)) {
      _items[dish] = _items[dish]! + quantity;
    } else {
      _items[dish] = quantity;
    }
    notifyListeners();
  }

  void removeItem(DishModel dish) {
    if (!_items.containsKey(dish)) return;
    if (_items[dish]! > 1) {
      _items[dish] = _items[dish]! - 1;
    } else {
      _items.remove(dish);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
