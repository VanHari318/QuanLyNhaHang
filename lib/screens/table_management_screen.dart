import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../services/database_service.dart';

/// Màn hình quản lý bàn – MD3 grid view
class TableManagementScreen extends StatelessWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Bàn')),
      body: Column(
        children: [
          _LegendBar(),
          Expanded(
            child: StreamBuilder<List<TableModel>>(
              stream: db.getTables(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tables = snapshot.data!;
                if (tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_bar_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        const Text('Chưa có bàn. Dùng Seed Data để khởi tạo.'),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (ctx, i) => _TableCard(
                    table: tables[i],
                    onTap: () => _showStatusDialog(ctx, db, tables[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, DatabaseService db, TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _TableStatusSheet(db: db, table: table),
    );
  }
}

// ── Legend bar ────────────────────────────────────────────────────────────────
class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: TableStatus.values.map((s) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: _statusColor(s, Theme.of(context).colorScheme),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(_statusLabel(s),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Table card ────────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(table.status, cs);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_bar_rounded, color: color, size: 28),
            const SizedBox(height: 6),
            Text(table.name,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text('${table.capacity} chỗ',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_statusLabel(table.status),
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status bottom sheet ───────────────────────────────────────────────────────
class _TableStatusSheet extends StatelessWidget {
  final DatabaseService db;
  final TableModel table;

  const _TableStatusSheet({required this.db, required this.table});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(table.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
          Text('Sức chứa: ${table.capacity} người',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          Text('Đổi trạng thái:',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ...TableStatus.values.map((s) {
            final color = _statusColor(s, cs);
            return ListTile(
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.table_bar_rounded, color: color, size: 20),
              ),
              title: Text(_statusLabel(s),
                  style: TextStyle(fontWeight: FontWeight.w600, color: color)),
              selected: table.status == s,
              selectedTileColor: color.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onTap: () async {
                await db.updateTableStatus(table.id, s);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Color _statusColor(TableStatus s, ColorScheme cs) {
  return switch (s) {
    TableStatus.available => Colors.green,
    TableStatus.occupied => cs.error,
    TableStatus.reserved => Colors.orange,
  };
}

String _statusLabel(TableStatus s) {
  return switch (s) {
    TableStatus.available => 'Trống',
    TableStatus.occupied => 'Đang dùng',
    TableStatus.reserved => 'Đặt trước',
  };
}
