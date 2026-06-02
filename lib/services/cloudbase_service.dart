import 'package:cloudbase_ce/cloudbase_ce.dart';
import 'package:flutter/foundation.dart';

class CloudBaseService {
  static CloudBaseService? _instance;
  late CloudBaseCore _core;
  late CloudBaseDatabase _db;
  late CloudBaseAuth _auth;
  bool _initialized = false;

  CloudBaseService._();

  static Future<CloudBaseService> getInstance() async {
    if (_instance == null) {
      _instance = CloudBaseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    if (_initialized) return;
    debugPrint('[CloudBase] 初始化开始...');
    _core = CloudBaseCore.init({
      'env': 'zhangben-2-d9gmgdlqn34dc6d4f',
      'appAccess': {
        'key': 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBpZCI6ImY1M2U5OGE2LWU3MmUtNDJhZi05ZDVjLTExMzMtMGM3ZWJkM2E4NWVhZSIsImVudiI6InpoYW5nYmVuLTItZDlnbWdkbHEzbjRkYzZkNGYiLCJpYXQiOjE3NDk5MzM1NTR9.fLGqVMqjb6qlp_alN5S-giH0L0qMlB35aJ8Upw',
        'version': 'v1',
      },
      'timeout': 10000,
    });
    debugPrint('[CloudBase] Core 初始化完成');
    _db = CloudBaseDatabase(_core);
    _auth = CloudBaseAuth(_core);
    _initialized = true;
    debugPrint('[CloudBase] 初始化完成!');
  }

  CloudBaseDatabase get database => _db;
  CloudBaseAuth get auth => _auth;
  CloudBaseCore get core => _core;

  // ========== Family ==========
  Future<String> createFamily(String name, String creatorId) async {
    debugPrint('[CloudBase] createFamily: name=$name creatorId=$creatorId');
    try {
      final res = await _db.collection('families').add({
        'name': name,
        'creatorId': creatorId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'monthlyBudget': 0.0,
      });
      debugPrint('[CloudBase] createFamily result: ${res.id}');
      return res.id ?? '';
    } catch (e) {
      debugPrint('[CloudBase] createFamily ERROR: $e');
      rethrow;
    }
  }

  Future<void> updateFamilyMonthlyBudget(String familyId, double budget) async {
    debugPrint('[CloudBase] updateFamilyMonthlyBudget: $familyId budget=$budget');
    await _db.collection('families').doc(familyId).update({'monthlyBudget': budget});
  }

  // ========== Users ==========
  Future<void> createUser(String uid, String name, String gender) async {
    debugPrint('[CloudBase] createUser: uid=$uid name=$name gender=$gender');
    try {
      await _db.collection('users').doc(uid).set({
        'name': name,
        'gender': gender,
        'familyId': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'avatarUrl': null,
      });
      debugPrint('[CloudBase] createUser success');
    } catch (e) {
      debugPrint('[CloudBase] createUser ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data;
    } catch (e) {
      debugPrint('[CloudBase] getUser ERROR: $e');
      return null;
    }
  }

  Future<void> updateUserFamily(String uid, String familyId) async {
    debugPrint('[CloudBase] updateUserFamily: uid=$uid familyId=$familyId');
    try {
      await _db.collection('users').doc(uid).update({'familyId': familyId});
      debugPrint('[CloudBase] updateUserFamily success');
    } catch (e) {
      debugPrint('[CloudBase] updateUserFamily ERROR: $e');
      rethrow;
    }
  }

  // ========== Bills ==========
  Future<String> addBill(Map<String, dynamic> billData) async {
    debugPrint('[CloudBase] addBill: $billData');
    try {
      final res = await _db.collection('bills').add(billData);
      debugPrint('[CloudBase] addBill result id: ${res.id}');
      return res.id ?? '';
    } catch (e) {
      debugPrint('[CloudBase] addBill ERROR: $e');
      rethrow;
    }
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    await _db.collection('bills').doc(billId).update(data);
  }

  Future<void> deleteBill(String billId) async {
    await _db.collection('bills').doc(billId).remove();
  }

  RealtimeListener watchBills(String familyId) {
    return _db
        .collection('bills')
        .where({'familyId': familyId})
        .orderBy('date', 'desc')
        .watch();
  }

  Future<List<Map<String, dynamic>>> getBillsByMonth(
      String familyId, int year, int month) async {
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    final snap = await _db
        .collection('bills')
        .where({'familyId': familyId})
        .orderBy('date', 'desc')
        .get();
    final all = snap.data.whereType<Map>();
    return all.where((d) {
      final ts = d['date'] as num?;
      if (ts == null) return false;
      return ts >= start && ts <= end;
    }).toList();
  }

  // ========== Settlements ==========
  Future<String> addSettlement(Map<String, dynamic> data) async {
    debugPrint('[CloudBase] addSettlement: $data');
    try {
      final res = await _db.collection('settlements').add(data);
      debugPrint('[CloudBase] addSettlement result id: ${res.id}');
      return res.id ?? '';
    } catch (e) {
      debugPrint('[CloudBase] addSettlement ERROR: $e');
      rethrow;
    }
  }

  RealtimeListener watchSettlements(String familyId) {
    return _db
        .collection('settlements')
        .where({'familyId': familyId})
        .orderBy('date', 'desc')
        .watch();
  }

  // ========== Categories ==========
  Future<void> initDefaultCategories(String familyId) async {
    debugPrint('[CloudBase] initDefaultCategories for $familyId');
    final cats = [
      {'id': 'meal', 'name': '餐饮', 'icon': '🍜', 'isDefault': true, 'isExpense': true},
      {'id': 'housing', 'name': '住房', 'icon': '🏠', 'isDefault': true, 'isExpense': true},
      {'id': 'transport', 'name': '交通', 'icon': '🚗', 'isDefault': true, 'isExpense': true},
      {'id': 'shopping', 'name': '购物', 'icon': '🛒', 'isDefault': true, 'isExpense': true},
      {'id': 'social', 'name': '人情', 'icon': '🎁', 'isDefault': true, 'isExpense': true},
      {'id': 'medical', 'name': '医疗', 'icon': '💊', 'isDefault': true, 'isExpense': true},
      {'id': 'childcare', 'name': '育儿', 'icon': '👶', 'isDefault': true, 'isExpense': true},
      {'id': 'entertainment', 'name': '娱乐', 'icon': '🎮', 'isDefault': true, 'isExpense': true},
      {'id': 'other_exp', 'name': '其他', 'icon': '📦', 'isDefault': true, 'isExpense': true},
      {'id': 'salary', 'name': '工资', 'icon': '💰', 'isDefault': true, 'isExpense': false},
      {'id': 'bonus', 'name': '奖金', 'icon': '🎉', 'isDefault': true, 'isExpense': false},
      {'id': 'red_packet', 'name': '红包', 'icon': '🧧', 'isDefault': true, 'isExpense': false},
      {'id': 'other_inc', 'name': '其他收入', 'icon': '💵', 'isDefault': true, 'isExpense': false},
    ];
    for (final cat in cats) {
      try {
        await _db.collection('categories').add({...cat, 'familyId': familyId});
      } catch (e) {
        debugPrint('[CloudBase] initDefaultCategories ERROR for ${cat['name']}: $e');
      }
    }
    debugPrint('[CloudBase] initDefaultCategories done');
  }

  RealtimeListener watchCategories(String familyId) {
    return _db.collection('categories').where({'familyId': familyId}).watch();
  }

  Future<void> addCategory(String familyId, String name, String icon, bool isExpense) async {
    await _db.collection('categories').add({
      'name': name,
      'icon': icon,
      'isDefault': false,
      'isExpense': isExpense,
      'familyId': familyId,
    });
  }

  // ========== Budgets ==========
  Future<void> setBudget(Map<String, dynamic> budgetData) async {
    final docId = '${budgetData['familyId']}_${budgetData['year']}_${budgetData['month']}';
    await _db.collection('budgets').doc(docId).set(budgetData);
  }

  Future<Map<String, dynamic>?> getBudget(String familyId, int year, int month) async {
    final docId = '${familyId}_${year}_$month';
    final doc = await _db.collection('budgets').doc(docId).get();
    return doc.data;
  }

  // ========== Export ==========
  Future<List<Map<String, dynamic>>> getAllBills(String familyId) async {
    final snap = await _db
        .collection('bills')
        .where({'familyId': familyId})
        .orderBy('date', 'desc')
        .get();
    return snap.data;
  }
}
