import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/table_provider.dart';
import '../../models/table_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'ordering_screen.dart';
import '../../utils/logout_helper.dart';

/// Màn hình chọn bàn cho waiter – dùng table.name (thay table.number)
class TableSelectionScreen extends StatelessWidget {
  const TableSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Bàn'),
        leading: isAdmin
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),
      body: tableProvider.tables.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_bar_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12),
                  const Text('Chưa có bàn. Admin cần seed data trước.'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: tableProvider.tables.length,
                itemBuilder: (context, index) {
                  final table = tableProvider.tables[index];
                  final isAvailable = table.status == TableStatus.available;
                  final color = _statusColor(table.status, cs);

                  return InkWell(
                    onTap: isAvailable
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      OrderingScreen(table: table)),
                            )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: color.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_bar_rounded,
                              color: isAvailable ? color : cs.outlineVariant,
                              size: 32),
                          const SizedBox(height: 6),
                          // Dùng table.name (Bàn 1..20) thay vì table.number
                          Text(table.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  fontSize: 13)),
                          Text('${table.capacity} chỗ',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _statusColor(TableStatus status, ColorScheme cs) {
    return switch (status) {
      TableStatus.available => Colors.green,
      TableStatus.occupied => cs.error,
      TableStatus.reserved => Colors.orange,
    };
  }
}
