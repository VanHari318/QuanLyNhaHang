import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';
import '../../theme/admin_theme.dart';

/// Màn hình quản lý danh mục – Haidilao Premium Dark
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      appBar: AppBar(
        title: const Text('Quản Lý Danh Mục'),
        backgroundColor: AdminColors.bgPrimary(context),
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _db.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: AdminColors.crimson));
          }
          final cats = snapshot.data!;
          if (cats.isEmpty) {
            return _emptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CategoryTile(
              category: cats[i],
              onEdit: () => _showDialog(cats[i]),
              onDelete: () => _confirmDelete(cats[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminColors.crimson,
        foregroundColor: Colors.white,
        onPressed: () => _showDialog(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminColors.bgElevated(context),
              shape: BoxShape.circle,
              border: Border.all(color: AdminColors.borderDefault(context)),
            ),
            child: Icon(Icons.category_rounded, size: 64, color: AdminColors.textMuted(context)),
          ),
          const SizedBox(height: 24),
          Text('Chưa có danh mục nào', style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Tạo 4 danh mục mặc định', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _seedDefaults,
          ),
        ]
      ),
    );
  }

  Future<void> _seedDefaults() async {
    for (final c in CategoryModel.defaults) await _db.saveCategory(c);
  }

  Future<void> _confirmDelete(CategoryModel cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.bgCard(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AdminColors.borderDefault(context)),
        ),
        title: Text('Xóa danh mục', style: AdminText.h1(context)),
        content: Text('Xóa vĩnh viễn danh mục "${cat.name}"?', style: TextStyle(color: AdminColors.textSecondary(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy', style: TextStyle(color: AdminColors.textSecondary(context)))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AdminColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) await _db.deleteCategory(cat.id);
  }

  void _showDialog(CategoryModel? cat) {
    final idCtrl = TextEditingController(text: cat?.id);
    final nameCtrl = TextEditingController(text: cat?.name);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.bgCard(context),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AdminColors.borderDefault(context)),
        ),
        title: Text(cat == null ? 'Thêm danh mục' : 'Sửa danh mục', style: AdminText.h1(context)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: idCtrl,
            enabled: cat == null,
            style: TextStyle(color: AdminColors.textPrimary(context), fontWeight: FontWeight.bold),
            decoration: _inputDeco('Mã ID (vd: appetizer)', Icons.label_outline),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            style: TextStyle(color: AdminColors.textPrimary(context), fontWeight: FontWeight.bold),
            decoration: _inputDeco('Tên hiển thị', Icons.title),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: AdminColors.textSecondary(context)))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.crimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              await _db.saveCategory(CategoryModel(
                  id: idCtrl.text.trim(), name: nameCtrl.text.trim()));
              if (mounted) Navigator.pop(context);
            },
            child: Text(cat == null ? 'Thêm' : 'Lưu', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AdminColors.textSecondary(context)),
      prefixIcon: Icon(icon, color: AdminColors.textSecondary(context)),
      filled: true,
      fillColor: AdminColors.bgElevated(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.borderDefault(context))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.borderDefault(context))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.crimson)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.borderMuted(context))),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AdminColors.bgCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.borderDefault(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AdminColors.crimson.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.category_rounded, color: AdminColors.crimsonBright, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(category.name, style: AdminText.h3(context)),
                   const SizedBox(height: 2),
                   Text('ID: ${category.id}', style: TextStyle(color: AdminColors.textSecondary(context), fontSize: 13)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AdminColors.teal, size: 20),
                  onPressed: onEdit,
                  style: IconButton.styleFrom(backgroundColor: AdminColors.bgElevated(context)),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.error, size: 20),
                  onPressed: onDelete,
                  style: IconButton.styleFrom(backgroundColor: AdminColors.error.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
