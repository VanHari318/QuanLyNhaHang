import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/table_provider.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../models/user_model.dart';
import '../utils/logout_helper.dart';

class CashierScreen extends StatelessWidget {
  const CashierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final orderProvider = Provider.of<OrderProvider>(context);
    final tableProvider = Provider.of<TableProvider>(context);

    // Filter orders for the cashier (ready for payment)
    final readyOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.ready)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashier Panel'),
        leading: isAdmin ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),
      body: readyOrders.isEmpty 
        ? const Center(child: Text('No orders ready for checkout'))
        : ListView.builder(
            itemCount: readyOrders.length,
            itemBuilder: (context, index) {
              final order = readyOrders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Table ${order.tableNumber}'),
                  subtitle: Text('Total: ${order.totalPrice.toStringAsFixed(0)}đ'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // 1. Mark order as completed
                      await orderProvider.updateStatus(order.id, OrderStatus.completed);
                      
                      // 2. Mark table as available (find the table ID first)
                      final table = tableProvider.tables.firstWhere((t) => t.number == order.tableNumber);
                      await tableProvider.updateStatus(table.id, TableStatus.available);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment completed. Table is now free.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: const Text('Checkout'),
                  ),
                  onTap: () => _showOrderDetails(context, order),
                ),
              );
            },
          ),
    );
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - Table ${order.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...order.items.map((item) => Text('${item.quantity}x ${item.foodItem.name} - ${item.foodItem.price * item.quantity}đ')),
            const Divider(),
            Text('Total: ${order.totalPrice.toStringAsFixed(0)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

