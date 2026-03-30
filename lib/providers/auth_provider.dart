import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.userStream.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      _user = await _dbService.getUser(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _authService.signIn(email, password);
    
    _isLoading = false;
    notifyListeners();
    return result != null;
  }

  Future<bool> register(String email, String password, String name, UserRole role, {String imageUrl = ''}) async {
    _isLoading = true;
    notifyListeners();
    
    final result = await _authService.register(email, password, name, role, imageUrl: imageUrl);
    
    _isLoading = false;
    notifyListeners();
    return result != null;
  }

  Future<void> updateProfile({String? name, String? phoneNumber, String? imageUrl}) async {
    if (_user == null) return;
    
    final updatedUser = UserModel(
      id: _user!.id,
      name: name ?? _user!.name,
      email: _user!.email,
      role: _user!.role,
      imageUrl: imageUrl ?? _user!.imageUrl,
      phoneNumber: phoneNumber ?? _user!.phoneNumber,
    );
    
    await _dbService.updateUser(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
