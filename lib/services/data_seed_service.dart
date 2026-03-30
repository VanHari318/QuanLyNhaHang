import 'dart:math' as math;
import '../models/order_model.dart';
import '../models/dish_model.dart';
import '../models/recipe_model.dart';
import 'database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeedService {
  final DatabaseService _db = DatabaseService();
  final math.Random _random = math.Random();

  Future<void> seedMockOrders({
    required Function(String) onProgress,
    required Function(String) onComplete,
    required Function(String) onError,
  }) async {
    try {
      // 1. Pre-fetch all data to avoid inner loop queries
      onProgress('Đang chuẩn bị thực đơn và kho...');
      final dishes = await _db.getDishes().first;
      if (dishes.isEmpty) {
        onError('Không tìm thấy món ăn nào. Hãy tạo món ăn trước.');
        return;
      }
      
      final inventoryItems = await _db.getInventory().first;
      final Map<String, double> inventoryMap = {for (var item in inventoryItems) item.name: item.quantity};
      final Map<String, String> inventoryIdMap = {for (var item in inventoryItems) item.name: item.id};
      final Map<String, String> inventoryUnitMap = {for (var item in inventoryItems) item.name: item.unit.toLowerCase().trim()};

      onProgress('Đang tải công thức...');
      final Map<String, DishRecipeModel> recipes = {};
      for (var d in dishes) {
        final r = await _db.getDishRecipe(d.id);
        if (r != null) recipes[d.id] = r;
      }

      final bestSellers = dishes.where((d) => d.isBestSeller).toList();
      final defaultBestSeller = bestSellers.isNotEmpty ? bestSellers.first : dishes.first;

      final targetDates = [
        DateTime(2026, 3, 22), DateTime(2026, 3, 23), DateTime(2026, 3, 24),
        DateTime(2026, 3, 25), DateTime(2026, 3, 26), DateTime(2026, 3, 27),
        DateTime(2026, 3, 30),
      ];

      final List<OrderModel> mockOrders = [];
      
      // 2. Generate Orders and Calculate Inventory in Memory
      onProgress('Đang tính toán dữ liệu mẫu...');
      for (var date in targetDates) {
        double currentDailyRevenue = 0;
        final targetRevenue = 3000000 + _random.nextDouble() * 2000000;
        
        while (currentDailyRevenue < targetRevenue) {
          final orderId = 'MOCK_${date.millisecondsSinceEpoch}_${_random.nextInt(10000)}';
          final itemCount = _random.nextInt(3) + 1;
          final List<OrderItem> items = [];
          double orderTotal = 0;

          for (int i = 0; i < itemCount; i++) {
            final DishModel selectedDish = (_random.nextDouble() < 0.66) ? defaultBestSeller : dishes[_random.nextInt(dishes.length)];
            final qty = _random.nextInt(2) + 1;
            items.add(OrderItem(dish: selectedDish, quantity: qty));
            orderTotal += selectedDish.price * qty;

            // Deduct from memory map
            final recipe = recipes[selectedDish.id];
            if (recipe != null) {
              for (var ing in recipe.ingredients) {
                if (inventoryMap.containsKey(ing.name)) {
                  double deductAmount = (ing.quantity / (recipe.servings ?? 1)) * qty;
                  
                  // Unit conversion logic (must match DatabaseService)
                  final recipeUnit = ing.unit.toLowerCase().trim();
                  final stockUnit = inventoryUnitMap[ing.name] ?? '';
                  const kgUnits = ['kg', 'kí', 'kilogram', 'kilôgam', 'ký', 'kilo'];
                  const gUnits = ['g', 'gam', 'gram'];
                  const lUnits = ['lít', 'lit', 'l', 'litre', 'liter'];
                  const mlUnits = ['ml', 'mililit', 'milliliter', 'mili'];

                  if (gUnits.contains(recipeUnit) && kgUnits.contains(stockUnit)) deductAmount /= 1000;
                  else if (mlUnits.contains(recipeUnit) && lUnits.contains(stockUnit)) deductAmount /= 1000;
                  else if (kgUnits.contains(recipeUnit) && gUnits.contains(stockUnit)) deductAmount *= 1000;
                  else if (lUnits.contains(recipeUnit) && mlUnits.contains(stockUnit)) deductAmount *= 1000;

                  inventoryMap[ing.name] = (inventoryMap[ing.name]! - deductAmount).clamp(0, double.infinity);
                }
              }
            }
          }

          final orderTime = date.add(Duration(hours: 8 + _random.nextInt(13), minutes: _random.nextInt(60)));
          mockOrders.add(OrderModel(
            id: orderId,
            type: _random.nextBool() ? OrderType.dine_in : OrderType.online,
            items: items,
            totalPrice: orderTotal,
            status: OrderStatus.completed,
            createdAt: orderTime,
            paymentMethod: 'Tiền mặt',
            tableId: 'Bàn ${_random.nextInt(10) + 1}',
          ));
          currentDailyRevenue += orderTotal;
        }
      }

      // 3. Batched Writes (Firestore limit: 500 per batch)
      onProgress('Đang tải dữ liệu lên Máy chủ (0%)...');
      final firestore = DatabaseService().db; // access internal db for batch
      
      // Save Orders
      for (int i = 0; i < mockOrders.length; i += 400) {
        final batch = firestore.batch();
        final chunk = mockOrders.skip(i).take(400);
        for (var o in chunk) {
          batch.set(firestore.collection('orders').doc(o.id), o.toMap());
        }
        onProgress('Đang lưu Đơn hàng (${(i / mockOrders.length * 100).toInt()}%)...');
        await batch.commit();
      }

      // Save Inventory Updates
      onProgress('Đang cập nhật kho hàng...');
      final invBatch = firestore.batch();
      inventoryMap.forEach((name, qty) {
        final id = inventoryIdMap[name];
        if (id != null) {
          invBatch.update(firestore.collection('inventory').doc(id), {'quantity': qty});
        }
      });
      await invBatch.commit();

      onComplete('Thành công! Đã sinh ${mockOrders.length} đơn hàng và cập nhật kho.');
    } catch (e) {
      onError('Lỗi: $e');
    }
  }
}
