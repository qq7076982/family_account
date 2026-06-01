import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Settlement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Settlement(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'familyId': familyId,
      'amount': amount,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}