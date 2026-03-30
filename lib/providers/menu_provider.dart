import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../models/recipe_model.dart';
import '../models/inventory_model.dart';
import '../services/database_service.dart';

/// Provider quản lý menu món ăn với category filter và best-seller toggle
class MenuProvider with ChangeNotifier {
  final _db = DatabaseService();

  List<DishModel> _allItems = [];
  Map<String, DishRecipeModel> _recipes = {};
  String _selectedCategory = ''; // '' = tất cả
  String _searchQuery = '';
  bool? _isSortAsc;

  List<DishModel> get allItems => _allItems;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool? get isSortAsc => _isSortAsc;

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
    _init();
  }

  Future<void> _init() async {
    // Lắng nghe tất cả món từ Firestore realtime
    _db.getDishes().listen((items) {
      _allItems = items;
      notifyListeners();
    });
    // Load công thức
    await refreshRecipes();
  }

  Future<void> refreshRecipes() async {
    _recipes = await _db.getAllDishRecipes();
    notifyListeners();
  }

  /// Kiểm tra xem món ăn có bị hết nguyên liệu hay không
  bool isOutOfStock(String dishId, List<InventoryModel> inventory) {
    if (_recipes.isEmpty) return false; // Nếu chưa load xong công thức thì chưa báo hết
    
    final recipe = _recipes[dishId];
    if (recipe == null || recipe.ingredients.isEmpty) return false;

    for (var ing in recipe.ingredients) {
      // Chuẩn hóa tên để so sánh (không phân biệt hoa thường, khoảng trắng)
      final normIngName = ing.name.trim().toLowerCase();
      
      // Tìm nguyên liệu trong kho
      final stockItem = inventory.firstWhere(
        (i) => i.name.trim().toLowerCase() == normIngName,
        orElse: () => InventoryModel(id: '', name: ing.name, quantity: 0, unit: ing.unit),
      );

      // Tính lượng cần cho 1 suất (đảm bảo không chia cho 0)
      final nServings = (recipe.servings > 0) ? recipe.servings : 1;
      double requiredQty = ing.quantity / nServings;
      
      // Quy đổi đơn vị
      final recipeUnit = ing.unit.toLowerCase().trim();
      final stockUnit = stockItem.unit.toLowerCase().trim();
      
      const kgUnits = ['kg', 'kí', 'kilogram', 'kilôgam', 'ký', 'kilo', 'k'];
      const gUnits = ['g', 'gam', 'gram'];
      const lUnits = ['lít', 'lit', 'l', 'litre', 'liter'];
      const mlUnits = ['ml', 'mililit', 'milliliter', 'mili'];

      // Quy đổi về cùng đơn vị nếu cần
      if (gUnits.contains(recipeUnit) && kgUnits.contains(stockUnit)) {
        requiredQty /= 1000;
      } else if (mlUnits.contains(recipeUnit) && lUnits.contains(stockUnit)) {
        requiredQty /= 1000;
      } else if (kgUnits.contains(recipeUnit) && gUnits.contains(stockUnit)) {
        requiredQty *= 1000;
      } else if (lUnits.contains(recipeUnit) && mlUnits.contains(stockUnit)) {
        requiredQty *= 1000;
      }

      // Nếu đơn vị khác hẳn nhau (ví dụ: kg vs cái) thì so sánh trực tiếp số lượng
      if (stockItem.quantity < requiredQty) return true;
    }
    return false;
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
