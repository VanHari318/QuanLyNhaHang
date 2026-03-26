import 'food_item.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled,
}

enum OrderType {
  dineIn,
  online,
}

class OrderModel {
  final String id;
  final String tableNumber;
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final OrderType type;
  final DateTime createdAt;
  final String? customerAddress;

  OrderModel({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.type,
    required this.createdAt,
    this.customerAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'items': items.map((x) => x.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'customerAddress': customerAddress,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      tableNumber: map['tableNumber'] ?? '',
      items: List<OrderItem>.from(
          map['items']?.map((x) => OrderItem.fromMap(x)) ?? []),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      type: OrderType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => OrderType.dineIn,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      customerAddress: map['customerAddress'],
    );
  }
}

class OrderItem {
  final FoodItem foodItem;
  final int quantity;
  final String? note;

  OrderItem({
    required this.foodItem,
    required this.quantity,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodItem': foodItem.toMap(),
      'quantity': quantity,
      'note': note,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      foodItem: FoodItem.fromMap(map['foodItem']),
      quantity: map['quantity'] ?? 1,
      note: map['note'],
    );
  }
}
