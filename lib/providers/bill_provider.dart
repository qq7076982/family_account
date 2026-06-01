import 'package:flutter/material.dart';
import 'package:cloudbase_ce/cloudbase_ce.dart';
import '../models/bill.dart';
import '../models/settlement.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/cloudbase_service.dart';

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
    final cs = await CloudBaseService.getInstance();
    cs.watchBills(familyId).onChange = (Snapshot snapshot) {
      final List docs = snapshot.docs;
      _bills = docs.whereType<Map>().map((d) {
        final map = Map<String, dynamic>.from(d);
        final id = map.remove('_id') ?? map.remove('id') ?? '';
        return Bill.fromMap(map, id.toString());
      }).toList();
      notifyListeners();
    };
  }

  Future<void> watchSettlements(String familyId) async {
    final cs = await CloudBaseService.getInstance();
    cs.watchSettlements(familyId).onChange = (Snapshot snapshot) {
      final List docs = snapshot.docs;
      _settlements = docs.whereType<Map>().map((d) {
        final map = Map<String, dynamic>.from(d);
        final id = map.remove('_id') ?? map.remove('id') ?? '';
        return Settlement.fromMap(map, id.toString());
      }).toList();
      notifyListeners();
    };
  }

  Future<void> watchCategories(String familyId) async {
    final cs = await CloudBaseService.getInstance();
    cs.watchCategories(familyId).onChange = (Snapshot snapshot) {
      final List docs = snapshot.docs;
      _categories = docs.whereType<Map>().map((d) {
        final map = Map<String, dynamic>.from(d);
        final id = map.remove('_id') ?? map.remove('id') ?? '';
        return Category.fromMap(map, id.toString());
      }).toList();
      notifyListeners();
    };
  }

  Future<void> loadMonthlyBills(String familyId, int year, int month) async {
    _loading = true;
    notifyListeners();
    final cs = await CloudBaseService.getInstance();
    final raw = await cs.getBillsByMonth(familyId, year, month);
    _monthlyBills = raw.map((d) {
      final map = Map<String, dynamic>.from(d);
      final id = map.remove('_id') ?? '';
      return Bill.fromMap(map, id.toString());
    }).toList();
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
    final cs = await CloudBaseService.getInstance();
    String payTypeStr = 'shared';
    if (payType == PayType.husband) payTypeStr = 'husband';
    if (payType == PayType.wife) payTypeStr = 'wife';

    final data = {
      'familyId': familyId,
      'type': type == BillType.income ? 'income' : 'expense',
      'amount': amount,
      'category': category,
      'payType': payTypeStr,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'creatorId': creatorId,
      'isSettled': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    return await cs.addBill(data);
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    final cs = await CloudBaseService.getInstance();
    await cs.updateBill(billId, data);
  }

  Future<void> deleteBill(String billId) async {
    final cs = await CloudBaseService.getInstance();
    await cs.deleteBill(billId);
  }

  Future<void> addSettlement({
    required String familyId,
    required double amount,
    required String fromUserId,
    required String toUserId,
    DateTime? date,
    String? note,
  }) async {
    final cs = await CloudBaseService.getInstance();
    await cs.addSettlement({
      'familyId': familyId,
      'amount': amount,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
      'note': note,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> setBudget(String familyId, double totalBudget,
      Map<String, double> categoryBudgets, int month, int year) async {
    final cs = await CloudBaseService.getInstance();
    await cs.setBudget({
      'familyId': familyId,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
      'month': month,
      'year': year,
    });
    _budget = Budget(
      id: '${familyId}_${year}_$month',
      familyId: familyId,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      month: month,
      year: year,
    );
    notifyListeners();
  }

  Future<void> loadBudget(String familyId, int month, int year) async {
    final cs = await CloudBaseService.getInstance();
    final raw = await cs.getBudget(familyId, month, year);
    if (raw != null) {
      _budget = Budget.fromMap(raw, '${familyId}_${year}_$month');
    }
    notifyListeners();
  }

  Future<void> addCategory(
      String familyId, String name, String icon, bool isExpense) async {
    final cs = await CloudBaseService.getInstance();
    await cs.addCategory(familyId, name, icon, isExpense);
  }

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