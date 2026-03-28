import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Khách Hàng'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _db.getAllCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customers = snapshot.data!;

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  const Text('Chưa có khách hàng nào đăng ký'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = customers[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: user.imageUrl.isNotEmpty
                        ? NetworkImage(user.imageUrl)
                        : null,
                    child: user.imageUrl.isEmpty
                        ? Text(user.name[0].toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: cs.onPrimaryContainer))
                        : null,
                  ),
                  title: Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user.email,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                    onPressed: () => _confirmDelete(user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khách hàng'),
        content: Text('Bạn có chắc muốn xóa tài khoản "${user.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _db.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa khách hàng thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }
}
