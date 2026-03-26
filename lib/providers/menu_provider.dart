import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

class MenuProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<FoodItem> _items = [];
  bool _isLoading = false;

  List<FoodItem> get items => _items;
  bool get isLoading => _isLoading;

  MenuProvider() {
    _dbService.getMenu().listen((items) {
      _items = items;
      notifyListeners();
    });
  }

  Future<void> addItem(FoodItem item) async {
    await _dbService.addFoodItem(item);
  }

  Future<void> updateItem(FoodItem item) async {
    await _dbService.updateFoodItem(item);
  }

  Future<void> deleteItem(String id) async {
    await _dbService.deleteFoodItem(id);
  }
}
