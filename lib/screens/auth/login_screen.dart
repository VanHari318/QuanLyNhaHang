import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/cloudinary_service.dart';

/// Màn hình đăng nhập / đăng ký – MD3
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _isCustomer = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _imageFile;
  XFile? _webImage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.camera);
    if (img != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = img;
        } else {
          _imageFile = File(img.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mật khẩu phải có ít nhất 6 ký tự'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    bool ok;

    try {
      if (_isLogin) {
        ok = await auth.login(email, password);
      } else {
        String imageUrl = '';
        if (_imageFile != null || _webImage != null) {
          imageUrl = await CloudinaryService.uploadImage(
            imageFile: _imageFile,
            webImage: _webImage,
            preset: CloudinaryService.avatarPreset,
            folder: CloudinaryService.avatarFolder,
          );
        }
        ok = await auth.register(
          email,
          password,
          _nameCtrl.text.trim(),
          _isCustomer ? UserRole.customer : UserRole.undefined,
          imageUrl: imageUrl,
        );
      }
    } catch (_) {
      ok = false;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin
                ? 'Email hoặc mật khẩu không đúng'
                : 'Đăng ký thất bại. Vui lòng thử lại.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo / Header
              Center(
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100, height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Vị Lai Quán',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _isLogin
                        ? 'Đăng nhập để tiếp tục'
                        : (_isCustomer ? 'Đăng ký Khách hàng' : 'Đăng ký Nhân viên'),
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ]),
              ),
              const SizedBox(height: 40),

              // Avatar picker (register only)
              if (!_isLogin) ...[
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: cs.surfaceContainerHighest,
                        backgroundImage: _webImage != null
                            ? NetworkImage(_webImage!.path)
                            : (_imageFile != null
                                ? FileImage(_imageFile!) as ImageProvider
                                : null),
                        child: (_imageFile == null && _webImage == null)
                            ? Icon(Icons.person_rounded,
                                size: 44, color: cs.onSurfaceVariant)
                            : null,
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt_rounded,
                              size: 16, color: cs.onPrimary),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: _submit,
                        child: Text(
                            _isLogin ? 'Đăng nhập' : 'Đăng ký'),
                      ),
              ),
              const SizedBox(height: 12),

              // Toggle
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isLogin = false;
                    _isCustomer = true;
                  }),
                  child: const Text('Bạn là khách hàng mới? Đăng ký ngay'),
                ),
              ),

              // Toggle
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    if (_isLogin) {
                      _isLogin = false;
                      _isCustomer = false;
                    } else {
                      _isLogin = true;
                      _isCustomer = false;
                    }
                  }),
                  child: Text(_isLogin
                      ? 'Chưa có tài khoản? Đăng ký nhân viên'
                      : 'Đã có tài khoản? Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
