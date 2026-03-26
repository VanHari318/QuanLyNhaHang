import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: StreamBuilder<List<UserModel>>(
        stream: _db.getAllStaff(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final staff = snapshot.data!;
          return ListView.builder(
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final user = staff[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text('${user.email} - ${user.role.name.toUpperCase()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showUpdateRoleDialog(user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _db.deleteUser(user.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStaffDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUpdateRoleDialog(UserModel user) {
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Role: ${user.name}'),
        content: DropdownButtonFormField<UserRole>(
          value: selectedRole,
          items: UserRole.values
              .map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase())))
              .toList(),
          onChanged: (v) => selectedRole = v!,
          decoration: const InputDecoration(labelText: 'Select New Role'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = UserModel(
                id: user.id,
                name: user.name,
                email: user.email,
                role: selectedRole,
              );
              await _db.saveUser(updatedUser);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.waiter;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            DropdownButtonFormField<UserRole>(
              value: selectedRole,
              items: UserRole.values
                  .where((r) => r != UserRole.admin && r != UserRole.customer)
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => selectedRole = v!,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Creating a staff record in Firestore. 
              // Note: Auth account must be created separately or via Cloud Function.
              final newUser = UserModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
                name: nameController.text,
                email: emailController.text,
                role: selectedRole,
              );
              await _db.saveUser(newUser);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
