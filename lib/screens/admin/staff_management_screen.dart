import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

/// Màn hình quản lý nhân sự – MD3
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản Lý Nhân Sự'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nhân sự'),
              Tab(text: 'Hàng chờ'),
            ],
          ),
        ),
        body: StreamBuilder<List<UserModel>>(
          stream: _db.getAllStaff(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final staff = snapshot.data!;
            final activeStaff = staff.where((u) => u.role != UserRole.undefined).toList();
            final pendingStaff = staff.where((u) => u.role == UserRole.undefined).toList();

            return TabBarView(
              children: [
                _buildList(activeStaff, 'Chưa có nhân viên nào'),
                _buildList(pendingStaff, 'Không có yêu cầu chờ duyệt'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Thêm nhân viên'),
        ),
      ),
    );
  }

  Widget _buildList(List<UserModel> staffList, String emptyMsg) {
    if (staffList.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(emptyMsg),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: staffList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) => _StaffTile(
        user: staffList[i],
        onEdit: () => _showRoleDialog(staffList[i]),
        onDelete: () => _confirmDelete(staffList[i]),
      ),
    );
  }

  Future<void> _confirmDelete(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhân viên'),
        content: Text('Xóa "${user.name}" khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
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
            const SnackBar(content: Text('Đã xóa nhân viên thành công')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showRoleDialog(UserModel user) {
    UserRole selected = user.role == UserRole.undefined ? UserRole.waiter : user.role;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Đổi quyền: ${user.name}'),
          content: DropdownButtonFormField<UserRole>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Quyền'),
            items: UserRole.values
                .where((r) => r != UserRole.admin && r != UserRole.customer && r != UserRole.undefined)
                .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                .toList(),
            onChanged: (v) => setS(() => selected = v!),
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
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole selected = UserRole.waiter;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Thêm nhân viên'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Họ tên', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<UserRole>(
              value: selected,
              decoration: const InputDecoration(labelText: 'Vai trò'),
              items: UserRole.values
                  .where((r) => r != UserRole.admin && r != UserRole.customer && r != UserRole.undefined)
                  .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                  .toList(),
              onChanged: (v) => setS(() => selected = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                await _db.saveUser(UserModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  role: selected,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Staff tile ────────────────────────────────────────────────────────────────
class _StaffTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffTile({required this.user, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roleColor = _roleColor(user.role, cs);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.15),
          backgroundImage: user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
          child: user.imageUrl.isEmpty
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
                )
              : null,
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_roleLabel(user.role),
                  style: TextStyle(
                      color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(Icons.edit_rounded, color: cs.primary), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete_outline_rounded, color: cs.error), onPressed: onDelete),
        ]),
      ),
    );
  }
}

String _roleLabel(UserRole r) {
  return switch (r) {
    UserRole.waiter => 'Phục vụ',
    UserRole.chef => 'Đầu bếp',
    UserRole.cashier => 'Thu ngân',
    UserRole.admin => 'Admin',
    UserRole.customer => 'Khách',
    UserRole.undefined => 'Chờ duyệt',
  };
}

Color _roleColor(UserRole r, ColorScheme cs) {
  return switch (r) {
    UserRole.waiter => Colors.blue,
    UserRole.chef => Colors.orange,
    UserRole.cashier => Colors.green,
    UserRole.admin => cs.error,
    _ => cs.outline,
  };
}
