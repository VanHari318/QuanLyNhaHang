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
import '../../theme/admin_theme.dart';

/// Màn hình quản lý món ăn – Haidilao Premium Dark
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
    final categories = [
      const CategoryModel(id: '', name: 'Tất cả'),
      ...CategoryModel.defaults,
    ];

    return Scaffold(
      backgroundColor: AdminColors.bgPrimary,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: AdminColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tìm món ăn...',
                  hintStyle: const TextStyle(color: AdminColors.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: menuProvider.setSearchQuery,
              )
            : const Text('Quản Lý Món Ăn'),
        backgroundColor: AdminColors.bgPrimary,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AdminColors.textSecondary,
            ),
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
              color: AdminColors.textSecondary,
            ),
            tooltip: 'Sắp xếp giá',
            onPressed: menuProvider.toggleSortByPrice,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _CategoryFilterBar(
            categories: categories,
            selected: menuProvider.selectedCategory,
            onSelected: menuProvider.setCategory,
          ),
        ),
      ),
      body: menuProvider.filteredItems.isEmpty
          ? _emptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: menuProvider.filteredItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        backgroundColor: AdminColors.crimson,
        foregroundColor: AdminColors.textPrimary,
        onPressed: () => _showDishDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm món', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminColors.bgElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AdminColors.borderDefault),
            ),
            child: const Icon(Icons.restaurant_menu_rounded, size: 64, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 24),
          const Text('Chưa có món ăn nào',
              style: TextStyle(color: AdminColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DishModel dish) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Text('Xóa món ăn', style: AdminText.h1),
        content: Text('Bạn muốn xóa vĩnh viễn món "${dish.name}"?', 
            style: const TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.error,
                  foregroundColor: AdminColors.textPrimary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold))),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.bgPrimary,
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat.id == selected;
          final icon = _iconFor(cat.id);

          return GestureDetector(
            onTap: () => onSelected(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AdminColors.crimson : AdminColors.bgElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AdminColors.crimsonBright : AdminColors.borderDefault,
                  width: 1,
                ),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AdminColors.crimson.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
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
    final inventory = context.watch<InventoryProvider>().items;
    final menu = context.watch<MenuProvider>();
    final isOutOfStock = menu.isOutOfStock(dish.id, inventory);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AdminColors.borderDefault),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AdminColors.bgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.borderDefault),
              ),
              clipBehavior: Clip.antiAlias,
              child: ColorFiltered(
                colorFilter: isOutOfStock
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: dish.imageUrl.isNotEmpty
                    ? Image.network(dish.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 16),
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
                            style: AdminText.h2.copyWith(
                              color: isOutOfStock ? AdminColors.error : AdminColors.textPrimary,
                            )),
                      ),
                      if (dish.isBestSeller)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AdminColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: const Text('⭐ Hot',
                              style: TextStyle(
                                  color: AdminColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (isOutOfStock)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AdminColors.error.withValues(alpha: 0.3)),
                          ),
                          child: const Text('⚠️ Hết hàng',
                              style: TextStyle(
                                  color: AdminColors.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatPrice(dish.price)}đ',
                    style: AdminText.h3.copyWith(color: AdminColors.gold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CategoryModel.labelOf(dish.category),
                    style: AdminText.caption,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20, color: AdminColors.teal),
                      onPressed: onEdit,
                      tooltip: 'Sửa',
                      style: IconButton.styleFrom(
                        backgroundColor: AdminColors.bgElevated,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AdminColors.error),
                      onPressed: onDelete,
                      tooltip: 'Xóa',
                      style: IconButton.styleFrom(
                        backgroundColor: AdminColors.error.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Top Seller', style: TextStyle(color: AdminColors.textSecondary, fontSize: 11)),
                    const SizedBox(width: 4),
                    Switch(
                      value: dish.isBestSeller,
                      onChanged: onToggleBestSeller,
                      activeColor: AdminColors.gold,
                      activeTrackColor: AdminColors.gold.withValues(alpha: 0.3),
                      inactiveThumbColor: AdminColors.textMuted,
                      inactiveTrackColor: AdminColors.bgElevated,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(child: Icon(Icons.fastfood_rounded, color: AdminColors.textMuted, size: 28));
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
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
    final isEdit = widget.existingDish != null;
    final inventory = context.watch<InventoryProvider>().items;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth > 600) ? 500.0 : (screenWidth - 48);

    return AlertDialog(
      backgroundColor: AdminColors.bgCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AdminColors.borderDefault),
      ),
      title: Text(isEdit ? 'Sửa món ăn' : 'Thêm món mới', style: AdminText.h1),
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
                  height: 140,
                  decoration: BoxDecoration(
                    color: AdminColors.bgElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.borderDefault),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
                decoration: _inputDeco('Tên món *', Icons.restaurant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(color: AdminColors.textPrimary),
                decoration: _inputDeco('Mô tả', Icons.description_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AdminColors.gold, fontWeight: FontWeight.bold),
                decoration: _inputDeco('Giá (VNĐ) *', Icons.attach_money),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCat,
                dropdownColor: AdminColors.bgCard,
                style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
                decoration: _inputDeco('Danh mục', Icons.category_outlined),
                items: CategoryModel.defaults
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCat = v!),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AdminColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminColors.borderDefault),
                ),
                child: SwitchListTile.adaptive(
                  title: const Text('Best Seller ⭐', style: TextStyle(color: AdminColors.gold, fontWeight: FontWeight.bold)),
                  value: _isBestSeller,
                  onChanged: (v) => setState(() => _isBestSeller = v),
                  activeColor: AdminColors.gold,
                  activeTrackColor: AdminColors.gold.withValues(alpha: 0.3),
                  inactiveThumbColor: AdminColors.textMuted,
                  inactiveTrackColor: AdminColors.bgPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Divider(height: 32, color: AdminColors.borderMuted),
              Row(
                children: [
                  const Icon(Icons.science_outlined, size: 18, color: AdminColors.teal),
                  const SizedBox(width: 8),
                  const Text(
                    'Công thức (1 suất)',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AdminColors.teal),
                  ),
                  const Spacer(),
                  if (_loadingRecipe)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.teal)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Thiết lập nguyên liệu cần dùng để làm 1 suất món này. Kho sẽ tự trừ khi thanh toán.',
                style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
              ),
              const SizedBox(height: 12),
              if (inventory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.borderDefault),
                  ),
                  child: const Text(
                    'Chưa có nguyên liệu nào trong kho. Vào mục Kho để thêm trước.',
                    style: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
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
                                  color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 6),
                      const SizedBox(
                          width: 70,
                          child: Text('Định lượng',
                              style: TextStyle(
                                  color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center)),
                      const SizedBox(width: 4),
                      const SizedBox(
                          width: 32,
                          child: Text('ĐV',
                              style: TextStyle(
                                  color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
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
                  label: const Text('Thêm nguyên liệu', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: AdminColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
        _uploading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.crimson)))
            : FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.crimson,
                  foregroundColor: AdminColors.textPrimary,
                ),
                onPressed: _save,
                child: Text(isEdit ? 'Lưu cập nhật' : 'Thêm món', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AdminColors.textSecondary),
      prefixIcon: Icon(icon, color: AdminColors.textSecondary),
      filled: true,
      fillColor: AdminColors.bgElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.borderDefault)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.borderDefault)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.crimson)),
    );
  }

  Widget _buildImagePreview() {
    if (_localImage != null) {
      return Image.file(_localImage!, fit: BoxFit.cover, width: double.infinity);
    }
    if (_webImage != null) {
      return Image.network(_webImage!.path, fit: BoxFit.cover, width: double.infinity);
    }
    if (widget.existingDish?.imageUrl.isNotEmpty == true) {
      return Image.network(widget.existingDish!.imageUrl,
          fit: BoxFit.cover, width: double.infinity);
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 36, color: AdminColors.textMuted),
        SizedBox(height: 6),
        Text('Tải ảnh lên', style: TextStyle(color: AdminColors.textMuted, fontWeight: FontWeight.bold)),
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
            flex: 3,
            child: DropdownButtonFormField<InventoryModel>(
              value: currentItem,
              isDense: true,
              isExpanded: true,
              dropdownColor: AdminColors.bgCard,
              style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.borderDefault)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.borderDefault)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.teal)),
                filled: true,
                fillColor: AdminColors.bgElevated,
              ),
              items: inventory.map((inv) => DropdownMenuItem(
                value: inv,
                child: Text(inv.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (inv) {
                if (inv != null) onInventoryChanged(inv);
              },
            ),
          ),
          const SizedBox(width: 6),
          // Số lượng
          SizedBox(
            width: 70, 
            child: TextField(
              controller: entry.quantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.borderDefault)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.borderDefault)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.teal)),
                hintText: '0',
                hintStyle: const TextStyle(color: AdminColors.textMuted),
                fillColor: AdminColors.bgElevated,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Đơn vị
          SizedBox(
            width: 32,
            child: Text(entry.unit,
              style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // Nút xóa dòng
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AdminColors.error),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
