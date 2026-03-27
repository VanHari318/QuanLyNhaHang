// Model nguyên liệu kho – Firestore collection: 'inventory'
class InventoryModel {
  final String id;
  final String name;
  final double quantity;
  final String unit;  // kg | lít | cái | túi...
  final double maxQuantity; // ngưỡng tối đa để tính % còn lại

  const InventoryModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.maxQuantity = 0, // 0 = không đặt (dùng fallback < 5)
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'maxQuantity': maxQuantity,
  };

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      maxQuantity: (map['maxQuantity'] ?? 0).toDouble(),
    );
  }

  InventoryModel copyWith({String? name, double? quantity, String? unit, double? maxQuantity}) {
    return InventoryModel(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      maxQuantity: maxQuantity ?? this.maxQuantity,
    );
  }
}

// Log nhập/xuất kho – Firestore collection: 'inventory_logs'
enum InventoryLogType { import, export }

class InventoryLogModel {
  final String id;
  final String itemId;
  final String itemName;
  final InventoryLogType type;
  final double quantity;
  final String note;
  final DateTime timestamp;

  InventoryLogModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    this.note = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'type': type.name,
    'quantity': quantity,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
  };

  factory InventoryLogModel.fromMap(Map<String, dynamic> map) {
    return InventoryLogModel(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      type: InventoryLogType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InventoryLogType.import,
      ),
      quantity: (map['quantity'] ?? 0).toDouble(),
      note: map['note'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
