import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bill.dart';
import '../models/settlement.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class BillProvider extends ChangeNotifier {
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

  Future<void> watchBills(String familyId) async {
    final fs = await FirestoreService.getInstance();
    fs.watchBills(familyId).listen((snap) {
      _bills = snap.docs.map((d) => Bill.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  Future<void> watchSettlements(String familyId) async {
    final fs = await FirestoreService.getInstance();
    fs.watchSettlements(familyId).listen((snap) {
      _settlements = snap.docs.map((d) => Settlement.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  Future<void> watchCategories(String familyId) async {
    final fs = await FirestoreService.getInstance();
    fs.watchCategories(familyId).listen((snap) {
      _categories = snap.docs.map((d) => Category.fromFirestore(d)).toList();
      notifyListeners();
    });
  }

  Future<void> loadMonthlyBills(String familyId, int year, int month) async {
    _loading = true;
    notifyListeners();
    final fs = await FirestoreService.getInstance();
    _monthlyBills = await fs.getBillsByMonth(familyId, year, month);
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
    final fs = await FirestoreService.getInstance();
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
    return await fs.addBill(bill);
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    final fs = await FirestoreService.getInstance();
    await fs.updateBill(billId, data);
  }

  Future<void> deleteBill(String billId) async {
    final fs = await FirestoreService.getInstance();
    await fs.deleteBill(billId);
  }

  Future<void> addSettlement({
    required String familyId,
    required double amount,
    required String fromUserId,
    required String toUserId,
    DateTime? date,
    String? note,
  }) async {
    final fs = await FirestoreService.getInstance();
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
    await fs.addSettlement(settlement);
  }

  Future<void> setBudget(String familyId, double totalBudget,
      Map<String, double> categoryBudgets, int month, int year) async {
    final fs = await FirestoreService.getInstance();
    final budget = Budget(
      id: '${familyId}_${year}_$month',
      familyId: familyId,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      month: month,
      year: year,
    );
    await fs.setBudget(budget);
    _budget = budget;
    notifyListeners();
  }

  Future<void> loadBudget(String familyId, int month, int year) async {
    final fs = await FirestoreService.getInstance();
    _budget = await fs.getBudget(familyId, month, year);
    notifyListeners();
  }

  Future<void> addCategory(
      String familyId, String name, String icon, bool isExpense) async {
    final fs = await FirestoreService.getInstance();
    await fs.addCategory(familyId, name, icon, isExpense);
  }

  // ========== 统计数据 ==========
  double getTotalExpense() {
    double total = 0.0;
    for (final bill in _monthlyBills) {
      if (bill.type == BillType.expense) total += bill.amount;
    }
    return total;
  }

  double getTotalIncome() {
    double total = 0.0;
    for (final bill in _monthlyBills) {
      if (bill.type == BillType.income) total += bill.amount;
    }
    return total;
  }

  double getHusbandExpense() {
    double total = 0.0;
    for (final bill in _monthlyBills) {
      if (bill.type == BillType.expense &&
          (bill.payType == PayType.husband || bill.payType == PayType.shared)) {
        total += bill.payType == PayType.shared ? bill.amount / 2 : bill.amount;
      }
    }
    return total;
  }

  double getWifeExpense() {
    double total = 0.0;
    for (final bill in _monthlyBills) {
      if (bill.type == BillType.expense &&
          (bill.payType == PayType.wife || bill.payType == PayType.shared)) {
        total += bill.payType == PayType.shared ? bill.amount / 2 : bill.amount;
      }
    }
    return total;
  }

  Map<String, double> getCategoryExpenses() {
    final Map<String, double> result = {};
    for (final bill in _monthlyBills) {
      if (bill.type == BillType.expense) {
        result[bill.category] = (result[bill.category] ?? 0.0) + bill.amount;
      }
    }
    return result;
  }
}