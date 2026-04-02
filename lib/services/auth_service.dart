import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Stream of auth state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Auth Error: $e');
      return null;
    }
  }

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

  Future<bool> reauthenticate(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Auth Error (reauth): $e');
      throw e;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
      print('Auth Error (password): $e');
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
