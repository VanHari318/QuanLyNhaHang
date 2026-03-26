import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'waiter_screen.dart';
import 'kitchen_screen.dart';
import 'cashier_screen.dart';
import 'staff_management_screen.dart';
import 'menu_management_screen.dart';
import '../services/database_service.dart';
import '../models/table_model.dart';
import '../utils/logout_helper.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => LogoutHelper.showLogoutDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              'Waiter View',
              Icons.restaurant,
              Colors.blue,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaiterScreen())),
            ),
            _buildMenuCard(
              context,
              'Kitchen View',
              Icons.kitchen,
              Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenScreen())),
            ),
            _buildMenuCard(
              context,
              'Cashier View',
              Icons.payment,
              Colors.green,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashierScreen())),
            ),
            _buildMenuCard(
              context,
              'Manage Staff',
              Icons.people,
              Colors.purple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
            ),
            _buildMenuCard(
              context,
              'Manage Menu',
              Icons.restaurant_menu,
              Colors.red,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManagementScreen())),
            ),
            _buildMenuCard(
              context,
              'Init Tables',
              Icons.table_bar,
              Colors.grey,
              () async {
                final db = DatabaseService();
                for (int i = 1; i <= 10; i++) {
                  await db.saveTable(TableModel(id: 'table_$i', number: i.toString()));
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('10 Tables Initialized')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

