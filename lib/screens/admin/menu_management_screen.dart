import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../providers/menu_provider.dart';
import '../../models/dish_model.dart';
import '../../models/category_model.dart';
import '../../services/cloudinary_service.dart';
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
                  : (menuProvider.isSortAsc! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
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

  // Icon & màu cho từng danh mục
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
      '': Color(0xFF5C6BC0),          // Indigo – "Tất cả"
      'appetizer': Color(0xFFFF7043), // Deep orange – Khai vị
      'main': Color(0xFFD32F2F),      // Red – Món chính
      'dessert': Color(0xFFAB47BC),   // Purple – Tráng miệng
      'drink': Color(0xFF00897B),     // Teal – Đồ uống
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
                color: isSelected ? color : color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.35),
                  width: isSelected ? 0 : 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 18,
                      color: isSelected ? Colors.white : color),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => DishDetailDialog(dish: dish),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: dish.imageUrl.isNotEmpty
                  ? Image.network(dish.imageUrl,
                      width: 64, height: 64, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(cs))
                  : _placeholder(cs),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(dish.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600)),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatPrice(dish.price)}đ  •  ${CategoryModel.labelOf(dish.category)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded,
                          size: 20, color: cs.primary),
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
      width: 64, height: 64,
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.fastfood_rounded,
          color: cs.onSurfaceVariant, size: 30),
    );
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

  @override
  void initState() {
    super.initState();
    final d = widget.existingDish;
    _nameCtrl = TextEditingController(text: d?.name);
    _descCtrl = TextEditingController(text: d?.description);
    _priceCtrl = TextEditingController(text: d?.price.toStringAsFixed(0));
    _selectedCat = d?.category ?? 'main';
    _isBestSeller = d?.isBestSeller ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await widget.picker.pickImage(source: ImageSource.gallery);
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

    final dish = DishModel(
      id: widget.existingDish?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
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

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existingDish != null;

    return AlertDialog(
      title: Text(isEdit ? 'Sửa món ăn' : 'Thêm món mới'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
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
                  labelText: 'Danh mục', prefixIcon: Icon(Icons.category_outlined)),
              items: CategoryModel.defaults
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
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
          ],
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
                    width: 24, height: 24,
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
      return Image.network(widget.existingDish!.imageUrl, fit: BoxFit.cover);
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
