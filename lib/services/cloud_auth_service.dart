import 'package:cloudbase_ce/cloudbase_ce.dart';
import 'package:flutter/foundation.dart';

class CloudAuthService {
  static CloudBaseAuth? _auth;

  static Future<void> init(CloudBaseAuth auth) async {
    _auth = auth;
  }

  static Future<String?> signInAnonymously() async {
    try {
      final state = await _auth!.signInAnonymously();
      // The anonymous uuid is stored in cache. Use refreshToken as the user identifier.
      final refreshToken = state?.refreshToken;
      debugPrint('[CloudAuth] signIn result - refreshToken: ${refreshToken?.substring(0, 20)}...');
      return refreshToken;
    } catch (e) {
      debugPrint('[CloudAuth] signInAnonymously ERROR: $e');
      rethrow;
    }
  }

  static Future<String?> getCurrentUid() async {
    try {
      final state = await _auth?.getAuthState();
      final refreshToken = state?.refreshToken;
      debugPrint('[CloudAuth] getCurrentUid - refreshToken: ${refreshToken?.substring(0, 20)}...');
      return refreshToken;
    } catch (e) {
      debugPrint('[CloudAuth] getCurrentUid ERROR: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
  }
}
