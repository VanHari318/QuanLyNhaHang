import 'package:flutter/material.dart';
import '../../models/table_model.dart';
import '../../services/database_service.dart';

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
                    childAspectRatio: 0.65,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (ctx, i) => _TableCard(
                    table: tables[i],
                    onTap: () => _showStatusDialog(ctx, db, tables[i]),
                    onShowQr: () => _showQrDialog(ctx, tables[i]),
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

  void _showQrDialog(BuildContext context, TableModel table) {
    // Luôn dùng URL deploy Firebase để mã QR hoạt động với bất kỳ ai (dù đang test trên LAN hay dùng thật)
    const baseUrl = 'https://quan-ly-nha-hang-20f37.web.app';
    final qrUrl = '$baseUrl/?tableId=${table.id}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mã QR – ${table.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(qrUrl)}',
                width: 220,
                height: 220,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => SizedBox(
                  width: 220,
                  height: 220,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_rounded, size: 60, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('Không tải được QR\n(cần kết nối Internet)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Khách quét mã để gọi món',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13),
            ),
            const SizedBox(height: 6),
            SelectableText(
              qrUrl,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
      ),
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
  final VoidCallback onShowQr;

  const _TableCard({required this.table, required this.onTap, required this.onShowQr});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(table.status, cs);

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          // Main area – tap to change status
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_bar_rounded, color: color, size: 32),
                    const SizedBox(height: 6),
                    Text(table.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13, color: color)),
                    const SizedBox(height: 2),
                    Text('${table.capacity} chỗ',
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_statusLabel(table.status),
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // QR button – separate tap area
          InkWell(
            onTap: onShowQr,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_rounded, size: 14, color: cs.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text('Xem QR',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
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
