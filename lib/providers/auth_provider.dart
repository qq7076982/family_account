import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

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

    final uid = AuthService.getCurrentUid();
    if (uid != null) {
      final data = await FirestoreService.getInstance().then((s) => s.getUser(uid));
      if (data != null) {
        _user = AppUser(
          id: uid,
          name: data['name'] ?? '',
          avatarUrl: data['avatarUrl'],
          gender: data['gender'] == 'husband'
              ? Gender.husband
              : Gender.wife,
          familyId: data['familyId'],
          createdAt: DateTime.now(),
        );
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> signInAnon() async {
    final uid = await AuthService.signInAnonymously();
    await FirestoreService.getInstance().then((s) => s.createUser(uid, '用户', 'husband'));
    _user = AppUser(
      id: uid,
      name: '用户',
      gender: Gender.husband,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> createFamilyAndJoin(String familyName, String myName, String myGender) async {
    final fs = await FirestoreService.getInstance();
    final uid = AuthService.getCurrentUid()!;

    // 创建账本
    final familyId = await fs.createFamily(familyName, uid);

    // 更新用户信息
    await fs.createUser(uid, myName, myGender);
    await fs.updateUserFamily(uid, familyId);

    // 初始化默认分类
    await fs.initDefaultCategories(familyId);

    // 重新加载用户
    final data = await fs.getUser(uid);
    _user = AppUser(
      id: uid,
      name: myName,
      avatarUrl: null,
      gender: myGender == 'husband' ? Gender.husband : Gender.wife,
      familyId: familyId,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<String> joinFamily(String familyId, String myName, String myGender) async {
    final fs = await FirestoreService.getInstance();
    final uid = AuthService.getCurrentUid()!;

    await fs.createUser(uid, myName, myGender);
    await fs.updateUserFamily(uid, familyId);

    final data = await fs.getUser(uid);
    _user = AppUser(
      id: uid,
      name: myName,
      avatarUrl: null,
      gender: myGender == 'husband' ? Gender.husband : Gender.wife,
      familyId: familyId,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    return familyId;
  }

  Future<void> refreshUser() async {
    final fs = await FirestoreService.getInstance();
    final uid = AuthService.getCurrentUid();
    if (uid == null) return;
    final data = await fs.getUser(uid);
    if (data != null) {
      _user = AppUser(
        id: uid,
        name: data['name'] ?? '',
        avatarUrl: data['avatarUrl'],
        gender: data['gender'] == 'husband' ? Gender.husband : Gender.wife,
        familyId: data['familyId'],
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _user = null;
    notifyListeners();
  }
}