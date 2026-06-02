import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();

  static Future<DatabaseHelper> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseHelper._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'family_account.db');
    debugPrint('[DB] 初始化数据库: $path');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS families (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            creator_id TEXT NOT NULL,
            join_code TEXT UNIQUE NOT NULL,
            created_at INTEGER NOT NULL,
            is_active INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            family_id TEXT NOT NULL,
            name TEXT NOT NULL,
            gender TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            is_active INTEGER DEFAULT 1,
            FOREIGN KEY (family_id) REFERENCES families(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            family_id TEXT NOT NULL,
            name TEXT NOT NULL,
            emoji TEXT NOT NULL,
            type TEXT NOT NULL,
            color TEXT NOT NULL,
            is_default INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (family_id) REFERENCES families(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bills (
            id TEXT PRIMARY KEY,
            family_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            category_id TEXT NOT NULL,
            category_name TEXT,
            amount REAL NOT NULL,
            note TEXT,
            date INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            is_deleted INTEGER DEFAULT 0,
            FOREIGN KEY (family_id) REFERENCES families(id),
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id TEXT PRIMARY KEY,
            family_id TEXT NOT NULL,
            category_id TEXT,
            amount REAL NOT NULL,
            month TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (family_id) REFERENCES families(id),
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settlements (
            id TEXT PRIMARY KEY,
            family_id TEXT NOT NULL,
            from_user_id TEXT NOT NULL,
            to_user_id TEXT NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            settled_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (family_id) REFERENCES families(id),
            FOREIGN KEY (from_user_id) REFERENCES users(id),
            FOREIGN KEY (to_user_id) REFERENCES users(id)
          )
        ''');

        // 默认分类
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.execute('''
          INSERT INTO categories (id, family_id, name, emoji, type, color, is_default, created_at)
          VALUES
            ('cat_food', '', '餐饮', '🍜', 'expense', '#FF6B6B', 1, $now),
            ('cat_shopping', '', '购物', '🛍', 'expense', '#4ECDC4', 1, $now),
            ('cat_transport', '', '交通', '🚗', 'expense', '#45B7D1', 1, $now),
            ('cat_entertainment', '', '娱乐', '🎮', 'expense', '#96CEB4', 1, $now),
            ('cat_medical', '', '医疗', '💊', 'expense', '#FF8A80', 1, $now),
            ('cat_housing', '', '居住', '🏠', 'expense', '#D4A5A5', 1, $now),
            ('cat_education', '', '教育', '📚', 'expense', '#88D8B0', 1, $now),
            ('cat_other', '', '其他', '📦', 'expense', '#90A4AE', 1, $now),
            ('cat_salary', '', '工资', '💰', 'income', '#4CAF50', 1, $now),
            ('cat_bonus', '', '奖金', '🎁', 'income', '#FF9800', 1, $now),
            ('cat_investment', '', '投资', '📈', 'income', '#2196F3', 1, $now),
            ('cat_other_income', '', '其他收入', '💵', 'income', '#9C27B0', 1, $now)
        ''');

        debugPrint('[DB] 数据库创建完成!');
      },
    );
  }

  Database get db {
    if (_db == null) throw Exception('数据库未初始化');
    return _db!;
  }

  // ========== Family ==========
  Future<String> createFamily(String name, String creatorId) async {
    final id = 'fam_${DateTime.now().millisecondsSinceEpoch}';
    final joinCode = _generateJoinCode();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('families', {
      'id': id,
      'name': name,
      'creator_id': creatorId,
      'join_code': joinCode,
      'created_at': now,
      'is_active': 1,
    });
    debugPrint('[DB] 创建账本: $name, ID: $id, 邀请码: $joinCode');
    return id;
  }

  Future<Map<String, dynamic>?> getFamily(String familyId) async {
    final res = await db.query('families', where: 'id = ?', whereArgs: [familyId]);
    return res.isEmpty ? null : res.first;
  }

  Future<Map<String, dynamic>?> getFamilyByJoinCode(String code) async {
    final res = await db.query('families', where: 'join_code = ?', whereArgs: [code]);
    return res.isEmpty ? null : res.first;
  }

  String _generateJoinCode() {
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]).join();
    return code;
  }

  // ========== User ==========
  Future<String> createUser(String familyId, String name, String gender) async {
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('users', {
      'id': id,
      'family_id': familyId,
      'name': name,
      'gender': gender,
      'created_at': now,
      'is_active': 1,
    });
    debugPrint('[DB] 创建用户: $name, ID: $id');
    return id;
  }

  Future<List<Map<String, dynamic>>> getUsersByFamily(String familyId) async {
    return await db.query('users', where: 'family_id = ? AND is_active = 1', whereArgs: [familyId]);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final res = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    return res.isEmpty ? null : res.first;
  }

  // ========== Categories ==========
  Future<void> initCategoriesForFamily(String familyId) async {
    final existing = await db.query('categories', where: 'family_id = ?', whereArgs: [familyId]);
    if (existing.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final categories = [
      {'id': 'cat_food_$familyId', 'name': '餐饮', 'emoji': '🍜', 'type': 'expense', 'color': '#FF6B6B'},
      {'id': 'cat_shopping_$familyId', 'name': '购物', 'emoji': '🛍', 'type': 'expense', 'color': '#4ECDC4'},
      {'id': 'cat_transport_$familyId', 'name': '交通', 'emoji': '🚗', 'type': 'expense', 'color': '#45B7D1'},
      {'id': 'cat_entertainment_$familyId', 'name': '娱乐', 'emoji': '🎮', 'type': 'expense', 'color': '#96CEB4'},
      {'id': 'cat_medical_$familyId', 'name': '医疗', 'emoji': '💊', 'type': 'expense', 'color': '#FF8A80'},
      {'id': 'cat_housing_$familyId', 'name': '居住', 'emoji': '🏠', 'type': 'expense', 'color': '#D4A5A5'},
      {'id': 'cat_education_$familyId', 'name': '教育', 'emoji': '📚', 'type': 'expense', 'color': '#88D8B0'},
      {'id': 'cat_other_$familyId', 'name': '其他', 'emoji': '📦', 'type': 'expense', 'color': '#90A4AE'},
      {'id': 'cat_salary_$familyId', 'name': '工资', 'emoji': '💰', 'type': 'income', 'color': '#4CAF50'},
      {'id': 'cat_bonus_$familyId', 'name': '奖金', 'emoji': '🎁', 'type': 'income', 'color': '#FF9800'},
      {'id': 'cat_investment_$familyId', 'name': '投资', 'emoji': '📈', 'type': 'income', 'color': '#2196F3'},
      {'id': 'cat_other_income_$familyId', 'name': '其他收入', 'emoji': '💵', 'type': 'income', 'color': '#9C27B0'},
    ];

    for (final c in categories) {
      await db.insert('categories', {
        ...c,
        'family_id': familyId,
        'is_default': 1,
        'created_at': now,
      });
    }
    debugPrint('[DB] 为账本 $familyId 初始化分类完成');
  }

  Future<List<Map<String, dynamic>>> getCategoriesByFamily(String familyId) async {
    return await db.query('categories', where: 'family_id = ?', whereArgs: [familyId], orderBy: 'created_at ASC');
  }

  // ========== Bills ==========
  // Bills 表新增 category_name 字段（用于 UI 直接显示分类名）
  // ALTER TABLE bills ADD COLUMN category_name TEXT
  // 但为兼容旧数据库，createBill 已写入 category_name 列
  Future<String> createBill({
    required String familyId,
    required String userId,
    required String categoryId,
    required String categoryName,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final id = 'bill_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('bills', {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'amount': amount,
      'note': note ?? '',
      'date': date.millisecondsSinceEpoch,
      'created_at': now,
      'is_deleted': 0,
    });
    debugPrint('[DB] 创建账单: ¥$amount, 分类: $categoryName($categoryId), ID: $id');
    return id;
  }

  Future<List<Map<String, dynamic>>> getBillsByFamily(String familyId, {int limit = 100}) async {
    return await db.query(
      'bills',
      where: 'family_id = ? AND is_deleted = 0',
      whereArgs: [familyId],
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getBillsByDateRange(
    String familyId,
    DateTime start,
    DateTime end,
  ) async {
    return await db.query(
      'bills',
      where: 'family_id = ? AND is_deleted = 0 AND date >= ? AND date <= ?',
      whereArgs: [familyId, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
  }

  Future<void> updateBill(String billId, Map<String, dynamic> data) async {
    await db.update('bills', data, where: 'id = ?', whereArgs: [billId]);
  }

  Future<void> deleteBill(String billId) async {
    await db.update('bills', {'is_deleted': 1}, where: 'id = ?', whereArgs: [billId]);
  }

  Future<void> addCategory(String familyId, String name, String emoji, String type, String color) async {
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('categories', {
      'id': id,
      'family_id': familyId,
      'name': name,
      'emoji': emoji,
      'type': type,
      'color': color,
      'is_default': 0,
      'created_at': now,
    });
    debugPrint('[DB] 新增分类: $name $emoji, ID: $id');
  }
  Future<void> setBudget(String familyId, String? categoryId, double amount, String month) async {
    final id = 'bud_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query(
      'budgets',
      where: 'family_id = ? AND month = ? AND (category_id = ? OR (category_id IS NULL AND ? IS NULL))',
      whereArgs: [familyId, month, categoryId, categoryId],
    );

    if (existing.isEmpty) {
      await db.insert('budgets', {
        'id': id,
        'family_id': familyId,
        'category_id': categoryId,
        'amount': amount,
        'month': month,
        'created_at': now,
      });
    } else {
      await db.update(
        'budgets',
        {'amount': amount},
        where: 'family_id = ? AND month = ?',
        whereArgs: [familyId, month],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getBudgetsByMonth(String familyId, String month) async {
    return await db.query('budgets', where: 'family_id = ? AND month = ?', whereArgs: [familyId, month]);
  }

  // ========== Settlements ==========
  Future<String> createSettlement({
    required String familyId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? note,
  }) async {
    final id = 'set_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('settlements', {
      'id': id,
      'family_id': familyId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'amount': amount,
      'note': note ?? '',
      'settled_at': now,
      'created_at': now,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getSettlementsByFamily(String familyId) async {
    return await db.query('settlements', where: 'family_id = ?', whereArgs: [familyId], orderBy: 'settled_at DESC');
  }

  // ========== Stats ==========
  Future<Map<String, double>> getMonthStats(String familyId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final bills = await getBillsByDateRange(familyId, start, end);
    double income = 0, expense = 0;

    // 获取所有分类
    final categories = await getCategoriesByFamily(familyId);
    final catMap = {for (var c in categories) c['id'] as String: c['type'] as String};

    for (final b in bills) {
      final catType = catMap[b['category_id'] as String? ?? ''];
      if (catType == 'income') {
        income += b['amount'] as double;
      } else {
        expense += b['amount'] as double;
      }
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // ========== Export ==========
  Future<String> exportToCSV(String familyId) async {
    final bills = await getBillsByFamily(familyId);
    final categories = await getCategoriesByFamily(familyId);
    final users = await getUsersByFamily(familyId);

    final catMap = {for (var c in categories) c['id'] as String: c['name'] as String};
    final userMap = {for (var u in users) u['id'] as String: u['name'] as String};

    final buffer = StringBuffer();
    buffer.writeln('日期,分类,用户,金额,备注');

    for (final b in bills) {
      final date = DateTime.fromMillisecondsSinceEpoch(b['date'] as int);
      final cat = catMap[b['category_id'] as String] ?? '未知';
      final user = userMap[b['user_id'] as String] ?? '未知';
      final amount = b['amount'] as double;
      final note = (b['note'] as String? ?? '').replaceAll(',', ';');
      buffer.writeln('${date.month}/${date.day},$cat,$user,$amount,$note');
    }

    return buffer.toString();
  }
}