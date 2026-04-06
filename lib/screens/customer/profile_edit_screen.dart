import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
>>>>>>> 6690387 (sua loi)
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
<<<<<<< HEAD
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscurePass = true;
=======
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isSaving = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
>>>>>>> 6690387 (sua loi)

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
<<<<<<< HEAD
      if (_newPassCtrl.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải từ 6 ký tự trở lên')));
=======
      if (_oldPassCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mật khẩu cũ để xác thực')));
        return;
      }
      if (_newPassCtrl.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới phải từ 6 ký tự trở lên')));
        return;
      }
      if (_newPassCtrl.text == _oldPassCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới không được giống mật khẩu cũ')));
>>>>>>> 6690387 (sua loi)
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
<<<<<<< HEAD
        await auth.changePassword(_newPassCtrl.text);
=======
        await auth.changePassword(_oldPassCtrl.text, _newPassCtrl.text);
>>>>>>> 6690387 (sua loi)
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật thông tin thành công!')));
        Navigator.pop(context);
      }
<<<<<<< HEAD
    } catch (e) {
      String errorMsg = 'Lỗi: $e';
      if (e.toString().contains('requires-recent-login')) {
        errorMsg = 'Vì lý do bảo mật, bạn cần Đăng xuất và Đăng nhập lại để thực hiện đổi mật khẩu.';
=======
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Đã có lỗi xảy ra';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMsg = 'Mật khẩu cũ không chính xác';
      } else if (e.code == 'requires-recent-login') {
        errorMsg = 'Vì lý do bảo mật, bạn cần Đăng xuất và Đăng nhập lại để thực hiện đổi mật khẩu.';
      } else if (e.message != null) {
        errorMsg = e.message!;
>>>>>>> 6690387 (sua loi)
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
<<<<<<< HEAD
=======
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
>>>>>>> 6690387 (sua loi)
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
<<<<<<< HEAD
              'Nếu bạn không muốn đổi mật khẩu, vui lòng bỏ trống hai ô dưới đây.',
=======
              'Nếu bạn không muốn đổi mật khẩu, hãy nhập đủ các ô dưới đây.',
>>>>>>> 6690387 (sua loi)
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
<<<<<<< HEAD
              controller: _newPassCtrl,
              obscureText: _obscurePass,
=======
              controller: _oldPassCtrl,
              obscureText: _obscureOld,
              decoration: InputDecoration(
                labelText: 'Mật khẩu cũ',
                prefixIcon: const Icon(Icons.lock_person_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPassCtrl,
              obscureText: _obscureNew,
>>>>>>> 6690387 (sua loi)
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
<<<<<<< HEAD
                  icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
=======
                  icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
>>>>>>> 6690387 (sua loi)
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPassCtrl,
<<<<<<< HEAD
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_reset),
=======
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
>>>>>>> 6690387 (sua loi)
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
