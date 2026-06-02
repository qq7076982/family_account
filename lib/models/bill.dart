enum BillType { income, expense }
enum PayType { husband, wife, shared }

class Bill {
  final String id;
  final String familyId;
  final BillType type;
  final double amount;
  final String category; // 分类 ID
  final String? categoryName; // 分类名称（用于 UI 显示）
  final PayType payType;
  final DateTime date;
  final String? note;
  final String creatorId;
  final bool isSettled;
  final DateTime createdAt;

  Bill({
    required this.id,
    required this.familyId,
    required this.type,
    required this.amount,
    required this.category,
    this.categoryName,
    required this.payType,
    required this.date,
    this.note,
    required this.creatorId,
    this.isSettled = false,
    required this.createdAt,
  });

  factory Bill.fromMap(Map<String, dynamic> data, String id) {
    String _str(Map d, String key) {
      final v = d[key] ?? d[key.replaceAllMapped(RegExp(r'_[a-z]'), (m) => m.group(0)!.substring(1).toUpperCase())];
      return v?.toString() ?? '';
    }
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) => v is double ? v : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    final typeStr = _str(data, 'type');
    final payTypeStr = _str(data, 'payType');

    return Bill(
      id: id,
      familyId: _str(data, 'familyId'),
      type: typeStr == 'income' ? BillType.income : BillType.expense,
      amount: _double(data['amount']),
      category: _str(data, 'categoryId') ?? _str(data, 'category'),
      categoryName: _str(data, 'categoryName'),
      payType: _parsePayType(payTypeStr),
      date: DateTime.fromMillisecondsSinceEpoch(_int(data['date'])),
      note: data['note']?.toString(),
      creatorId: _str(data, 'creatorId'),
      isSettled: data['isSettled'] == true || data['isSettled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_int(data['createdAt'])),
    );
  }

  static PayType _parsePayType(String val) {
    if (val == 'husband') return PayType.husband;
    if (val == 'wife') return PayType.wife;
    return PayType.shared;
  }

  Map<String, dynamic> toMap() {
    String payTypeStr = 'shared';
    if (payType == PayType.husband) payTypeStr = 'husband';
    if (payType == PayType.wife) payTypeStr = 'wife';

    return {
      'familyId': familyId,
      'type': type == BillType.income ? 'income' : 'expense',
      'amount': amount,
      'categoryId': category,
      'categoryName': categoryName,
      'payType': payTypeStr,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'creatorId': creatorId,
      'isSettled': isSettled,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Bill copyWith({
    double? amount,
    String? category,
    String? categoryName,
    PayType? payType,
    DateTime? date,
    String? note,
    bool? isSettled,
  }) {
    return Bill(
      id: id,
      familyId: familyId,
      type: type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      payType: payType ?? this.payType,
      date: date ?? this.date,
      note: note ?? this.note,
      creatorId: creatorId,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt,
    );
  }
}