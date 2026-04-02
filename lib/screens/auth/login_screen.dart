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

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    if (mounted) {
      setState(() => _isLoading = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đăng nhập Google thất bại'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Gradient ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B0000), // Dark Red
                  const Color(0xFFC0392B), // Lighter Red
                  const Color(0xFFD4AC0D), // Gold/Mustard
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Floating Shapes (Decorations) ───────────────────────────────
          Positioned(
            top: -50, right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            bottom: 100, left: -60,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
            ),
          ),

          // ── Main Content ────────────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo at top
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 80, height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vị Lai Quán',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── THE POPUP CARD ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLogin
                                ? 'Đăng Nhập'
                                : (_isCustomer ? 'Đăng Ký Khách' : 'Đăng Ký Nhân Viên'),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Chào mừng bạn quay trở lại 👋' : 'Gia nhập cộng đồng Vị Lai 🏮',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                          ),
                          const SizedBox(height: 24),

                          // Avatar (Register mode only)
                          if (!_isLogin) ...[
                            Center(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Stack(children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: cs.surfaceContainerHighest,
                                    backgroundImage: _webImage != null
                                        ? NetworkImage(_webImage!.path)
                                        : (_imageFile != null
                                            ? FileImage(_imageFile!) as ImageProvider
                                            : null),
                                    child: (_imageFile == null && _webImage == null)
                                        ? Icon(Icons.person_rounded, size: 30, color: cs.primary)
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0, bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInput(
                              controller: _nameCtrl,
                              label: 'Họ và tên',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                          ],

                          _buildInput(
                            controller: _emailCtrl,
                            label: 'Email',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          _buildInput(
                            controller: _passwordCtrl,
                            label: 'Mật khẩu',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24),

                          // Login/Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : FilledButton(
                                    onPressed: _submit,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 4,
                                    ),
                                    child: Text(_isLogin ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ NGAY', 
                                        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // Google Sign In
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _googleSignIn,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: cs.outlineVariant),
                              ),
                              icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png', width: 18),
                              label: const Text('Tiếp tục với Google', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Toggle Links
                          Center(
                            child: Column(
                              children: [
                                if (_isLogin)
                                  TextButton(
                                    onPressed: () => setState(() { _isLogin = false; _isCustomer = true; }),
                                    child: const Text('Bạn là khách hàng mới? Tạo tài khoản'),
                                  ),
                                TextButton(
                                  onPressed: () => setState(() {
                                    if (_isLogin) {
                                      _isLogin = false; _isCustomer = false;
                                    } else {
                                      _isLogin = true; _isCustomer = false;
                                    }
                                  }),
                                  child: Text(_isLogin ? 'Đăng ký cho nhân viên' : 'Đã có tài khoản? Đăng nhập ngay'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
