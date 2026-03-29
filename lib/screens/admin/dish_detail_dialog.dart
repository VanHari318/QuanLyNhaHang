import 'package:flutter/material.dart';
import '../../models/dish_model.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../models/recipe_model.dart';
import 'recipe_editor_dialog.dart';

class DishDetailDialog extends StatefulWidget {
  final DishModel dish;
  const DishDetailDialog({super.key, required this.dish});

  @override
  State<DishDetailDialog> createState() => _DishDetailDialogState();
}

class _DishDetailDialogState extends State<DishDetailDialog> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  DishRecipeModel? _recipe;

  @override
  void initState() {
    super.initState();
    _fetchRecipe();
  }

  Future<void> _fetchRecipe() async {
    setState(() => _isLoading = true);
    final data = await _db.getDishRecipe(widget.dish.id);
    if (mounted) {
      setState(() {
        _recipe = data;
        _isLoading = false;
      });
    }
  }

  String _formatPrice(double price) {
    final s = price.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dish = widget.dish;
    final servings = _recipe?.servings ?? 1;
    final ingredients = _recipe?.ingredients ?? [];

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Chi tiết món ăn'),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dish basic info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: dish.imageUrl.isNotEmpty
                        ? Image.network(
                            dish.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(cs),
                          )
                        : _placeholder(cs),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(dish.price)} VNĐ',
                          style: TextStyle(color: cs.primary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            CategoryModel.labelOf(dish.category),
                            style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (dish.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(dish.description, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Ingredients section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text('Công thức (1 suất)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Sửa'),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => RecipeEditorDialog(
                          dishId: dish.id,
                          dishName: dish.name,
                          initialServings: servings,
                          initialIngredients: ingredients.map((i) => i.toMap()).toList(),
                        ),
                      );
                      _fetchRecipe(); // reload recipe after editing
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  : ingredients.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Chưa có công thức nào được tạo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: cs.outlineVariant),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ingredients.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
                                itemBuilder: (context, index) {
                                  final ing = ingredients[index];
                                  final qty = (ing.quantity / servings).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                                  return ListTile(
                                    dense: true,
                                    title: Text(ing.name),
                                    trailing: Text(
                                      '$qty ${ing.unit}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 100,
      height: 100,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.fastfood_rounded, color: cs.onSurfaceVariant, size: 40),
    );
  }
}
