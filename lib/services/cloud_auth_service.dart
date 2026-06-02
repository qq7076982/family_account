import 'package:cloudbase_ce/cloudbase_ce.dart';

class CloudAuthService {
  static CloudBaseAuth? _auth;

  static Future<void> init(CloudBaseAuth auth) async {
    _auth = auth;
  }

  static Future<String?> signInAnonymously() async {
    await _auth!.signInAnonymously();
    final state = await _auth!.getAuthState();
    // The refresh token serves as the anonymous user identifier
    return state?.refreshToken;
  }

  static Future<String?> getCurrentUid() async {
    final state = await _auth?.getAuthState();
    return state?.refreshToken;
  }

  static Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
  }
}
