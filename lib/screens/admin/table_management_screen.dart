import 'package:flutter/material.dart';
import '../../models/table_model.dart';
import '../../services/database_service.dart';
import '../../theme/admin_theme.dart';

/// Màn hình quản lý bàn – Haidilao Premium Dark
class TableManagementScreen extends StatelessWidget {
  const TableManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Quản Lý Bàn'),
        backgroundColor: AdminColors.bgPrimary,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          const _LegendBar(),
          Expanded(
            child: StreamBuilder<List<TableModel>>(
              stream: db.getTables(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AdminColors.crimson));
                }
                final tables = snapshot.data!;
                if (tables.isEmpty) {
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
                          child: const Icon(Icons.table_bar_rounded, size: 64, color: AdminColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        const Text('Chưa có bàn nào', style: TextStyle(color: AdminColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        const Text('Dùng Seed Data ở trang Cấu hình để khởi tạo.', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75, // Ajusted for layout
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
      backgroundColor: AdminColors.bgCard,
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
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Text('Mã QR – ${table.name}', style: AdminText.h1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.borderDefault),
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
                        child: Center(child: CircularProgressIndicator(color: AdminColors.crimson)),
                      ),
                errorBuilder: (_, __, ___) => SizedBox(
                  width: 220,
                  height: 220,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Không tải được QR\n(cần kết nối Internet)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đưa mã QR này cho khách để gọi món nhe!',
              style: TextStyle(color: AdminColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AdminColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.borderDefault),
              ),
              child: SelectableText(
                qrUrl,
                style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.bgElevated,
                foregroundColor: AdminColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng bảng', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// ── Legend bar ────────────────────────────────────────────────────────────────
class _LegendBar extends StatelessWidget {
  const _LegendBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.borderDefault),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: TableStatus.values.map((s) {
          final color = _statusColor(s);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1),
                  ]
                ),
              ),
              const SizedBox(width: 8),
              Text(_statusLabel(s),
                  style: const TextStyle(color: AdminColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
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
    final color = _statusColor(table.status);

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: table.status == TableStatus.occupied 
            ? [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)] 
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft tint
          Positioned.fill(
            child: ColoredBox(color: color.withValues(alpha: 0.05)),
          ),
          Column(
            children: [
              // Main area – tap to change status
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_bar_rounded, color: color, size: 36),
                        const SizedBox(height: 8),
                        Text(table.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15, color: color)),
                        const SizedBox(height: 2),
                        Text('${table.capacity} chỗ',
                            style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(_statusLabel(table.status).toUpperCase(),
                              style: TextStyle(
                                  fontSize: 9,
                                  color: color,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // QR button – separate tap area
              InkWell(
                onTap: onShowQr,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: AdminColors.bgElevated,
                    border: Border(top: BorderSide(color: AdminColors.borderDefault)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_rounded, size: 14, color: AdminColors.textSecondary),
                      SizedBox(width: 6),
                      Text('XEM QR',
                          style: TextStyle(
                              fontSize: 11,
                              color: AdminColors.textSecondary,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(table.name, style: AdminText.h1),
                  const SizedBox(height: 4),
                  Text('Sức chứa: ${table.capacity} người',
                      style: const TextStyle(color: AdminColors.textSecondary)),
                ],
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AdminColors.bgElevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminColors.borderDefault),
                ),
                child: const Icon(Icons.table_restaurant_rounded, color: AdminColors.teal),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text('Cập nhật trạng thái mới:',
              style: TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...TableStatus.values.map((s) {
            final color = _statusColor(s);
            final isSelected = table.status == s;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : AdminColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : AdminColors.borderDefault),
              ),
              child: ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.circle, color: color, size: 14),
                ),
                title: Text(_statusLabel(s),
                    style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? color : AdminColors.textPrimary)),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: color) : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  await db.updateTableStatus(table.id, s);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Color _statusColor(TableStatus s) {
  return switch (s) {
    TableStatus.available => AdminColors.success,
    TableStatus.occupied => AdminColors.error,
    TableStatus.reserved => AdminColors.warning,
  };
}

String _statusLabel(TableStatus s) {
  return switch (s) {
    TableStatus.available => 'Bàn Trống',
    TableStatus.occupied => 'Đang Phục Vụ',
    TableStatus.reserved => 'Đã Đặt Trước',
  };
}
