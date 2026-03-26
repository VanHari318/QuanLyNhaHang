import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/cloudinary_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  File? _imageFile;
  XFile? _webImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _imageFile = File(pickedFile.path);
        }
      });
    }
  }

  void _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;
    
    if (_isLogin) {
      success = await authProvider.login(_emailController.text.trim(), _passwordController.text.trim());
    } else {
      setState(() => _isUploading = true);
      
      String imageUrl = await CloudinaryService.uploadImage(
        imageFile: _imageFile,
        webImage: _webImage,
        preset: CloudinaryService.avatarPreset,
        folder: CloudinaryService.avatarFolder,
      );
      
      success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        UserRole.customer, 
        imageUrl: imageUrl,
      );
      
      setState(() => _isUploading = false);
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action Failed. Check Console or Credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isLogin) ...[
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _webImage != null 
                    ? NetworkImage(_webImage!.path) 
                    : (_imageFile != null ? FileImage(_imageFile!) : null),
                  child: (_imageFile == null && _webImage == null) ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_isUploading) 
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'New Staff? Register here' : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

