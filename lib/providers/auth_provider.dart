import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = true;
  String? _error;
  DatabaseHelper? _db;

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
      final db = await DatabaseHelper.getInstance();
      _db = db;

      // 从 SharedPreferences 加载当前用户
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('current_user_id');
      if (uid != null) {
        final data = await db.getUser(uid);
        if (data != null) {
          _user = AppUser(
            id: uid,
            name: data['name'] as String,
            avatarUrl: null,
            gender: data['gender'] == 'wife' ? Gender.wife : Gender.husband,
            familyId: data['family_id'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
          );
        }
      }
    } catch (e) {
      _error = '初始化失败: $e';
      debugPrint('[AuthProvider] init error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> createFamilyAndJoin(String familyName, String myName, String myGender) async {
    _error = null;
    debugPrint('[AuthProvider] createFamilyAndJoin: familyName=$familyName myName=$myName gender=$myGender');

    try {
      final db = _db ?? await DatabaseHelper.getInstance();

      // 创建账本
      final familyId = await db.createFamily(familyName, 'local_user');

      // 初始化该账本的分类
      await db.initCategoriesForFamily(familyId);

      // 创建用户
      final userId = await db.createUser(familyId, myName, myGender);

      // 保存当前用户
      _user = AppUser(
        id: userId,
        name: myName,
        avatarUrl: null,
        gender: myGender == 'wife' ? Gender.wife : Gender.husband,
        familyId: familyId,
        createdAt: DateTime.now(),
      );

      // 持久化
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      await prefs.setString('current_family_id', familyId);

      notifyListeners();
      return familyId;
    } catch (e) {
      _error = '创建失败: $e';
      debugPrint('[AuthProvider] createFamilyAndJoin ERROR: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<String> joinFamily(String joinCode, String myName, String myGender) async {
    _error = null;
    debugPrint('[AuthProvider] joinFamily: code=$joinCode myName=$myName');

    try {
      final db = _db ?? await DatabaseHelper.getInstance();

      // 通过邀请码查找账本
      final family = await db.getFamilyByJoinCode(joinCode.toUpperCase());
      if (family == null) {
        throw Exception('邀请码无效，找不到对应的账本');
      }

      final familyId = family['id'] as String;

      // 创建用户
      final userId = await db.createUser(familyId, myName, myGender);

      // 保存当前用户
      _user = AppUser(
        id: userId,
        name: myName,
        avatarUrl: null,
        gender: myGender == 'wife' ? Gender.wife : Gender.husband,
        familyId: familyId,
        createdAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      await prefs.setString('current_family_id', familyId);

      notifyListeners();
      return familyId;
    } catch (e) {
      _error = '加入失败: $e';
      debugPrint('[AuthProvider] joinFamily ERROR: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('current_user_id');
      if (uid == null) return;

      final db = _db ?? await DatabaseHelper.getInstance();
      final data = await db.getUser(uid);
      if (data != null) {
        _user = AppUser(
          id: uid,
          name: data['name'] as String,
          avatarUrl: null,
          gender: data['gender'] == 'wife' ? Gender.wife : Gender.husband,
          familyId: data['family_id'] as String?,
          createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AuthProvider] refreshUser error: $e');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    _user = null;
    notifyListeners();
  }

  String? get currentFamilyId => _user?.familyId;
}