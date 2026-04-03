import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GoogleSignInAccount?> getCurrentGoogleAccount() {
    return _authService.getCurrentGoogleAccount();
  }

  Future<void> loginWithGoogle({bool forceNewAccount = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle(forceNewAccount: forceNewAccount);
      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;
        final existingUser = await _dbService.getUser(firebaseUser.uid);
        
        if (existingUser == null) {
          final newUser = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Người dùng Google',
            email: firebaseUser.email ?? '',
            role: UserRole.customer,
            imageUrl: firebaseUser.photoURL ?? '',
          );
          await _dbService.saveUser(newUser);
          _user = newUser;
        } else {
          _user = existingUser;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name, UserRole role, {String imageUrl = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(email, password, name, role, imageUrl: imageUrl);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (_user == null) return;
    try {
      await _authService.reauthenticate(_user!.email, oldPassword);
      await _authService.updatePassword(newPassword);
    } catch (e) {
      print('Change Password Error: $e');
      throw e;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
