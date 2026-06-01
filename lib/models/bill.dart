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
    final typeStr = data['type'] as String? ?? 'expense';
    final payTypeStr = data['payType'] as String? ?? 'shared';

    return Bill(
      id: id,
      familyId: data['familyId'] ?? '',
      type: typeStr == 'income' ? BillType.income : BillType.expense,
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      payType: _parsePayType(payTypeStr),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      note: data['note'],
      creatorId: data['creatorId'] ?? '',
      isSettled: data['isSettled'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
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