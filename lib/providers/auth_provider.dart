import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/cloud_auth_service.dart';
import '../services/cloudbase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = true;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get hasFamily => _user?.familyId != null;
  String? get error => _error;

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cs = await CloudBaseService.getInstance();
      await CloudAuthService.init(cs.auth);

      final uid = await CloudAuthService.getCurrentUid();
      debugPrint('[AuthProvider] init uid: $uid');
      if (uid != null) {
        final data = await cs.getUser(uid);
        if (data != null) {
          _user = AppUser.fromMap(data, uid);
          debugPrint('[AuthProvider] init user loaded: ${_user?.name}');
        }
      }
    } catch (e) {
      _error = '初始化失败: $e';
      debugPrint('[AuthProvider] init error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> signInAnon() async {
    debugPrint('[AuthProvider] signInAnon called');
    try {
      final cs = await CloudBaseService.getInstance();
      await CloudAuthService.init(cs.auth);
      final uid = await CloudAuthService.signInAnonymously();
      debugPrint('[AuthProvider] signInAnon result uid: $uid');
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
    } catch (e) {
      debugPrint('[AuthProvider] signInAnon error: $e');
      rethrow;
    }
  }

  Future<String?> createFamilyAndJoin(String familyName, String myName, String myGender) async {
    _error = null;
    debugPrint('[AuthProvider] createFamilyAndJoin called: familyName=$familyName myName=$myName');

    try {
      // Step 1: 获取 CloudBase 实例并初始化
      debugPrint('[AuthProvider] Step1: 初始化 CloudBase...');
      final cs = await CloudBaseService.getInstance();
      await CloudAuthService.init(cs.auth);
      debugPrint('[AuthProvider] Step1: CloudBase 初始化完成');

      // Step 2: 获取当前 uid
      debugPrint('[AuthProvider] Step2: 获取 uid...');
      var uid = await CloudAuthService.getCurrentUid();
      debugPrint('[AuthProvider] Step2: uid=$uid');

      // 如果没有 uid，先匿名登录
      if (uid == null) {
        debugPrint('[AuthProvider] uid 为空，执行匿名登录...');
        await signInAnon();
        uid = await CloudAuthService.getCurrentUid();
        debugPrint('[AuthProvider] 匿名登录后 uid=$uid');
      }

      if (uid == null) {
        throw Exception('匿名登录失败，无法获取用户ID');
      }

      // Step 3: 创建账本
      debugPrint('[AuthProvider] Step3: 创建账本...');
      final familyId = await cs.createFamily(familyName, uid);
      debugPrint('[AuthProvider] Step3: 账本创建成功, familyId=$familyId');

      // Step 4: 创建用户记录
      debugPrint('[AuthProvider] Step4: 创建用户记录...');
      await cs.createUser(uid, myName, myGender);
      debugPrint('[AuthProvider] Step4: 用户记录创建成功');

      // Step 5: 关联用户和账本
      debugPrint('[AuthProvider] Step5: 关联用户和账本...');
      await cs.updateUserFamily(uid, familyId);
      debugPrint('[AuthProvider] Step5: 关联成功');

      // Step 6: 初始化默认分类
      debugPrint('[AuthProvider] Step6: 初始化默认分类...');
      await cs.initDefaultCategories(familyId);
      debugPrint('[AuthProvider] Step6: 默认分类初始化成功');

      // Step 7: 刷新用户数据
      debugPrint('[AuthProvider] Step7: 刷新用户数据...');
      await refreshUser();
      debugPrint('[AuthProvider] Step7: 完成!');

      return familyId;
    } catch (e) {
      _error = '创建失败: $e';
      debugPrint('[AuthProvider] createFamilyAndJoin ERROR: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<String> joinFamily(String familyId, String myName, String myGender) async {
    _error = null;
    debugPrint('[AuthProvider] joinFamily called: familyId=$familyId');

    try {
      final cs = await CloudBaseService.getInstance();
      await CloudAuthService.init(cs.auth);

      var uid = await CloudAuthService.getCurrentUid();
      if (uid == null) {
        await signInAnon();
        uid = await CloudAuthService.getCurrentUid();
      }

      if (uid == null) {
        throw Exception('匿名登录失败');
      }

      await cs.createUser(uid, myName, myGender);
      await cs.updateUserFamily(uid, familyId);
      await refreshUser();
      return familyId;
    } catch (e) {
      _error = '加入失败: $e';
      debugPrint('[AuthProvider] joinFamily error: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    try {
      final cs = await CloudBaseService.getInstance();
      final uid = await CloudAuthService.getCurrentUid();
      if (uid == null) return;
      final data = await cs.getUser(uid);
      if (data != null) {
        _user = AppUser.fromMap(data, uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] refreshUser error: $e');
    }
  }

  Future<void> signOut() async {
    await CloudAuthService.signOut();
    _user = null;
    notifyListeners();
  }
}
