import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/cloud_auth_service.dart';
import '../services/cloudbase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = true;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get hasFamily => _user?.familyId != null;

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    final cs = await CloudBaseService.getInstance();
    await CloudAuthService.init(cs.auth);

    final uid = await CloudAuthService.getCurrentUid();
    if (uid != null) {
      final data = await cs.getUser(uid);
      if (data != null) {
        _user = AppUser.fromMap(data, uid);
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> signInAnon() async {
    final cs = await CloudBaseService.getInstance();
    await CloudAuthService.init(cs.auth);
    final uid = await CloudAuthService.signInAnonymously();
    if (uid != null) {
      await cs.createUser(uid, '用户', 'husband');
      _user = AppUser(
        id: uid,
        name: '用户',
        avatarUrl: null,
        gender: Gender.husband,
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> createFamilyAndJoin(String familyName, String myName, String myGender) async {
    final cs = await CloudBaseService.getInstance();
    final uid = await CloudAuthService.getCurrentUid() ?? '';

    final familyId = await cs.createFamily(familyName, uid);
    await cs.createUser(uid, myName, myGender);
    await cs.updateUserFamily(uid, familyId);
    await cs.initDefaultCategories(familyId);

    await cs.getUser(uid); // ensure user record exists
    _user = AppUser.fromMap({
      'name': myName,
      'gender': myGender,
      'familyId': familyId,
    }, uid);
    notifyListeners();
  }

  Future<String> joinFamily(String familyId, String myName, String myGender) async {
    final cs = await CloudBaseService.getInstance();
    final uid = await CloudAuthService.getCurrentUid() ?? '';

    await cs.createUser(uid, myName, myGender);
    await cs.updateUserFamily(uid, familyId);

    await cs.getUser(uid); // ensure user record exists
    _user = AppUser.fromMap({
      'name': myName,
      'gender': myGender,
      'familyId': familyId,
    }, uid);
    notifyListeners();
    return familyId;
  }

  Future<void> refreshUser() async {
    final cs = await CloudBaseService.getInstance();
    final uid = await CloudAuthService.getCurrentUid();
    if (uid == null) return;
    final data = await cs.getUser(uid);
    if (data != null) {
      _user = AppUser.fromMap(data, uid);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await CloudAuthService.signOut();
    _user = null;
    notifyListeners();
  }
}