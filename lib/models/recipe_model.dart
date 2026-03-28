// Model công thức nấu của 1 món ăn – Firestore collection: 'bulk_ingredients_100'
// Cấu trúc: 1 suất – lưu dưới dạng dishId -> {servings:1, ingredients:[{name, quantity, unit}]}

class RecipeIngredient {
  final String name;     // Tên nguyên liệu (khớp với Inventory.name)
  final double quantity; // Số lượng cho 1 suất
  final String unit;     // Đơn vị (kg, lít, g, cái...)

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'total_quantity': quantity,
        'unit': unit,
      };

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      name: map['name'] ?? '',
      quantity: (map['total_quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
    );
  }

  RecipeIngredient copyWith({String? name, double? quantity, String? unit}) {
    return RecipeIngredient(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}

class DishRecipeModel {
  final int servings; // Số suất công thức này tính cho (luôn = 1 cho UX mới)
  final List<RecipeIngredient> ingredients;

  const DishRecipeModel({
    this.servings = 1,
    required this.ingredients,
  });

  Map<String, dynamic> toMap() => {
        'servings': servings,
        'ingredients': ingredients.map((i) => i.toMap()).toList(),
      };

  factory DishRecipeModel.fromMap(Map<String, dynamic> map) {
    final rawIngredients = map['ingredients'] as List<dynamic>? ?? [];
    return DishRecipeModel(
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      ingredients: rawIngredients
          .map((i) => RecipeIngredient.fromMap(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
