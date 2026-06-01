import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill.dart';
import '../models/settlement.dart';
import '../models/budget.dart';
import '../models/category.dart';

class FirestoreService {
  static FirestoreService? _instance;
  static FirebaseFirestore? _db;
  static final Object _initLock = Object();

  FirestoreService._();

  static Future<FirestoreService> getInstance() async {
    if (_instance == null) {
      synchronized (_initLock) {
        if (_instance == null) {
          _instance = FirestoreService._();
        }
      }
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    if (_db != null) return;
    await Firebase.initializeApp();
    _db = FirebaseFirestore.instance;
  }

  FirebaseFirestore get db {
    if (_db == null) {
      throw StateError('FirestoreService not initialized. Did you forget to call getInstance()?');
    }
    return _db!;
  }

  // ========== Family ==========
  Future<String> createFamily(String name, String creatorId) async {
    final doc = await db.collection('families').add({
      'name': name,
      'creatorId': creatorId,
      'createdAt': Timestamp.now(),
      'monthlyBudget': 0.0,
    });
    return doc.id;
  }

  Future<void> updateFamilyMonthlyBudget(String familyId, double budget) async {
    await db.collection('families').doc(familyId).update({'monthlyBudget': budget});
  }

  // ========== Users ==========
  Future<void> createUser(String uid, String name, String gender) async {
    await db.collection('users').doc(uid).set({
      'name': name,
      'gender': gender,
      'familyId': null,
      'createdAt': Timestamp.now(),
      'avatarUrl': null,
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUserFamily(String uid, String familyId) async {
    await db.collection('users').doc(uid).update({'familyId': familyId});
  }

  // ========== Bills ==========
  Future<String> addBill(Bill bill) async {
    final doc = await db.collection('bills').add(bill.toFirestore());
    return doc.id;
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    await db.collection('bills').doc(billId).update(data);
  }

  Future<void> deleteBill(String billId) async {
    await db.collection('bills').doc(billId).delete();
  }

  Stream<QuerySnapshot> watchBills(String familyId) {
    return db
        .collection('bills')
        .where('familyId', isEqualTo: familyId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<List<Bill>> getBillsByMonth(String familyId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final snap = await db
        .collection('bills')
        .where('familyId', isEqualTo: familyId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => Bill.fromFirestore(d)).toList();
  }

  // ========== Settlements ==========
  Future<String> addSettlement(Settlement settlement) async {
    final doc = await db.collection('settlements').add(settlement.toFirestore());
    return doc.id;
  }

  Stream<QuerySnapshot> watchSettlements(String familyId) {
    return db
        .collection('settlements')
        .where('familyId', isEqualTo: familyId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // ========== Categories ==========
  Future<void> initDefaultCategories(String familyId) async {
    final batch = db.batch();
    for (final cat in Category.defaultCategories()) {
      final ref = db.collection('categories').doc('${familyId}_${cat.id}');
      batch.set(ref, {
        'name': cat.name,
        'icon': cat.icon,
        'isDefault': cat.isDefault,
        'isExpense': cat.isExpense,
        'familyId': familyId,
      });
    }
    await batch.commit();
  }

  Stream<QuerySnapshot> watchCategories(String familyId) {
    return db.collection('categories').where('familyId', isEqualTo: familyId).snapshots();
  }

  Future<void> addCategory(String familyId, String name, String icon, bool isExpense) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await db.collection('categories').doc('${familyId}_$id').set({
      'name': name,
      'icon': icon,
      'isDefault': false,
      'isExpense': isExpense,
      'familyId': familyId,
    });
  }

  // ========== Budgets ==========
  Future<void> setBudget(Budget budget) async {
    await db
        .collection('budgets')
        .doc('${budget.familyId}_${budget.year}_${budget.month}')
        .set(budget.toFirestore());
  }

  Future<Budget?> getBudget(String familyId, int year, int month) async {
    final doc = await db
        .collection('budgets')
        .doc('${familyId}_${year}_$month')
        .get();
    if (!doc.exists) return null;
    return Budget.fromMap(doc.data()!, doc.id);
  }

  // ========== Export ==========
  Future<List<Bill>> getAllBills(String familyId) async {
    final snap = await db
        .collection('bills')
        .where('familyId', isEqualTo: familyId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => Bill.fromFirestore(d)).toList();
  }
}