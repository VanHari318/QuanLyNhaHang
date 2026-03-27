// Model cho món ăn – Firestore collection: 'dishes'
class DishModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;      // URL lưu trên Cloudinary
  final String category;      // appetizer | main | dessert | drink
  final bool isAvailable;     // trạng thái: true = có thể đặt
  final bool isBestSeller;    // đánh dấu best-seller
  final DateTime createdAt;

  DishModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.isBestSeller = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Chuyển sang Map để lưu Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'isBestSeller': isBestSeller,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Tạo từ Firestore document
  factory DishModel.fromMap(Map<String, dynamic> map) {
    return DishModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      isBestSeller: map['isBestSeller'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Copy with — dùng khi update một field
  DishModel copyWith({
    String? id, String? name, String? description,
    double? price, String? imageUrl, String? category,
    bool? isAvailable, bool? isBestSeller, DateTime? createdAt,
  }) {
    return DishModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
