import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../services/database_service.dart';

/// Provider quản lý menu món ăn với category filter và best-seller toggle
class MenuProvider with ChangeNotifier {
  final _db = DatabaseService();

  List<DishModel> _allItems = [];
  String _selectedCategory = ''; // '' = tất cả
  String _searchQuery = '';
  bool? _isSortAsc;
  bool _isLoading = false;

  List<DishModel> get allItems => _allItems;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool? get isSortAsc => _isSortAsc;
  bool get isLoading => _isLoading;

  /// Danh sách đã lọc theo category, search và sort
  List<DishModel> get filteredItems {
    var list = _allItems.toList();

    // 1. Lọc theo Category
    if (_selectedCategory.isNotEmpty) {
      list = list.where((d) => d.category == _selectedCategory).toList();
    }

    // 2. Lọc theo Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((d) => d.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 3. Sắp xếp theo Giá
    if (_isSortAsc != null) {
      list.sort((a, b) => _isSortAsc! ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
    }

    return list;
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSortByPrice() {
    if (_isSortAsc == null) {
      _isSortAsc = true;
    } else if (_isSortAsc == true) {
      _isSortAsc = false;
    } else {
      _isSortAsc = null; // Reset
    }
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
