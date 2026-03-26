import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Stream of auth state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Auth Error: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserCredential?> register(String email, String password, String name, UserRole role, {String imageUrl = ''}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      UserModel newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        imageUrl: imageUrl,
      );
      await _db.saveUser(newUser);
      
      return credential;
    } catch (e) {
      print('Auth Error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
