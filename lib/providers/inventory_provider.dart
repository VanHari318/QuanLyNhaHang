import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/database_service.dart';

/// Provider quản lý kho nguyên liệu
class InventoryProvider with ChangeNotifier {
  final _db = DatabaseService();
  List<InventoryModel> _items = [];
  Map<String, double> _thresholds = {};

  List<InventoryModel> get items => _items;
  Map<String, double> get thresholds => _thresholds;

  InventoryProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to inventory
    _db.getInventory().listen((items) {
      _items = items;
      updateThresholds(); // Cập nhật lại ngưỡng khi kho thay đổi (để lấy đúng đơn vị)
      notifyListeners();
    });
  }

  Future<void> updateThresholds() async {
    final recipes = await _db.getAllDishRecipes();
    final Map<String, double> newThresholds = {};
    
    for (var recipe in recipes.values) {
      final servings = recipe.servings > 0 ? recipe.servings : 1;
      for (var ing in recipe.ingredients) {
        final amountPerServing = ing.quantity / servings;
        double threshold = amountPerServing * 20;

        // Chuẩn hóa tên để tìm kiếm và lưu trữ
        final normName = ing.name.trim().toLowerCase();

        // Tìm item trong kho để tính toán threshold theo đơn vị của kho
        final stockItem = _items.firstWhere(
          (i) => i.name.trim().toLowerCase() == normName,
          orElse: () => InventoryModel(id: '', name: ing.name, quantity: 0, unit: ing.unit),
        );

        // Quy đổi đơn vị THÔNG MINH
        final recipeUnit = ing.unit.toLowerCase().trim();
        final stockUnit = stockItem.unit.toLowerCase().trim();
        
        const kgUnits = ['kg', 'kí', 'kilogram', 'kilôgam', 'ký', 'kilo', 'k'];
        const gUnits = ['g', 'gam', 'gram'];
        const lUnits = ['lít', 'lit', 'l', 'litre', 'liter'];
        const mlUnits = ['ml', 'mililit', 'milliliter', 'mili'];

        if (gUnits.contains(recipeUnit) && kgUnits.contains(stockUnit)) {
          threshold /= 1000;
        } else if (mlUnits.contains(recipeUnit) && lUnits.contains(stockUnit)) {
          threshold /= 1000;
        } else if (kgUnits.contains(recipeUnit) && gUnits.contains(stockUnit)) {
          threshold *= 1000;
        } else if (lUnits.contains(recipeUnit) && mlUnits.contains(stockUnit)) {
          threshold *= 1000;
        }

        // Lưu ngưỡng cao nhất cho nguyên liệu này (đã dùng normName làm key)
        if (!newThresholds.containsKey(normName) || threshold > newThresholds[normName]!) {
          newThresholds[normName] = threshold;
        }
      }
    }
    _thresholds = newThresholds;
    notifyListeners();
  }

  bool isLow(InventoryModel item) {
    // Luôn chuẩn hóa tên khi truy xuất ngưỡng
    final normName = item.name.trim().toLowerCase();
    final threshold = _thresholds[normName] ?? 0.5; 
    return item.quantity < threshold;
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
