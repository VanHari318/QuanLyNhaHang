import 'package:flutter/material.dart';
import '../models/dish_model.dart';
<<<<<<< HEAD
import '../services/database_service.dart';
=======
import '../models/recipe_model.dart';
import '../models/inventory_model.dart';
import '../services/database_service.dart';
import '../utils/recipe_helper.dart';
>>>>>>> 6690387 (sua loi)

/// Provider quản lý menu món ăn với category filter và best-seller toggle
class MenuProvider with ChangeNotifier {
  final _db = DatabaseService();

  List<DishModel> _allItems = [];
<<<<<<< HEAD
=======
  List<String> _topSellingIds = [];
  Map<String, DishRecipeModel> _recipes = {};
>>>>>>> 6690387 (sua loi)
  String _selectedCategory = ''; // '' = tất cả
  String _searchQuery = '';
  bool? _isSortAsc;
  bool _isLoading = false;

  List<DishModel> get allItems => _allItems;
<<<<<<< HEAD
=======
  List<String> get topSellingIds => _topSellingIds;
>>>>>>> 6690387 (sua loi)
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool? get isSortAsc => _isSortAsc;
  bool get isLoading => _isLoading;

<<<<<<< HEAD
=======
  /// Helper: Kiểm tra một món có nằm trong Top bán chạy không
  bool isTopSelling(String dishId) => _topSellingIds.contains(dishId);

>>>>>>> 6690387 (sua loi)
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
<<<<<<< HEAD
      notifyListeners();
    });
=======
      _refreshTopSellers();
      notifyListeners();
    });

    // Lắng nghe tất cả công thức nấu ăn
    _db.getAllRecipes().listen((recipes) {
      _recipes = recipes;
      notifyListeners();
    });
  }

  Future<void> _refreshTopSellers() async {
    try {
      _topSellingIds = await _db.getTopSellingDishIds(limit: 5);
      notifyListeners();
    } catch (_) {}
  }

  /// Kiểm tra xem món ăn có hết hàng hay không dựa trên tồn kho thực tế
  bool isOutOfStock(String dishId, List<InventoryModel> inventory) {
    if (inventory.isEmpty) return false;
    final recipe = _recipes[dishId];
    if (recipe == null) return false;

    for (var requirement in recipe.ingredients) {
      final invItem = inventory.firstWhere(
        (i) => i.name == requirement.name,
        orElse: () => const InventoryModel(id: '', name: '', quantity: 0, unit: ''),
      );

      // Truyền targetUnit để RecipeHelper convert đúng đơn vị (g→kg, ml→l)
      final needed = RecipeHelper.calculateNeededQuantity(
        totalQuantityForBulk: requirement.quantity,
        bulkServings: recipe.servings,
        unit: requirement.unit,
        targetUnit: invItem.unit, // ← quan trọng: convert đơn vị đúng
        orderQuantity: 1,
      );

      if (invItem.quantity < needed) {
        return true;
      }
    }
    return false;
>>>>>>> 6690387 (sua loi)
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
