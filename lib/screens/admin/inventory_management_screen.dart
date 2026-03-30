import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../components/inventory_item_card.dart';
import '../../theme/admin_theme.dart';

/// Màn hình quản lý kho nguyên liệu – Haidilao Premium Dark
class InventoryManagementScreen extends StatelessWidget {
  const InventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _InventoryBody();
  }
}

class _InventoryBody extends StatefulWidget {
  const _InventoryBody();

  @override
  State<_InventoryBody> createState() => _InventoryBodyState();
}

class _InventoryBodyState extends State<_InventoryBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();

    final lowItems = inv.items.where((i) => inv.isLow(i)).toList();

    return Scaffold(
      backgroundColor: AdminColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Kho Nguyên Liệu'),
        backgroundColor: AdminColors.bgPrimary,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AdminColors.crimson,
          unselectedLabelColor: AdminColors.textSecondary,
          indicatorColor: AdminColors.crimson,
          dividerColor: AdminColors.borderDefault,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_rounded),
              text: 'Tất cả (${inv.items.length})',
            ),
            Tab(
              icon: Icon(Icons.warning_amber_rounded,
                  color: lowItems.isNotEmpty ? AdminColors.error : null),
              text: 'Sắp hết (${lowItems.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ItemList(
            items: inv.items,
            onImport: (item) => _showAdjustDialog(context, item, isImport: true),
            onExport: (item) => _showAdjustDialog(context, item, isImport: false),
            onDelete: (item) => _confirmDelete(context, item, inv),
            isLowBuilder: (item) => inv.isLow(item),
          ),
          _ItemList(
            items: lowItems,
            onImport: (item) => _showAdjustDialog(context, item, isImport: true),
            onExport: (item) => _showAdjustDialog(context, item, isImport: false),
            onDelete: (item) => _confirmDelete(context, item, inv),
            isLowBuilder: (item) => true,
            emptyLabel: 'Kho đủ hàng, không có mặt hàng sắp hết!',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AdminColors.crimson,
        foregroundColor: AdminColors.textPrimary,
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm nguyên liệu', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, InventoryModel item, InventoryProvider inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Text('Xác nhận xóa', style: AdminText.h1.copyWith(color: AdminColors.error)),
        content: Text('Chắc chắn xóa vĩnh viễn nguyên liệu "${item.name}" khỏi hệ thống?', style: const TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: AdminColors.textPrimary,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await inv.deleteItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa ${item.name}', style: const TextStyle(color: AdminColors.textPrimary)),
                    backgroundColor: AdminColors.bgElevated,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final unitCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Text('Thêm nguyên liệu', style: AdminText.h1),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: _inputDeco('Tên nguyên liệu', Icons.inventory_outlined),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: _inputDeco('Số lượng ban đầu', Icons.numbers),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: unitCtrl,
            style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: _inputDeco('Đơn vị (kg, lít, cái...)', Icons.straighten),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.crimson,
              foregroundColor: AdminColors.textPrimary,
            ),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final qty = DatabaseService.parseVnNum(qtyCtrl.text);
              final item = InventoryModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                quantity: qty,
                unit: unitCtrl.text.trim(),
                maxQuantity: 0,
              );
              await context.read<InventoryProvider>().addItem(item);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Thêm mới', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, InventoryModel item,
      {required bool isImport}) {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Row(
          children: [
            Icon(isImport ? Icons.download_rounded : Icons.upload_rounded, 
                color: isImport ? AdminColors.success : AdminColors.warning, size: 28),
            const SizedBox(width: 8),
            Text(isImport ? 'Nhập kho' : 'Xuất kho', style: AdminText.h1),
          ],
        ),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AdminColors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Tồn hiện tại: ${item.quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '')} ${item.unit}',
                          style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
            decoration: _inputDeco('Số lượng ${isImport ? "nhập" : "xuất"}', Icons.numbers),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            style: const TextStyle(color: AdminColors.textPrimary),
            decoration: _inputDeco('Ghi chú thay đổi', Icons.note_outlined),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isImport
                  ? AdminColors.success
                  : AdminColors.warning,
              foregroundColor: isImport ? Colors.white : Colors.black,
            ),
            onPressed: () async {
              final qty = DatabaseService.parseVnNum(qtyCtrl.text);
              if (qty <= 0) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số lượng phải lớn hơn 0')),
                  );
                }
                return;
              }
              
              try {
                final provider = context.read<InventoryProvider>();
                if (isImport) {
                  await provider.importStock(item, qty, noteCtrl.text);
                } else {
                  await provider.exportStock(item, qty, noteCtrl.text);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: Text(isImport ? 'Xác nhận Nhập' : 'Xác nhận Xuất', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
}

// ── Item list ─────────────────────────────────────────────────────────────────
class _ItemList extends StatelessWidget {
  final List<InventoryModel> items;
  final void Function(InventoryModel) onImport;
  final void Function(InventoryModel) onExport;
  final void Function(InventoryModel) onDelete;
  final bool Function(InventoryModel) isLowBuilder;
  final String emptyLabel;

  const _ItemList({
    required this.items,
    required this.onImport,
    required this.onExport,
    required this.onDelete,
    required this.isLowBuilder,
    this.emptyLabel = 'Chưa có nguyên liệu nào',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
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
              child: const Icon(Icons.inventory_2_rounded, size: 64, color: AdminColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(emptyLabel,
                style: const TextStyle(color: AdminColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return InventoryItemCard(
          item: item,
          isLow: isLowBuilder(item),
          onImport: () => onImport(item),
          onExport: () => onExport(item),
          onDelete: () => onDelete(item),
        );
      },
    );
  }
}
