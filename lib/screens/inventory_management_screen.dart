import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_model.dart';

/// Màn hình quản lý kho nguyên liệu – MD3
class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState
    extends State<InventoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kho Nguyên Liệu')),
      body: inv.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  Text('Kho trống',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: inv.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _InventoryTile(
                item: inv.items[i],
                onImport: () => _showAdjustDialog(context, inv.items[i],
                    isImport: true),
                onExport: () => _showAdjustDialog(context, inv.items[i],
                    isImport: false),
                onDelete: () => inv.deleteItem(inv.items[i].id),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm nguyên liệu'),
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
              final item = InventoryModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                quantity: double.tryParse(qtyCtrl.text) ?? 0,
                unit: unitCtrl.text.trim(),
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

  void _showAdjustDialog(
      BuildContext context, InventoryModel item,
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
          Text('Tồn kho hiện tại: ${item.quantity} ${item.unit}'),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số lượng ${isImport ? "nhập" : "xuất"}',
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
                labelText: 'Ghi chú', prefixIcon: Icon(Icons.note_outlined)),
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
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              if (qty <= 0) return;
              final provider = context.read<InventoryProvider>();
              if (isImport) {
                await provider.importStock(item, qty, noteCtrl.text);
              } else {
                await provider.exportStock(item, qty, noteCtrl.text);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isImport ? 'Nhập kho' : 'Xuất kho'),
          ),
        ],
      ),
    );
  }
}

// ── Inventory tile ────────────────────────────────────────────────────────────
class _InventoryTile extends StatelessWidget {
  final InventoryModel item;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _InventoryTile({
    required this.item,
    required this.onImport,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLow = item.quantity < 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: (isLow ? cs.errorContainer : cs.primaryContainer),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: isLow ? cs.onErrorContainer : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(children: [
                  Text(
                    '${item.quantity} ${item.unit}',
                    style: TextStyle(
                        color: isLow ? cs.error : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600),
                  ),
                  if (isLow) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Sắp hết',
                          style: TextStyle(
                              color: cs.onErrorContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.green),
            onPressed: onImport,
            tooltip: 'Nhập kho',
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded, color: cs.error),
            onPressed: onExport,
            tooltip: 'Xuất kho',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: cs.outlineVariant),
            onPressed: onDelete,
            tooltip: 'Xóa',
          ),
        ]),
      ),
    );
  }
}
