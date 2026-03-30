import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/admin_theme.dart';

/// Màn hình Đăng nhập / Đăng ký - Vị Lai Quán Premium Design
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
      _showError('Mật khẩu phải có ít nhất 6 ký tự');
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
          UserRole.customer,
          imageUrl: imageUrl,
        );
      }
    } catch (_) {
      ok = false;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (!ok) {
        _showError(_isLogin ? 'Email hoặc mật khẩu không đúng' : 'Đăng ký thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AdminColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgPrimary(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── LOGO & BRAND ─────────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 48),

                // ── FORM CONTENT ─────────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: AdminDeco.cardSheet(context).copyWith(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? 'Chào mừng trở lại' : 'Tạo tài khoản mới',
                          style: AdminText.h1(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin 
                              ? 'Vui lòng đăng nhập để tiếp tục quản lý' 
                              : 'Khám phá thế giới ẩm thực độc bản của Vị Lai',
                          style: AdminText.body(context),
                        ),
                        const SizedBox(height: 32),

                        // Avatar picker (Register only)
                        if (!_isLogin) _buildAvatarPicker(),

                        // Fields
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameCtrl,
                            label: 'Họ và tên',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildTextField(
                          controller: _emailCtrl,
                          label: 'Địa chỉ Email',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordCtrl,
                          label: 'Mật khẩu',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            color: AdminColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Submission
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── FOOTER TOGGLE ────────────────────────────────────────────
                _buildToggleLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AdminColors.gold.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: AdminColors.gold.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              'assets/images/logo.png',
              width: 84, height: 84,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('VỊ LAI QUÁN', style: AdminText.brandName),
      ],
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminColors.crimson, width: 2),
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AdminColors.bgElevated(context),
                  backgroundImage: _webImage != null
                      ? NetworkImage(_webImage!.path)
                      : (_imageFile != null ? FileImage(_imageFile!) as ImageProvider : null),
                  child: (_imageFile == null && _webImage == null)
                      ? Icon(Icons.person_add_alt_1_rounded, size: 40, color: AdminColors.textMuted(context))
                      : null,
                ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AdminColors.crimson, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AdminColors.textSecondary(context), fontSize: 14),
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AdminColors.crimson))
          : Container(
              decoration: AdminDeco.iconGradient(AdminColors.crimson, radius: 14),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isLogin ? 'Đăng Nhập' : 'Tạo Tài Khoản',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
    );
  }

  Widget _buildToggleLink() {
    return TextButton(
      onPressed: () => setState(() => _isLogin = !_isLogin),
      style: TextButton.styleFrom(foregroundColor: AdminColors.textSecondary(context)),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 14, color: AdminColors.textSecondary(context)),
          children: [
            TextSpan(text: _isLogin ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? '),
            TextSpan(
              text: _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
              style: const TextStyle(color: AdminColors.crimson, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
