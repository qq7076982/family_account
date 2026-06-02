class Settlement {
  final String id;
  final String familyId;
  final double amount;
  final String fromUserId;
  final String toUserId;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  Settlement({
    required this.id,
    required this.familyId,
    required this.amount,
    required this.fromUserId,
    required this.toUserId,
    required this.date,
    this.note,
    required this.createdAt,
  });

  factory Settlement.fromMap(Map<String, dynamic> data, String id) {
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
    return Settlement(
      id: id,
      familyId: data['familyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(_int(data['settledAt'] ?? data['settled_at'])),
      note: data['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(_int(data['createdAt'] ?? data['created_at'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'amount': amount,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}