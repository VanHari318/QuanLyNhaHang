import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< HEAD
=======
import 'package:google_sign_in/google_sign_in.dart';
>>>>>>> 6690387 (sua loi)
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();
<<<<<<< HEAD
=======
  final GoogleSignIn _googleSignIn = GoogleSignIn();
>>>>>>> 6690387 (sua loi)

  // Stream of auth state changes
  Stream<User?> get userStream => _auth.authStateChanges();

<<<<<<< HEAD
=======
  // Lấy tài khoản Google đang đăng nhập (nếu có)
  Future<GoogleSignInAccount?> getCurrentGoogleAccount() async {
    return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle({bool forceNewAccount = false}) async {
    try {
      if (forceNewAccount) {
        await _googleSignIn.signOut();
      }
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Google Auth Error (${e.code}): ${e.message}');
      rethrow;
    } catch (e) {
      print('Google Auth Error: $e');
      rethrow;
    }
  }

>>>>>>> 6690387 (sua loi)
  // Sign in with email and password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
<<<<<<< HEAD
    } catch (e) {
      print('Auth Error: $e');
      return null;
=======
    } on FirebaseAuthException catch (e) {
      print('Auth Error (${e.code}): ${e.message}');
      rethrow;
    } catch (e) {
      print('Auth Error: $e');
      rethrow;
>>>>>>> 6690387 (sua loi)
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
<<<<<<< HEAD
    } catch (e) {
      print('Auth Error: $e');
      return null;
=======
    } on FirebaseAuthException catch (e) {
      print('Auth Error (${e.code}): ${e.message}');
      rethrow;
    } catch (e) {
      print('Auth Error: $e');
      rethrow;
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
>>>>>>> 6690387 (sua loi)
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return true;
    } catch (e) {
<<<<<<< HEAD
      print('Auth Error: $e');
      throw e; // Để provider xử lý lời nhắn cụ thể
=======
      print('Auth Error (password): $e');
      throw e;
>>>>>>> 6690387 (sua loi)
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
<<<<<<< HEAD
=======
    await _googleSignIn.signOut();
>>>>>>> 6690387 (sua loi)
  }
}
