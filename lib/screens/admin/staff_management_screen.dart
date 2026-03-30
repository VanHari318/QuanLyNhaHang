import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../theme/admin_theme.dart';

/// Màn hình quản lý nhân sự – Haidilao Premium Dark
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _db = DatabaseService();
  UserRole? _selectedRoleFilter; // null = Tất cả

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AdminColors.bgPrimary,
        appBar: AppBar(
          title: const Text('Quản Lý Nhân Sự'),
          backgroundColor: AdminColors.bgPrimary,
          scrolledUnderElevation: 0,
          bottom: const TabBar(
            labelColor: AdminColors.crimson,
            unselectedLabelColor: AdminColors.textSecondary,
            indicatorColor: AdminColors.crimson,
            dividerColor: AdminColors.borderDefault,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Nhân sự'),
              Tab(text: 'Hành chờ duyệt'),
            ],
          ),
        ),
        body: StreamBuilder<List<UserModel>>(
          stream: _db.getAllStaff(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AdminColors.crimson));
            }
            final staff = snapshot.data!;
            var activeStaff = staff.where((u) => u.role != UserRole.undefined).toList();
            final pendingStaff = staff.where((u) => u.role == UserRole.undefined).toList();

            // Áp dụng bộ lọc chức vụ cho tab nhân sự
            if (_selectedRoleFilter != null) {
              activeStaff = activeStaff.where((u) => u.role == _selectedRoleFilter).toList();
            }

            return Column(
              children: [
                if (DefaultTabController.of(context).index == 0) _buildRoleFilterBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(activeStaff, _selectedRoleFilter == null ? 'Chưa có nhân viên nào' : 'Không tìm thấy nhân viên với chức vụ này'),
                      _buildList(pendingStaff, 'Không có yêu cầu chờ duyệt'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AdminColors.crimson,
          foregroundColor: AdminColors.textPrimary,
          onPressed: _showAddDialog,
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Thêm nhân viên', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildList(List<UserModel> staffList, String emptyMsg) {
    if (staffList.isEmpty) {
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
               child: const Icon(Icons.people_outline_rounded, size: 64, color: AdminColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(emptyMsg, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: staffList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Text('Xóa nhân viên', style: AdminText.h1.copyWith(color: AdminColors.error)),
        content: Text('Xóa toàn bộ dữ liệu của "${user.name}" khỏi hệ thống?', style: const TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AdminColors.error,
                foregroundColor: AdminColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
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
              backgroundColor: AdminColors.error,
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
          backgroundColor: AdminColors.bgCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AdminColors.borderDefault),
          ),
          title: Text('Đổi quyền: ${user.name}', style: AdminText.h1),
          content: DropdownButtonFormField<UserRole>(
            value: selected,
            dropdownColor: AdminColors.bgCard,
            decoration: _inputDeco('Vai trò'),
            style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
            items: UserRole.values
                .where((r) => r != UserRole.admin && r != UserRole.customer && r != UserRole.undefined)
                .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                .toList(),
            onChanged: (v) => setS(() => selected = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.crimson,
                foregroundColor: AdminColors.textPrimary,
              ),
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
              child: const Text('Lưu quyền', style: TextStyle(fontWeight: FontWeight.bold)),
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
          backgroundColor: AdminColors.bgCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AdminColors.borderDefault),
          ),
          title: Text('Thêm nhân viên mới', style: AdminText.h1),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: _inputDecoPrefix('Họ tên', Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: _inputDecoPrefix('Dùng Email để Login', Icons.email_outlined),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              value: selected,
              dropdownColor: AdminColors.bgCard,
              style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
              decoration: _inputDecoPrefix('Gán Vai trò', Icons.work_outline),
              items: UserRole.values
                  .where((r) => r != UserRole.admin && r != UserRole.customer && r != UserRole.undefined)
                  .map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))))
                  .toList(),
              onChanged: (v) => setS(() => selected = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.crimson,
                foregroundColor: AdminColors.textPrimary,
              ),
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
              child: const Text('Xác nhận Thêm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AdminColors.textSecondary),
      filled: true,
      fillColor: AdminColors.bgElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.borderDefault)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.borderDefault)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.crimson)),
    );
  }

  InputDecoration _inputDecoPrefix(String label, IconData icon) {
    return _inputDeco(label).copyWith(prefixIcon: Icon(icon, color: AdminColors.textSecondary));
  }

  Widget _buildRoleFilterBar() {
    final roles = [
      null, // Tất cả
      UserRole.waiter,
      UserRole.chef,
      UserRole.cashier,
    ];

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final role = roles[i];
          final isSelected = _selectedRoleFilter == role;
          final label = role == null ? 'Gộp Tất cả' : _roleLabel(role);

          return GestureDetector(
            onTap: () => setState(() => _selectedRoleFilter = role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AdminColors.crimson : AdminColors.bgElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AdminColors.crimsonBright : AdminColors.borderDefault,
                  width: 1,
                ),
              ),
              child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? AdminColors.textPrimary : AdminColors.textSecondary,
                      ),
                    ),
                 ],
              ),
            ),
          );
        },
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
    final roleColor = _roleColor(user.role);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.borderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            backgroundImage: user.imageUrl.isNotEmpty ? NetworkImage(user.imageUrl) : null,
            child: user.imageUrl.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w800, fontSize: 20),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AdminText.h3),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(_roleLabel(user.role).toUpperCase(),
                      style: TextStyle(
                          color: roleColor, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AdminColors.teal, size: 20),
                onPressed: onEdit,
                style: IconButton.styleFrom(backgroundColor: AdminColors.bgElevated),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.error, size: 20),
                onPressed: onDelete,
                style: IconButton.styleFrom(backgroundColor: AdminColors.error.withValues(alpha: 0.1)),
              ),
            ],
          ),
        ],
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

Color _roleColor(UserRole r) {
  return switch (r) {
    UserRole.waiter => AdminColors.info,
    UserRole.chef => AdminColors.warning,
    UserRole.cashier => AdminColors.success,
    UserRole.admin => AdminColors.crimson,
    _ => AdminColors.textMuted,
  };
}
