import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/settlement.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class BillProvider extends ChangeNotifier {
  final FirestoreService _fs;
  List<Bill> _bills = [];
  List<Bill> _monthlyBills = [];
  List<Settlement> _settlements = [];
  List<Category> _categories = [];
  Budget? _budget;
  bool _loading = false;

  List<Bill> get bills => _bills;
  List<Bill> get monthlyBills => _monthlyBills;
  List<Settlement> get settlements => _settlements;
  List<Category> get categories => _categories;
  Budget? get budget => _budget;
  bool get loading => _loading;

  List<Category> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();
  List<Category> get incomeCategories =>
      _categories.where((c) => !c.isExpense).toList();

  BillProvider(this._fs);

  void watchBills(String familyId) {
    _fs.watchBills(familyId).listen((snap) {
      _bills = snap.docs.map((d) => Bill.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  void watchSettlements(String familyId) {
    _fs.watchSettlements(familyId).listen((snap) {
      _settlements = snap.docs.map((d) => Settlement.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  void watchCategories(String familyId) {
    _fs.watchCategories(familyId).listen((snap) {
      _categories = snap.docs.map((d) => Category.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  Future<void> loadMonthlyBills(String familyId, int year, int month) async {
    _loading = true;
    notifyListeners();
    _monthlyBills = await _fs.getBillsByMonth(familyId, year, month);
    _loading = false;
    notifyListeners();
  }

  Future<String> addBill({
    required String familyId,
    required BillType type,
    required double amount,
    required String category,
    required PayType payType,
    required DateTime date,
    String? note,
    required String creatorId,
  }) async {
    final bill = Bill(
      id: const Uuid().v4(),
      familyId: familyId,
      type: type,
      amount: amount,
      category: category,
      payType: payType,
      date: date,
      note: note,
      creatorId: creatorId,
      createdAt: DateTime.now(),
    );
    return await _fs.addBill(bill);
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    await _fs.updateBill(billId, data);
  }

  Future<void> deleteBill(String billId) async {
    await _fs.deleteBill(billId);
  }

  Future<void> addSettlement({
    required String familyId,
    required double amount,
    required String fromUserId,
    required String toUserId,
    DateTime? date,
    String? note,
  }) async {
    final settlement = Settlement(
      id: const Uuid().v4(),
      familyId: familyId,
      amount: amount,
      fromUserId: fromUserId,
      toUserId: toUserId,
      date: date ?? DateTime.now(),
      note: note,
      createdAt: DateTime.now(),
    );
    await _fs.addSettlement(settlement);
  }

  Future<void> setBudget(String familyId, double totalBudget,
      Map<String, double> categoryBudgets, int month, int year) async {
    final budget = Budget(
      id: '${familyId}_${year}_$month',
      familyId: familyId,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      month: month,
      year: year,
    );
    await _fs.setBudget(budget);
    _budget = budget;
    notifyListeners();
  }

  Future<void> loadBudget(String familyId, int month, int year) async {
    _budget = await _fs.getBudget(familyId, month, year);
    notifyListeners();
  }

  Future<void> addCategory(
      String familyId, String name, String icon, bool isExpense) async {
    await _fs.addCategory(familyId, name, icon, isExpense);
  }

  // 统计数据
  double getTotalExpense() {
    return _monthlyBills
        .where((b) => b.type == BillType.expense)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  double getTotalIncome() {
    return _monthlyBills
        .where((b) => b.type == BillType.income)
        .fold(0.0, (sum, b) => sum + b.amount);
  }

  double getHusbandExpense() {
    return _monthlyBills
        .where((b) =>
            b.type == BillType.expense &&
            (b.payType == PayType.husband || b.payType == PayType.shared))
        .fold(0.0, (sum, b) {
      if (b.payType == PayType.shared) return sum + b.amount / 2;
      return sum + b.amount;
    });
  }

  double getWifeExpense() {
    return _monthlyBills
        .where((b) =>
            b.type == BillType.expense &&
            (b.payType == PayType.wife || b.payType == PayType.shared))
        .fold(0.0, (sum, b) {
      if (b.payType == PayType.shared) return sum + b.amount / 2;
      return sum + b.amount;
    });
  }

  Map<String, double> getCategoryExpenses() {
    final Map<String, double> result = {};
    for (final bill in _monthlyBills.where((b) => b.type == BillType.expense)) {
      result[b.category] = (result[b.category] ?? 0) + bill.amount;
    }
    return result;
  }
}