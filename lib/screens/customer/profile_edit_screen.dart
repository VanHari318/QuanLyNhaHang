import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phoneNumber ?? '';
      _emailCtrl.text = user.email;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên không được để trống')));
      return;
    }

    // Password validation if not empty
    if (_newPassCtrl.text.isNotEmpty) {
      if (_newPassCtrl.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải từ 6 ký tự trở lên')));
        return;
      }
      if (_newPassCtrl.text != _confirmPassCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp')));
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      
      // Update Name & Phone
      await auth.updateProfile(
        name: _nameCtrl.text,
        phoneNumber: _phoneCtrl.text,
      );

      // Update Password if provided
      if (_newPassCtrl.text.isNotEmpty) {
        await auth.changePassword(_newPassCtrl.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin thành công!')));
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMsg = 'Lỗi: $e';
      if (e.toString().contains('requires-recent-login')) {
        errorMsg = 'Vì lý do bảo mật, bạn cần Đăng xuất và Đăng nhập lại để thực hiện đổi mật khẩu.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: const Icon(Icons.phone_android_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              enabled: false, // Email is read-only
              decoration: InputDecoration(
                labelText: 'Gmail (Tài khoản)',
                prefixIcon: const Icon(Icons.email_outlined),
                fillColor: Colors.grey.withValues(alpha: 0.1),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Đổi mật khẩu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nếu bạn không muốn đổi mật khẩu, vui lòng bỏ trống hai ô dưới đây.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPassCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_reset),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
