import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/menu_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/dish_model.dart';
import '../../models/category_model.dart';
import '../../models/inventory_model.dart';
import '../../models/recipe_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/database_service.dart';
import 'dish_detail_dialog.dart';

/// Màn hình quản lý món ăn – MD3
class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MenuManagementBody();
  }
}

class _MenuManagementBody extends StatefulWidget {
  const _MenuManagementBody();

  @override
  State<_MenuManagementBody> createState() => _MenuManagementBodyState();
}

class _MenuManagementBodyState extends State<_MenuManagementBody> {
  final _picker = ImagePicker();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final cs = Theme.of(context).colorScheme;
    final categories = [
      const CategoryModel(id: '', name: 'Tất cả'),
      ...CategoryModel.defaults,
    ];

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Tìm món ăn...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onChanged: menuProvider.setSearchQuery,
              )
            : const Text('Quản Lý Món Ăn'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            tooltip: 'Tìm kiếm',
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) menuProvider.setSearchQuery('');
            },
          ),
          IconButton(
            icon: Icon(
              menuProvider.isSortAsc == null
                  ? Icons.sort_rounded
                  : (menuProvider.isSortAsc!
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded),
            ),
            tooltip: 'Sắp xếp giá',
            onPressed: menuProvider.toggleSortByPrice,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _CategoryFilterBar(
            categories: categories,
            selected: menuProvider.selectedCategory,
            onSelected: menuProvider.setCategory,
          ),
        ),
      ),
      body: menuProvider.filteredItems.isEmpty
          ? _emptyState(cs)
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: menuProvider.filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final dish = menuProvider.filteredItems[index];
                return _DishTile(
                  dish: dish,
                  onEdit: () => _showDishDialog(context, dish: dish),
                  onDelete: () => _confirmDelete(context, dish),
                  onToggleBestSeller: (val) =>
                      menuProvider.toggleBestSeller(dish.id, val),
                  onToggleAvailable: (val) =>
                      menuProvider.toggleAvailability(dish.id, val),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDishDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm món'),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 72, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('Chưa có món ăn nào',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DishModel dish) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa món ăn'),
        content: Text('Bạn muốn xóa "${dish.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<MenuProvider>().deleteDish(dish.id);
      // Xóa công thức đi kèm
      await DatabaseService().deleteRecipe(dish.id);
    }
  }

  void _showDishDialog(BuildContext context, {DishModel? dish}) {
    showDialog(
      context: context,
      builder: (_) => _DishDialog(existingDish: dish, picker: _picker),
    );
  }
}

// ── Category filter bar ───────────────────────────────────────────────────────
class _CategoryFilterBar extends StatelessWidget {
  final List<CategoryModel> categories;
  final String selected;
  final void Function(String) onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static IconData _iconFor(String id) {
    const m = {
      '': Icons.grid_view_rounded,
      'appetizer': Icons.lunch_dining_rounded,
      'main': Icons.set_meal_rounded,
      'dessert': Icons.icecream_rounded,
      'drink': Icons.local_drink_rounded,
    };
    return m[id] ?? Icons.restaurant_rounded;
  }

  static Color _colorFor(String id) {
    const m = {
      '': Color(0xFF5C6BC0),
      'appetizer': Color(0xFFFF7043),
      'main': Color(0xFFD32F2F),
      'dessert': Color(0xFFAB47BC),
      'drink': Color(0xFF00897B),
    };
    return m[id] ?? const Color(0xFF757575);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat.id == selected;
          final color = _colorFor(cat.id);
          final icon = _iconFor(cat.id);

          return GestureDetector(
            onTap: () => onSelected(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.35),
                  width: isSelected ? 0 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: isSelected ? Colors.white : color),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Dish list tile ────────────────────────────────────────────────────────────
class _DishTile extends StatelessWidget {
  final DishModel dish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggleBestSeller;
  final void Function(bool) onToggleAvailable;

  const _DishTile({
    required this.dish,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleBestSeller,
    required this.onToggleAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inventory = context.watch<InventoryProvider>().items;
    final menu = context.watch<MenuProvider>();
    final isOutOfStock = menu.isOutOfStock(dish.id, inventory);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: isOutOfStock
                      ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: dish.imageUrl.isNotEmpty
                      ? Image.network(dish.imageUrl,
                          width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(cs))
                      : _placeholder(cs),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(dish.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isOutOfStock ? cs.error : null,
                                  )),
                        ),
                        if (dish.isBestSeller)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('⭐ Hot',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        if (isOutOfStock)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('⚠️ Hết hàng',
                                style: TextStyle(
                                    color: cs.onErrorContainer,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatPrice(dish.price)}đ  •  ${CategoryModel.labelOf(dish.category)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.edit_rounded, size: 20, color: cs.primary),
                      onPressed: onEdit,
                      tooltip: 'Sửa',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 20, color: cs.error),
                      onPressed: onDelete,
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 16,
                        color: dish.isBestSeller
                            ? Colors.amber
                            : cs.outlineVariant),
                    Switch(
                      value: dish.isBestSeller,
                      onChanged: onToggleBestSeller,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
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
      width: 64,
      height: 64,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.fastfood_rounded, color: cs.onSurfaceVariant, size: 30),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2);
  }
}

// ── Ingredient entry state holder ─────────────────────────────────────────────
class _IngredientEntry {
  String name;
  String unit;
  final TextEditingController quantityCtrl;

  _IngredientEntry({
    required this.name,
    required this.unit,
    required this.quantityCtrl,
  });
}

// ── Dish dialog (Add / Edit) ──────────────────────────────────────────────────
class _DishDialog extends StatefulWidget {
  final DishModel? existingDish;
  final ImagePicker picker;

  const _DishDialog({this.existingDish, required this.picker});

  @override
  State<_DishDialog> createState() => _DishDialogState();
}

class _DishDialogState extends State<_DishDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late String _selectedCat;
  late bool _isBestSeller;

  File? _localImage;
  XFile? _webImage;
  bool _uploading = false;
  bool _loadingRecipe = false;

  final List<_IngredientEntry> _ingredients = [];
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    final d = widget.existingDish;
    _nameCtrl = TextEditingController(text: d?.name);
    _descCtrl = TextEditingController(text: d?.description);
    _priceCtrl = TextEditingController(text: d?.price.toStringAsFixed(0));
    _selectedCat = d?.category ?? 'main';
    _isBestSeller = d?.isBestSeller ?? false;

    if (d != null) _loadRecipe(d.id);
  }

  Future<void> _loadRecipe(String dishId) async {
    setState(() => _loadingRecipe = true);
    final recipe = await _db.getDishRecipe(dishId);
    if (mounted && recipe != null) {
      setState(() {
        _ingredients.addAll(recipe.ingredients.map(
          (i) => _IngredientEntry(
            name: i.name,
            unit: i.unit,
            quantityCtrl: TextEditingController(text: i.quantity.toString()),
          ),
        ));
      });
    }
    if (mounted) setState(() => _loadingRecipe = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    for (final e in _ingredients) {
      e.quantityCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await widget.picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = img;
        } else {
          _localImage = File(img.path);
        }
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _uploading = true);

    String imageUrl = widget.existingDish?.imageUrl ?? '';
    if (_localImage != null || _webImage != null) {
      imageUrl = await CloudinaryService.uploadImage(
        imageFile: _localImage,
        webImage: _webImage,
        preset: CloudinaryService.foodPreset,
        folder: CloudinaryService.foodFolder,
      );
    }

    final dishId = widget.existingDish?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final dish = DishModel(
      id: dishId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: DatabaseService.parseVnNum(_priceCtrl.text),
      imageUrl: imageUrl,
      category: _selectedCat,
      isBestSeller: _isBestSeller,
      isAvailable: widget.existingDish?.isAvailable ?? true,
    );

    final provider = context.read<MenuProvider>();
    if (widget.existingDish == null) {
      await provider.addDish(dish);
    } else {
      await provider.updateDish(dish);
    }

    final recipeIngredients = _ingredients
        .where((e) =>
            e.name.isNotEmpty &&
            e.quantityCtrl.text.isNotEmpty &&
            DatabaseService.parseVnNum(e.quantityCtrl.text) > 0)
        .map((e) => RecipeIngredient(
              name: e.name,
              quantity: DatabaseService.parseVnNum(e.quantityCtrl.text),
              unit: e.unit,
            ))
        .toList();

    await _db.saveDishRecipe(
        dishId, DishRecipeModel(ingredients: recipeIngredients));

    await provider.refreshRecipes();

    if (mounted) Navigator.pop(context);
  }

  void _addIngredientRow(List<InventoryModel> inventory) {
    if (inventory.isEmpty) return;
    final first = inventory.first;
    setState(() {
      _ingredients.add(_IngredientEntry(
        name: first.name,
        unit: first.unit,
        quantityCtrl: TextEditingController(text: ''),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existingDish != null;
    final inventory = context.watch<InventoryProvider>().items;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth > 600) ? 500.0 : (screenWidth - 48);

    return AlertDialog(
      title: Text(isEdit ? 'Sửa món ăn' : 'Thêm món mới'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(cs),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Tên món *', prefixIcon: Icon(Icons.restaurant)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Mô tả', prefixIcon: Icon(Icons.description_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Giá (VNĐ) *', prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCat,
                decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    prefixIcon: Icon(Icons.category_outlined)),
                items: CategoryModel.defaults
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCat = v!),
              ),
              const SizedBox(height: 6),
              SwitchListTile.adaptive(
                title: const Text('Best Seller ⭐'),
                value: _isBestSeller,
                onChanged: (v) => setState(() => _isBestSeller = v),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.science_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Công thức (1 suất)',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: cs.primary),
                  ),
                  const Spacer(),
                  if (_loadingRecipe)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Thiết lập nguyên liệu cần dùng để làm 1 suất món này. Kho sẽ tự trừ khi thanh toán.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (inventory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Chưa có nguyên liệu nào trong kho. Vào mục Kho để thêm trước.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Expanded(
                          flex: 3,
                          child: Text('Nguyên liệu',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600))),
                      const SizedBox(width: 6),
                      const SizedBox(
                          width: 70,
                          child: Text('Số lượng',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center)),
                      const SizedBox(width: 4),
                      const SizedBox(
                          width: 32,
                          child: Text('ĐV',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center)),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                ..._ingredients.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ing = entry.value;
                  return _IngredientRow(
                    entry: ing,
                    inventory: inventory,
                    onRemove: () => setState(() => _ingredients.removeAt(idx)),
                    onInventoryChanged: (inv) => setState(() {
                      _ingredients[idx] = _IngredientEntry(
                        name: inv.name,
                        unit: inv.unit,
                        quantityCtrl: ing.quantityCtrl,
                      );
                    }),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _addIngredientRow(inventory),
                  icon:
                      const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Thêm nguyên liệu'),
                  style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 4)),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        _uploading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : FilledButton(
                onPressed: _save,
                child: Text(isEdit ? 'Lưu' : 'Thêm'),
              ),
      ],
    );
  }

  Widget _buildImagePreview(ColorScheme cs) {
    if (_localImage != null) {
      return Image.file(_localImage!, fit: BoxFit.cover);
    }
    if (_webImage != null) {
      return Image.network(_webImage!.path, fit: BoxFit.cover);
    }
    if (widget.existingDish?.imageUrl.isNotEmpty == true) {
      return Image.network(widget.existingDish!.imageUrl,
          fit: BoxFit.cover);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 36, color: cs.onSurfaceVariant),
        const SizedBox(height: 6),
        Text('Chọn ảnh', style: TextStyle(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ── Ingredient row widget ─────────────────────────────────────────────────────
class _IngredientRow extends StatelessWidget {
  final _IngredientEntry entry;
  final List<InventoryModel> inventory;
  final VoidCallback onRemove;
  final void Function(InventoryModel) onInventoryChanged;

  const _IngredientRow({
    required this.entry,
    required this.inventory,
    required this.onRemove,
    required this.onInventoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentItem = inventory.firstWhere(
      (i) => i.name == entry.name,
      orElse: () => inventory.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dropdown nguyên liệu
          Expanded(
            flex: 3, // Giảm từ 4 xuống 3 để dành chỗ cho số lượng
            child: DropdownButtonFormField<InventoryModel>(
              value: currentItem,
              isDense: true,
              isExpanded: true, // Cho phép text co lại nếu quá dài
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: inventory.map((inv) => DropdownMenuItem(
                value: inv,
                child: Text(inv.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (inv) {
                if (inv != null) onInventoryChanged(inv);
              },
            ),
          ),
          const SizedBox(width: 6),
          // Số lượng
          SizedBox(
            width: 70, // Dùng chiều rộng cố định nhỏ cho số lượng
            child: TextField(
              controller: entry.quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: '0',
                fillColor: cs.surface,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Đơn vị
          SizedBox(
            width: 32,
            child: Text(entry.unit,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          // Nút xóa dòng
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded, size: 18, color: cs.error),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}
