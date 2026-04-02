import 'package:flutter/material.dart';
import '../models/dish_model.dart';
import '../models/recipe_model.dart';
import '../models/inventory_model.dart';
import '../services/database_service.dart';
import '../utils/recipe_helper.dart';

/// Provider quản lý menu món ăn với category filter và best-seller toggle
class MenuProvider with ChangeNotifier {
  final _db = DatabaseService();

  List<DishModel> _allItems = [];
  Map<String, DishRecipeModel> _recipes = {};
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

    // Lắng nghe tất cả công thức nấu ăn
    _db.getAllRecipes().listen((recipes) {
      _recipes = recipes;
      notifyListeners();
    });
  }

  /// Kiểm tra xem món ăn có hết hàng hay không dựa trên tồn kho thực tế
  bool isOutOfStock(String dishId, List<InventoryModel> inventory) {
    if (inventory.isEmpty) return false;
    final recipe = _recipes[dishId];
    if (recipe == null) return false; // Không có công thức -> Coi như không giới hạn kho (hoặc xử lý khác tùy ý)

    for (var requirement in recipe.ingredients) {
      // Tìm nguyên liệu trong kho theo tên (khớp chính xác như trong DatabaseService)
      final invItem = inventory.firstWhere(
        (i) => i.name == requirement.name,
        orElse: () => const InventoryModel(id: '', name: '', quantity: 0, unit: ''),
      );

      final needed = RecipeHelper.calculateNeededQuantity(
        totalQuantityForBulk: requirement.quantity,
        bulkServings: recipe.servings,
        unit: requirement.unit,
        orderQuantity: 1, // Kiểm tra cho 1 suất
      );

      if (invItem.quantity < needed) {
        return true; // Chỉ cần 1 nguyên liệu thiếu là hết hàng
      }
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
