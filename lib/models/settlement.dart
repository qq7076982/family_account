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
    return Settlement(
      id: id,
      familyId: data['familyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      note: data['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
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