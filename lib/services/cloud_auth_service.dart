import 'package:cloudbase_ce/cloudbase_ce.dart';
import 'package:flutter/foundation.dart';

class CloudAuthService {
  static CloudBaseAuth? _auth;

  static Future<void> init(CloudBaseAuth auth) async {
    _auth = auth;
  }

  static Future<String?> signInAnonymously() async {
    final res = await _auth!.signInAnonymously();
    final state = await _auth!.getAuthState();
    debugPrint('[CloudAuth] signInAnonymously - res: $res');
    debugPrint('[CloudAuth] state: ${state?.uid} ${state?.refreshToken}');
    return state?.uid;
  }

  static Future<String?> getCurrentUid() async {
    final state = await _auth?.getAuthState();
    debugPrint('[CloudAuth] getCurrentUid - state.uid: ${state?.uid}');
    return state?.uid;
  }

  static Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
  }
}
