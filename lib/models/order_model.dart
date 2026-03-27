// Model đơn hàng – Firestore collection: 'orders'
import 'dish_model.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }
enum OrderType { dine_in, online }

/// Vị trí GPS của khách (cho online order)
class OrderLocation {
  final double lat;
  final double lng;
  final String address;

  const OrderLocation({
    required this.lat,
    required this.lng,
    this.address = '',
  });

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'address': address,
  };

  factory OrderLocation.fromMap(Map<String, dynamic> map) {
    return OrderLocation(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final OrderType type;           // dine_in | online
  final String? tableId;          // nullable – chỉ có khi dine_in
  final List<OrderItem> items;
  final double totalPrice;
  final OrderStatus status;
  final OrderLocation? location;  // GPS – chỉ có khi online
  final DateTime createdAt;
  final String? customerNote;

  OrderModel({
    required this.id,
    required this.type,
    required this.items,
    required this.totalPrice,
    required this.status,
    this.tableId,
    this.location,
    this.customerNote,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'tableId': tableId,
    'items': items.map((x) => x.toMap()).toList(),
    'totalPrice': totalPrice,
    'status': status.name,
    'location': location?.toMap(),
    'customerNote': customerNote,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      type: OrderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => OrderType.dine_in,
      ),
      tableId: map['tableId'],
      items: (map['items'] as List<dynamic>? ?? [])
          .map((x) => OrderItem.fromMap(x as Map<String, dynamic>))
          .toList(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      location: map['location'] != null
          ? OrderLocation.fromMap(map['location'])
          : null,
      customerNote: map['customerNote'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Một dòng trong đơn hàng
class OrderItem {
  final DishModel dish;
  final int quantity;
  final String? note;

  const OrderItem({required this.dish, required this.quantity, this.note});

  Map<String, dynamic> toMap() => {
    'dish': dish.toMap(),
    'quantity': quantity,
    'note': note,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      dish: DishModel.fromMap(map['dish'] as Map<String, dynamic>),
      quantity: map['quantity'] ?? 1,
      note: map['note'],
    );
  }
}
