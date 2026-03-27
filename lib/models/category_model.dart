// Model danh mục – Firestore collection: 'categories'
class CategoryModel {
  final String id;    // appetizer | main | dessert | drink
  final String name;  // Khai vị | Món chính | Tráng miệng | Đồ uống

  const CategoryModel({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(id: map['id'] ?? '', name: map['name'] ?? '');
  }

  /// 4 danh mục mặc định
  static const List<CategoryModel> defaults = [
    CategoryModel(id: 'appetizer', name: 'Khai vị'),
    CategoryModel(id: 'main', name: 'Món chính'),
    CategoryModel(id: 'dessert', name: 'Tráng miệng'),
    CategoryModel(id: 'drink', name: 'Đồ uống'),
  ];

  /// Map id → label hiển thị
  static String labelOf(String id) {
    return defaults.firstWhere((c) => c.id == id,
            orElse: () => CategoryModel(id: id, name: id))
        .name;
  }
}
