import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/settlement.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class BillProvider extends ChangeNotifier {
  List<Bill> _bills = [];
  List<Bill> _monthlyBills = [];
  List<Settlement> _settlements = [];
  List<Category> _categories = [];
  Budget? _budget;
  bool _loading = false;
  DatabaseHelper? _db;
  String? _familyId;
  String? _currentUserId;

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

  Future<void> init(String familyId, {String? currentUserId}) async {
    _familyId = familyId;
    _currentUserId = currentUserId;
    _db = await DatabaseHelper.getInstance();
    await _loadCategories();
    await _loadBills();
  }

  Future<void> _loadCategories() async {
    if (_familyId == null) return;
    final rows = await _db!.getCategoriesByFamily(_familyId!);
    _categories = rows.map((r) => Category.fromMap(r, r['id'] as String)).toList();
    notifyListeners();
  }

  Future<void> _loadBills() async {
    if (_familyId == null) return;
    _loading = true;
    notifyListeners();

    final rows = await _db!.getBillsByFamily(_familyId!);
    _bills = rows.map((r) => Bill.fromMap(r, r['id'] as String)).toList();

    _loading = false;
    notifyListeners();
  }

  Future<void> loadMonthlyBills(int year, int month) async {
    if (_familyId == null) return;
    _loading = true;
    notifyListeners();

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final rows = await _db!.getBillsByDateRange(_familyId!, start, end);
    _monthlyBills = rows.map((r) => Bill.fromMap(r, r['id'] as String)).toList();

    _loading = false;
    notifyListeners();
  }

  Future<String> addBill({
    required String userId,
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
    required BillType type,
    required PayType payType,
  }) async {
    if (_familyId == null) throw Exception('未加入账本');

    // 存分类名称，用于 UI 直接显示
    final catName = getCategoryNameById(categoryId);

    final id = await _db!.createBill(
      familyId: _familyId!,
      userId: userId,
      categoryId: categoryId,
      categoryName: catName,
      amount: amount,
      date: date,
      note: note,
    );

    await _loadBills();
    // 刷新月度账单（首页统计用）
    final now = DateTime.now();
    await loadMonthlyBills(now.year, now.month);
    return id;
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    await _db!.updateBill(billId, data);
    await _loadBills();
  }

  Future<void> deleteBill(String billId) async {
    await _db!.deleteBill(billId);
    await _loadBills();
    // 刷新月度账单
    final now = DateTime.now();
    await loadMonthlyBills(now.year, now.month);
  }

  // ========== 结算（修复 Bug #4：使用真实对方用户 ID）==========
  Future<void> addSettlement({
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    if (_familyId == null) throw Exception('未加入账本');

    // 如果传入的是 'other'，自动查找对方用户
    String fromId = fromUserId;
    String toId = toUserId;

    if (fromUserId == 'other' || toUserId == 'other') {
      final otherId = await _getOtherUserId();
      if (otherId != null) {
        if (fromUserId == 'other') fromId = otherId;
        if (toUserId == 'other') toId = otherId;
      }
    }

    await _db!.createSettlement(
      familyId: _familyId!,
      fromUserId: fromId,
      toUserId: toId,
      amount: amount,
      note: note,
    );

    await loadSettlements();
  }

  Future<void> loadSettlements() async {
    if (_familyId == null) return;
    final rows = await _db!.getSettlementsByFamily(_familyId!);
    _settlements = rows.map((r) => Settlement.fromMap(r, r['id'] as String)).toList();
    notifyListeners();
  }

  Future<void> setBudget(double totalBudget, Map<String, double> categoryBudgets, int month, int year) async {
    if (_familyId == null) return;

    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    await _db!.setBudget(_familyId!, null, totalBudget, monthStr);

    _budget = Budget(
      id: '${_familyId}_${year}_$month',
      familyId: _familyId!,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      month: month,
      year: year,
    );
    notifyListeners();
  }

  Future<void> loadBudget(int month, int year) async {
    if (_familyId == null) return;

    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await _db!.getBudgetsByMonth(_familyId!, monthStr);
    if (rows.isNotEmpty) {
      _budget = Budget.fromMap(rows.first, '${_familyId}_${year}_$month');
    }
    notifyListeners();
  }

  // ========== 新增分类（修复 Bug #7）==========
  Future<void> addCategory(String name, String emoji, bool isExpense, String color) async {
    if (_familyId == null) return;
    final type = isExpense ? 'expense' : 'income';
    await _db!.addCategory(_familyId!, name, emoji, type, color);
    await _loadCategories();
  }

  // ========== 查找对方用户 ID ==========
  // ========== 查找对方用户 ID ==========
  Future<String?> getOtherUserId() async {
    return _getOtherUserId();
  }

  Future<String?> _getOtherUserId() async {
    if (_familyId == null || _db == null) return null;
    final rows = await _db!.getUsersByFamily(_familyId!);
    for (final r in rows) {
      if (r['id'] != _currentUserId) return r['id'] as String;
    }
    return null;
  }

  void setCurrentUserId(String id) {
    _currentUserId = id;
  }

  // ========== 工具方法 ==========
  String getCategoryNameById(String id) {
    final cat = _categories.where((c) => c.id == id).firstOrNull;
    return cat?.name ?? id;
  }

  // ========== 统计 ==========
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

  // 修复 Bug #6：分类统计使用分类名称而非 ID
  Map<String, double> getCategoryExpenses() {
    final Map<String, double> result = {};
    for (final bill in _monthlyBills) {
      if (bill.type == BillType.expense) {
        final name = bill.categoryName ?? getCategoryNameById(bill.category);
        result[name] = (result[name] ?? 0.0) + bill.amount;
      }
    }
    return result;
  }
}