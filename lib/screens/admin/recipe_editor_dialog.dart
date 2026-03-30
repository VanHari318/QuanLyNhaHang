import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../providers/inventory_provider.dart';
import '../../models/recipe_model.dart';
import '../../theme/admin_theme.dart';

class RecipeEditorDialog extends StatefulWidget {
  final String dishId;
  final String dishName;
  final int initialServings;
  final List<Map<String, dynamic>> initialIngredients;

  const RecipeEditorDialog({
    super.key,
    required this.dishId,
    required this.dishName,
    required this.initialServings,
    required this.initialIngredients,
  });

  @override
  State<RecipeEditorDialog> createState() => _RecipeEditorDialogState();
}

class _RecipeEditorDialogState extends State<RecipeEditorDialog> {
  final DatabaseService _db = DatabaseService();
  late List<Map<String, dynamic>> _ingredients;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Chuyển đổi công thức cũ (nếu có `servings` > 1) về 1 suất
    _ingredients = widget.initialIngredients.map((e) {
      final qty = (e['total_quantity'] as num) / widget.initialServings;
      return {
        'name': e['name'],
        'total_quantity': double.tryParse(qty.toStringAsFixed(2)) ?? qty,
        'unit': e['unit'],
      };
    }).toList();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({
        'name': '',
        'total_quantity': 0.0,
        'unit': 'g', // default unit
      });
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _save() async {
    // Luôn lưu với số suất là 1
    const servings = 1;
    
    // Validate
    for (var ing in _ingredients) {
      if ((ing['name'] as String).trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tên nguyên liệu không được để trống')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    
    final normalizedIngredients = _ingredients.map((ing) {
      return {
        'name': (ing['name'] as String).trim(),
        'total_quantity': double.tryParse(ing['total_quantity'].toString()) ?? 0.0,
        'unit': (ing['unit'] as String).trim(),
      };
    }).toList();

    await _db.saveDishRecipe(
      widget.dishId,
      DishRecipeModel(
        servings: servings,
        ingredients: normalizedIngredients.map((i) => RecipeIngredient.fromMap(i)).toList(),
      ),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryItems = context.read<InventoryProvider>().items;

    return AlertDialog(
      backgroundColor: AdminColors.bgCard(context),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AdminColors.borderDefault(context)),
      ),
      title: Text('Sửa công thức: ${widget.dishName}', style: AdminText.h1(context)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: AdminColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gõ và chọn tên nguyên liệu từ kho. Nếu là nguyên liệu mới hoàn toàn, hệ thống sẽ tự động thêm vào kho (khi lưu, số lượng kho = 0).',
                        style: TextStyle(fontSize: 13, color: AdminColors.textSecondary(context), height: 1.3),
                      ),
                    ),
                  ],
                ),
             ),
            const SizedBox(height: 16),
            Expanded(
              child: _ingredients.isEmpty
                  ? Center(child: Text('Chưa có nguyên liệu nào.', style: TextStyle(color: AdminColors.textMuted(context))))
                  : ListView.separated(
                      itemCount: _ingredients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildIngredientRow(index, inventoryItems);
                      },
                    ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AdminColors.bgElevated(context),
                foregroundColor: AdminColors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm nguyên liệu', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _addIngredient,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(color: AdminColors.textSecondary(context))),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AdminColors.crimson,
            foregroundColor: Colors.white,
          ),
          icon: _isSaving 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_isSaving ? 'Đang lưu...' : 'Lưu công thức', style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }

  Widget _buildIngredientRow(int index, List inventoryItems) {
    final ing = _ingredients[index];
    
    // Format quantity cleanly (drop .0)
    final rawQty = ing['total_quantity'];
    final num qty = rawQty is num ? rawQty : (double.tryParse(rawQty.toString()) ?? 0);
    final qtyStr = qty == qty.toInt() ? qty.toInt().toString() : qty.toString();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.bgElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.borderDefault(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
        Expanded(
          flex: 4,
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: ing['name']),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                 return const Iterable<String>.empty();
              }
              return inventoryItems
                  .map<String>((e) => e.name.toString())
                  .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              setState(() {
                _ingredients[index]['name'] = selection;
                try {
                  final matchedItem = inventoryItems.firstWhere((e) => e.name == selection);
                  _ingredients[index]['unit'] = matchedItem.unit;
                } catch (_) {}
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(color: AdminColors.textPrimary(context)),
                decoration: InputDecoration(
                  labelText: 'Tên nguyên liệu',
                  labelStyle: TextStyle(color: AdminColors.textSecondary(context)),
                  isDense: true,
                  hintText: 'Nhập hoặc chọn...',
                  hintStyle: TextStyle(color: AdminColors.textMuted(context)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderSide: BorderSide(color: AdminColors.borderMuted(context)), borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AdminColors.borderMuted(context)), borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AdminColors.crimson), borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) {
                  _ingredients[index]['name'] = val;
                },
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: ValueKey('qty-${index}-$qtyStr'),
            initialValue: qtyStr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AdminColors.textPrimary(context), fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Định lượng',
              labelStyle: TextStyle(color: AdminColors.textSecondary(context)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AdminColors.borderMuted(context)), borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AdminColors.borderMuted(context)), borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AdminColors.crimson), borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (val) {
              _ingredients[index]['total_quantity'] = val;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            key: ValueKey('unit-${index}-${ing['unit']}'),
            initialValue: ing['unit']?.toString() ?? '',
            style: TextStyle(color: AdminColors.textPrimary(context)),
            decoration: InputDecoration(
              labelText: 'Đơn vị',
              labelStyle: TextStyle(color: AdminColors.textSecondary(context)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderSide: BorderSide(color: AdminColors.borderMuted(context)), borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AdminColors.borderMuted(context)), borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AdminColors.crimson), borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (val) {
              _ingredients[index]['unit'] = val;
            },
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: AdminColors.error),
            onPressed: () => _removeIngredient(index),
            tooltip: 'Xóa',
          ),
        ),
      ],
    ),
  );
}
}
