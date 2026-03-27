import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../services/database_service.dart';

/// Provider quản lý menu món ăn với category filter và best-seller toggle
class MenuProvider with ChangeNotifier {
  final _db = DatabaseService();

  List<DishModel> _allItems = [];
  String _selectedCategory = ''; // '' = tất cả
  bool _isLoading = false;

  List<DishModel> get allItems => _allItems;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  /// Danh sách đã lọc theo category
  List<DishModel> get filteredItems {
    if (_selectedCategory.isEmpty) return _allItems;
    return _allItems.where((d) => d.category == _selectedCategory).toList();
  }

  MenuProvider() {
    // Lắng nghe tất cả món từ Firestore realtime
    _db.getDishes().listen((items) {
      _allItems = items;
      notifyListeners();
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> addDish(DishModel dish) async {
    await _db.saveDish(dish);
  }

  Future<void> updateDish(DishModel dish) async {
    await _db.updateDish(dish);
  }

  Future<void> deleteDish(String id) async {
    await _db.deleteDish(id);
  }

  Future<void> toggleBestSeller(String id, bool value) async {
    await _db.toggleBestSeller(id, value);
  }

  Future<void> toggleAvailability(String id, bool value) async {
    await _db.toggleDishAvailability(id, value);
  }
}
