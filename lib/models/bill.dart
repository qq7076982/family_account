enum BillType { income, expense }
enum PayType { husband, wife, shared }

class Bill {
  final String id;
  final String familyId;
  final BillType type;
  final double amount;
  final String category;
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
    required this.payType,
    required this.date,
    this.note,
    required this.creatorId,
    this.isSettled = false,
    required this.createdAt,
  });

  factory Bill.fromMap(Map<String, dynamic> data, String id) {
    // 支持 camelCase (CloudBase) 和 snake_case (SQLite)
    String _val(dynamic v) => v?.toString() ?? '';
    String? _str(Map d, String key) {
      final v = d[key] ?? d[key.replaceAllMapped(RegExp(r'_[a-z]'), (m) => m.group(0)!.substring(1).toUpperCase())];
      return v?.toString();
    }
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    double _double(dynamic v) => v is double ? v : double.tryParse(v?.toString() ?? '0') ?? 0.0;

    final typeStr = _str(data, 'type') ?? 'expense';
    final payTypeStr = _str(data, 'payType') ?? 'shared';

    // category 可能是 id 或 name
    final catVal = data['category'] ?? data['category_id'] ?? '';

    return Bill(
      id: id,
      familyId: _str(data, 'familyId') ?? _str(data, 'family_id') ?? '',
      type: typeStr == 'income' ? BillType.income : BillType.expense,
      amount: _double(data['amount'] ?? data['amount']),
      category: catVal.toString(),
      payType: _parsePayType(payTypeStr),
      date: DateTime.fromMillisecondsSinceEpoch(_int(data['date'] ?? data['date'])),
      note: data['note']?.toString(),
      creatorId: _str(data, 'creatorId') ?? _str(data, 'creator_id') ?? '',
      isSettled: data['isSettled'] == true || data['isSettled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(_int(data['createdAt'] ?? data['created_at'])),
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
      'category': category,
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
      payType: payType ?? this.payType,
      date: date ?? this.date,
      note: note ?? this.note,
      creatorId: creatorId,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt,
    );
  }
}