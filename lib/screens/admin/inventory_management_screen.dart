import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../components/inventory_item_card.dart';

/// Màn hình quản lý kho nguyên liệu – MD3 enhanced
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
    final cs = Theme.of(context).colorScheme;

    final lowItems = inv.items.where((i) => inv.isLow(i)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Nguyên Liệu'),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_rounded),
              text: 'Tất cả (${inv.items.length})',
            ),
            Tab(
              icon: Icon(Icons.warning_amber_rounded,
                  color: lowItems.isNotEmpty ? cs.error : null),
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
            emptyLabel: '✅ Kho đủ hàng, không có mặt hàng sắp hết!',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm nguyên liệu'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, InventoryModel item, InventoryProvider inv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nguyên liệu "${item.name}" khỏi hệ thống? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await inv.deleteItem(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa ${item.name}')),
                );
              }
            },
            child: const Text('Xóa'),
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
        title: const Text('Thêm nguyên liệu'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Tên nguyên liệu',
                prefixIcon: Icon(Icons.inventory_outlined)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Số lượng ban đầu',
                prefixIcon: Icon(Icons.numbers)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: unitCtrl,
            decoration: const InputDecoration(
                labelText: 'Đơn vị (kg, lít, cái...)',
                prefixIcon: Icon(Icons.straighten)),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
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
            child: const Text('Thêm'),
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
        title: Text(isImport ? '📦 Nhập kho' : '📤 Xuất kho'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nguyên liệu: ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('Tồn kho: ${item.quantity} ${item.unit}'),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  'Số lượng ${isImport ? "nhập" : "xuất"}',
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.note_outlined)),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isImport
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
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
            child: Text(isImport ? 'Nhập kho' : 'Xuất kho'),
          ),
        ],
      ),
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
    this.emptyLabel = 'Kho trống',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded,
                size: 64, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
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
