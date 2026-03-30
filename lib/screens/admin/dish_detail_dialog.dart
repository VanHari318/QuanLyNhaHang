import 'package:flutter/material.dart';
import '../../models/dish_model.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../models/recipe_model.dart';
import '../../theme/admin_theme.dart';
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
    final dish = widget.dish;
    final servings = _recipe?.servings ?? 1;
    final ingredients = _recipe?.ingredients ?? [];

    return AlertDialog(
      backgroundColor: AdminColors.bgCard(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AdminColors.borderDefault(context)),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Chi tiết món ăn', style: AdminText.h1(context)),
          IconButton(
            icon: Icon(Icons.close_rounded, color: AdminColors.textSecondary(context)),
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AdminColors.bgElevated(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdminColors.borderDefault(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: dish.imageUrl.isNotEmpty
                        ? Image.network(
                            dish.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name,
                          style: AdminText.h2(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_formatPrice(dish.price)} VNĐ',
                          style: AdminText.h3(context).copyWith(
                            color: Theme.of(context).brightness == Brightness.dark ? AdminColors.gold : AdminColors.crimsonDeep,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AdminColors.crimson.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AdminColors.crimson.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            CategoryModel.labelOf(dish.category),
                            style: const TextStyle(color: AdminColors.crimsonBright, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (dish.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold, color: AdminColors.textPrimary(context))),
                const SizedBox(height: 6),
                Text(dish.description, style: TextStyle(color: AdminColors.textSecondary(context), height: 1.4)),
              ],
              
              const SizedBox(height: 24),
              Divider(color: AdminColors.borderMuted(context)),
              const SizedBox(height: 16),
              
              // Ingredients section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Công thức (1 suất)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AdminColors.textPrimary(context))),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark ? AdminColors.gold : AdminColors.crimson,
                    ),
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
                  ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AdminColors.crimson)))
                  : ingredients.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AdminColors.bgElevated(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AdminColors.borderDefault(context)),
                          ),
                          child: Text(
                            'Chưa có công thức nào được tạo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AdminColors.textMuted(context)),
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AdminColors.borderMuted(context)),
                            borderRadius: BorderRadius.circular(12),
                            color: AdminColors.bgPrimary(context),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ingredients.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: AdminColors.borderMuted(context)),
                            itemBuilder: (context, index) {
                              final ing = ingredients[index];
                              final qty = (ing.quantity / servings).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
                              return ListTile(
                                dense: true,
                                title: Text(ing.name, style: TextStyle(color: AdminColors.textPrimary(context))),
                                trailing: Text(
                                  '$qty ${ing.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.teal),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(Icons.fastfood_rounded, color: AdminColors.textMuted(context), size: 40),
    );
  }
}
