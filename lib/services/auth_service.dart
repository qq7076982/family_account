import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static FirebaseAuth get instance => _auth;

  static Future<String> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  static String? getCurrentUid() {
    return _auth.currentUser?.uid;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}