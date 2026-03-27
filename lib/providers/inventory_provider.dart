import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/database_service.dart';

/// Provider quản lý kho nguyên liệu
class InventoryProvider with ChangeNotifier {
  final _db = DatabaseService();
  List<InventoryModel> _items = [];

  List<InventoryModel> get items => _items;

  InventoryProvider() {
    _db.getInventory().listen((items) {
      _items = items;
      notifyListeners();
    });
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
