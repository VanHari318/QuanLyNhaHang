import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = "";

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
          var customers = snapshot.data!;

          // Lọc theo tìm kiếm
          if (_searchQuery.isNotEmpty) {
            customers = customers.where((u) {
              final searchStr = '${u.name} ${u.email}'.toLowerCase();
              return searchStr.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Column(
            children: [
              // Thanh tìm kiếm
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              Expanded(
                child: customers.isEmpty
                    ? _emptyState(cs)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = customers[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cs.primaryContainer,
                                backgroundImage: user.imageUrl.isNotEmpty
                                    ? NetworkImage(user.imageUrl)
                                    : null,
                                child: user.imageUrl.isEmpty
                                    ? Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onPrimaryContainer))
                                    : null,
                              ),
                              title: Text(user.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.email,
                                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.admin_panel_settings_rounded, color: cs.primary),
                                    onPressed: () => _showRoleDialog(user),
                                    tooltip: 'Cấp quyền nhân sự',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                                    onPressed: () => _confirmDelete(user),
                                    tooltip: 'Xóa',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(_searchQuery.isEmpty 
            ? 'Chưa có khách hàng nào đăng ký'
            : 'Không tìm thấy khách hàng nào phù hợp'),
        ],
      ),
    );
  }

  void _showRoleDialog(UserModel user) {
    UserRole selected = UserRole.waiter;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Cấp quyền: ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn chức vụ nhân sự cho người dùng này:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Chức vụ'),
                items: UserRole.values
                    .where((r) => r != UserRole.admin && r != UserRole.customer && r != UserRole.undefined)
                    .map((r) => DropdownMenuItem(
                        value: r, 
                        child: Text(r == UserRole.waiter ? 'Phục vụ' : (r == UserRole.chef ? 'Đầu bếp' : 'Thu ngân'))))
                    .toList(),
                onChanged: (v) => setS(() => selected = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                await _db.saveUser(UserModel(
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  role: selected,
                  imageUrl: user.imageUrl,
                ));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cấp quyền ${selected.name} cho ${user.name}')),
                  );
                }
              },
              child: const Text('Cấp quyền'),
            ),
          ],
        ),
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
