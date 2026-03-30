import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../theme/admin_theme.dart';

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
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Quản Lý Khách Hàng'),
        backgroundColor: AdminColors.bgPrimary,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _db.getAllCustomers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AdminColors.crimson));
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
                  style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên hoặc email...',
                    hintStyle: const TextStyle(color: AdminColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AdminColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                    filled: true,
                    fillColor: AdminColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AdminColors.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AdminColors.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AdminColors.crimson),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              Expanded(
                child: customers.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = customers[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AdminColors.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AdminColors.borderDefault),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AdminColors.teal.withValues(alpha: 0.15),
                                  backgroundImage: user.imageUrl.isNotEmpty
                                      ? NetworkImage(user.imageUrl)
                                      : null,
                                  child: user.imageUrl.isEmpty
                                      ? Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AdminColors.teal))
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
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 20, color: AdminColors.gold),
                                      onPressed: () => _showRoleDialog(user),
                                      tooltip: 'Cấp quyền nhân sự',
                                      style: IconButton.styleFrom(backgroundColor: AdminColors.bgElevated),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AdminColors.error),
                                      onPressed: () => _confirmDelete(user),
                                      tooltip: 'Xóa',
                                      style: IconButton.styleFrom(backgroundColor: AdminColors.error.withValues(alpha: 0.1)),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _emptyState() {
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
             child: const Icon(Icons.person_search_rounded, size: 64, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(_searchQuery.isEmpty 
            ? 'Chưa có khách hàng nào đăng ký'
            : 'Không tìm thấy khách hàng nào phù hợp',
            style: const TextStyle(color: AdminColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
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
          backgroundColor: AdminColors.bgCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AdminColors.borderDefault),
          ),
          title: Text('Cấp quyền: ${user.name}', style: AdminText.h1),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn chức vụ nhân sự cho người dùng này:', style: TextStyle(color: AdminColors.textSecondary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selected,
                dropdownColor: AdminColors.bgCard,
                style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Chức vụ',
                  labelStyle: const TextStyle(color: AdminColors.textSecondary),
                  filled: true,
                  fillColor: AdminColors.bgElevated,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminColors.borderDefault)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminColors.borderDefault)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AdminColors.crimson)),
                ),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.gold,
                foregroundColor: Colors.black,
              ),
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
                    SnackBar(
                      content: Text('Đã cấp quyền ${selected.name} cho ${user.name}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      backgroundColor: AdminColors.gold,
                    ),
                  );
                }
              },
              child: const Text('Xác nhận Cấp quyền', style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: AdminColors.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AdminColors.borderDefault),
        ),
        title: Text('Xóa khách hàng', style: AdminText.h1.copyWith(color: AdminColors.error)),
        content: Text('Chắc chắn xóa tài khoản "${user.name}" khỏi hệ thống?', style: const TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy', style: TextStyle(color: AdminColors.textSecondary))),
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
            const SnackBar(
               content: Text('Đã xóa khách hàng thành công', style: TextStyle(color: AdminColors.textPrimary)),
               backgroundColor: AdminColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi: $e', style: const TextStyle(color: AdminColors.textPrimary)),
                backgroundColor: AdminColors.error),
          );
        }
      }
    }
  }
}
