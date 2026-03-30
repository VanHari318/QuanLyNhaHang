import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/table_provider.dart';
import '../../models/table_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'ordering_screen.dart';
import '../active_table_dialog.dart';
import '../../utils/logout_helper.dart';

/// Màn hình chọn bàn cho waiter – dùng table.name (thay table.number)
class TableSelectionScreen extends StatelessWidget {
  const TableSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tableProvider = Provider.of<TableProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
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
                  final isOccupied = table.status == TableStatus.occupied;
                  final color = _statusColor(table.status, cs);

                  // Find active order for this table
                  OrderModel? activeOrder;
                  if (isOccupied) {
                    // Try finding a "live" order first
                    activeOrder = orderProvider.orders.where((o) =>
                        o.tableId == table.id &&
                        o.status != OrderStatus.completed &&
                        o.status != OrderStatus.cancelled).firstOrNull;
                    
                    // If no live order, get the most recent one for this table to allow "Clear Table"
                    if (activeOrder == null) {
                      final tableOrders = orderProvider.orders
                          .where((o) => o.tableId == table.id)
                          .toList();
                      if (tableOrders.isNotEmpty) {
                        tableOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        activeOrder = tableOrders.first;
                      }
                    }
                  }
                  
                  final hasReadyItems = activeOrder?.status == OrderStatus.ready;
                  final isCleaningNeeded = isOccupied && 
                      (activeOrder?.status == OrderStatus.completed || activeOrder?.status == OrderStatus.cancelled);

                  return InkWell(
                    onTap: () {
                      if (isAvailable) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderingScreen(table: table)),
                        );
                      } else if (isOccupied && activeOrder != null) {
                        showActiveTableDialog(context, table, activeOrder);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isCleaningNeeded 
                            ? Colors.orange.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isCleaningNeeded 
                                ? Colors.orange.withValues(alpha: 0.6)
                                : color.withValues(alpha: 0.4), 
                            width: isCleaningNeeded ? 2 : 1.5),
                        boxShadow: isCleaningNeeded ? [
                          BoxShadow(color: Colors.orange.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)
                        ] : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isCleaningNeeded ? Icons.cleaning_services_rounded : Icons.table_bar_rounded,
                                color: isCleaningNeeded ? Colors.orange : (isAvailable || isOccupied ? color : cs.outlineVariant),
                                size: 30,
                              ),
                              const SizedBox(height: 6),
                              Text(table.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isCleaningNeeded ? Colors.orange : color,
                                      fontSize: 13)),
                              Text(isCleaningNeeded ? 'Chờ dọn dẹp' : '${table.capacity} chỗ',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isCleaningNeeded ? FontWeight.bold : FontWeight.normal,
                                      color: isCleaningNeeded ? Colors.orange.withValues(alpha: 0.8) : cs.onSurfaceVariant)),
                            ],
                          ),
                          if (hasReadyItems)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _PulsingNotification(),
                            ),
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

class _PulsingNotification extends StatefulWidget {
  @override
  State<_PulsingNotification> createState() => _PulsingNotificationState();
}

class _PulsingNotificationState extends State<_PulsingNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
        child: const Icon(Icons.notifications_active_rounded, size: 12, color: Colors.white),
      ),
    );
  }
}
