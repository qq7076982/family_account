import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String creatorId;
  final DateTime createdAt;
  final double monthlyBudget;

  Family({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
    this.monthlyBudget = 0,
  });

  factory Family.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Family(
      id: doc.id,
      name: data['name'] ?? '',
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      monthlyBudget: (data['monthlyBudget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'monthlyBudget': monthlyBudget,
    };
  }
}