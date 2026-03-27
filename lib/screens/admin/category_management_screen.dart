import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/database_service.dart';

/// Màn hình quản lý danh mục – MD3
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
      appBar: AppBar(title: const Text('Quản Lý Danh Mục')),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _db.getCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cats = snapshot.data!;
          if (cats.isEmpty) {
            return _emptyState(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _CategoryTile(
              category: cats[i],
              onEdit: () => _showDialog(cats[i]),
              onDelete: () => _confirmDelete(cats[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm danh mục'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.category_rounded, size: 64, color: cs.outlineVariant),
        const SizedBox(height: 12),
        Text('Chưa có danh mục', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Tạo 4 danh mục mặc định'),
          onPressed: _seedDefaults,
        ),
      ]),
    );
  }

  Future<void> _seedDefaults() async {
    for (final c in CategoryModel.defaults) await _db.saveCategory(c);
  }

  Future<void> _confirmDelete(CategoryModel cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Xóa danh mục "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
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
        title: Text(cat == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: idCtrl,
            enabled: cat == null,
            decoration: const InputDecoration(
              labelText: 'ID (vd: appetizer)',
              prefixIcon: Icon(Icons.label_outline)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              prefixIcon: Icon(Icons.title)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              if (idCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              await _db.saveCategory(CategoryModel(
                  id: idCtrl.text.trim(), name: nameCtrl.text.trim()));
              if (mounted) Navigator.pop(context);
            },
            child: Text(cat == null ? 'Thêm' : 'Lưu'),
          ),
        ],
      ),
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.category_rounded, color: cs.onPrimaryContainer),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('ID: ${category.id}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.edit_rounded, color: cs.primary), onPressed: onEdit),
            IconButton(icon: Icon(Icons.delete_outline_rounded, color: cs.error), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
