import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../utils/logout_helper.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isAdmin = user?.role == UserRole.admin;
    final orderProvider = Provider.of<OrderProvider>(context);

    // Filter orders for the kitchen (pending and preparing)
    final activeOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.preparing)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Panel'),
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
      body: activeOrders.isEmpty 
        ? const Center(child: Text('No active orders'))
        : ListView.builder(
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final order = activeOrders[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Table ${order.tableNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      const Divider(),
                      ...order.items.map((item) => Text('${item.quantity}x ${item.foodItem.name}')),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (order.status == OrderStatus.pending)
                            ElevatedButton(
                              onPressed: () => orderProvider.updateStatus(order.id, OrderStatus.preparing),
                              child: const Text('Start Preparing'),
                            ),
                          if (order.status == OrderStatus.preparing)
                            ElevatedButton(
                              onPressed: () => orderProvider.updateStatus(order.id, OrderStatus.ready),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text('Mark as Ready'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color = Colors.grey;
    if (status == OrderStatus.pending) color = Colors.orange;
    if (status == OrderStatus.preparing) color = Colors.blue;
    
    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
    );
  }
}

