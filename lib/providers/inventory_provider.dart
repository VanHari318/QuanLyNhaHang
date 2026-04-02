import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../models/recipe_model.dart';
import '../services/database_service.dart';
import '../utils/recipe_helper.dart';

/// Provider quản lý kho nguyên liệu
class InventoryProvider with ChangeNotifier {
  final _db = DatabaseService();
  List<InventoryModel> _items = [];
  Map<String, double> _maxUsagePerDish = {};

  List<InventoryModel> get items => _items;
  Map<String, double> get maxUsagePerDish => _maxUsagePerDish;

  /// Helper check: Có đang sắp hết (không đủ 20 suất món tốn nhất)
  bool isLowStock(InventoryModel item) {
    final maxUsage = _maxUsagePerDish[item.name] ?? 0;
    if (maxUsage > 0) {
      return item.quantity < (maxUsage * 20);
    }
    // Fallback: Nếu không có công thức, dùng logic cũ (dưới 20% hoặc 5 đơn vị)
    return item.maxQuantity > 0
        ? item.quantity < item.maxQuantity * 0.2
        : item.quantity < 5;
  }

  /// Tính tổng số món đang sắp hết cho Dashboard
  int get lowStockCount => _items.where((i) => isLowStock(i)).length;

  InventoryProvider() {
    _db.getInventory().listen((items) {
      _items = items;
      notifyListeners();
    });

    _db.getAllRecipes().listen((recipes) {
      _calculateMaxUsage(recipes);
      notifyListeners();
    });
  }

  void _calculateMaxUsage(Map<String, DishRecipeModel> recipes) {
    final Map<String, double> maxUsage = {};
    for (final recipe in recipes.values) {
      for (final ing in recipe.ingredients) {
        // Tìm đơn vị tương ứng trong kho để quy đổi cho đúng
        final invItem = _items.firstWhere(
          (i) => i.name == ing.name,
          orElse: () => const InventoryModel(id: '', name: '', quantity: 0, unit: ''),
        );

        final usagePerServing = RecipeHelper.calculateNeededQuantity(
          totalQuantityForBulk: ing.quantity,
          bulkServings: recipe.servings,
          unit: ing.unit,
          targetUnit: invItem.unit,
        );
        
        final current = maxUsage[ing.name] ?? 0;
        if (usagePerServing > current) {
          maxUsage[ing.name] = usagePerServing;
        }
      }
    }
    _maxUsagePerDish = maxUsage;
  }

  Future<void> addItem(InventoryModel item) async {
    await _db.saveInventoryItem(item);
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteInventoryItem(id);
  }

  /// Nhập kho: cộng số lượng
  Future<void> importStock(InventoryModel item, double qty, String note) async {
    final updated = item.copyWith(quantity: item.quantity + qty);
    final log = InventoryLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: item.id,
      itemName: item.name,
      type: InventoryLogType.import,
      quantity: qty,
      note: note,
    );
    await _db.adjustInventory(updated, log);
  }

  /// Xuất kho: trừ số lượng (không trừ âm)
  Future<void> exportStock(InventoryModel item, double qty, String note) async {
    final newQty = (item.quantity - qty).clamp(0.0, double.infinity);
    final updated = item.copyWith(quantity: newQty);
    final log = InventoryLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: item.id,
      itemName: item.name,
      type: InventoryLogType.export,
      quantity: qty,
      note: note,
    );
    await _db.adjustInventory(updated, log);
  }
}
