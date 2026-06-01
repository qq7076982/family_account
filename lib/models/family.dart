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

  factory Family.fromMap(Map<String, dynamic> data, String id) {
    return Family(
      id: id,
      name: data['name'] ?? '',
      creatorId: data['creatorId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      monthlyBudget: (data['monthlyBudget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'creatorId': creatorId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'monthlyBudget': monthlyBudget,
    };
  }
}