import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  File? _pickedImage;
  XFile? _webPickedImage;
  String? _currentImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _currentImageUrl = user?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _webPickedImage = picked;
        if (!kIsWeb) {
          _pickedImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUploading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String finalImageUrl = _currentImageUrl ?? '';

    // Upload image if picked
    if (_pickedImage != null || _webPickedImage != null) {
      final uploadedUrl = await CloudinaryService.uploadImage(
        imageFile: _pickedImage,
        webImage: _webPickedImage,
        preset: CloudinaryService.avatarPreset,
        folder: CloudinaryService.avatarFolder,
      );
      if (uploadedUrl.isNotEmpty) {
        finalImageUrl = uploadedUrl;
      }
    }

    try {
      await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        imageUrl: finalImageUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Cập nhật thông tin thành công')),
        );
        setState(() {
          _isEditing = false;
          _isUploading = false;
          _currentImageUrl = finalImageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    if (user == null) return const Scaffold(body: Center(child: Text('Không tìm thấy người dùng')));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Chỉnh sửa'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _isEditing = false;
                  _nameController.text = user.name;
                  _phoneController.text = user.phoneNumber ?? '';
                  _pickedImage = null;
                  _webPickedImage = null;
                }),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Hủy'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: _webPickedImage != null
                            ? Image.network(_webPickedImage!.path, fit: BoxFit.cover)
                            : (_pickedImage != null
                                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                : (user.imageUrl.isNotEmpty
                                    ? Image.network(user.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                              color: cs.primaryContainer,
                                              child: Icon(Icons.person_rounded,
                                                  size: 80, color: cs.primary),
                                            ))
                                    : Container(
                                        color: cs.primaryContainer,
                                        child: Icon(Icons.person_rounded,
                                            size: 80, color: cs.primary),
                                      ))),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: cs.primary,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: _pickImage,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info Section
              _buildInfoField(
                label: 'Họ và tên',
                controller: _nameController,
                icon: Icons.person_outline_rounded,
                isEditing: _isEditing,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 20),
              
              _buildInfoField(
                label: 'Email',
                initialValue: user.email,
                icon: Icons.email_outlined,
                isEditing: false, // Email is not editable
              ),
              const SizedBox(height: 20),

              _buildInfoField(
                label: 'Số điện thoại',
                controller: _phoneController,
                icon: Icons.phone_android_rounded,
                isEditing: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              _buildInfoField(
                label: 'Vai trò',
                initialValue: _roleLabel(user.role),
                icon: Icons.badge_outlined,
                isEditing: false, // Role is not editable
              ),

              if (_isEditing) ...[
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUploading ? null : _saveChanges,
                    icon: _isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_isUploading ? 'Đang lưu...' : 'Lưu thay đổi'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    required bool isEditing,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
        const SizedBox(height: 8),
        if (isEditing && controller != null)
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              hintText: 'Nhập $label',
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    initialValue ?? controller?.text ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Quản trị viên',
      UserRole.waiter => 'Nhân viên Phục vụ',
      UserRole.chef => 'Bếp trưởng',
      UserRole.cashier => 'Thu ngân',
      UserRole.customer => 'Khách hàng',
      _ => 'Chưa xác định',
    };
  }
}
