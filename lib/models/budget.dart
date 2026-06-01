class Budget {
  final String id;
  final String familyId;
  final double totalBudget;
  final Map<String, double> categoryBudgets;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.familyId,
    required this.totalBudget,
    required this.categoryBudgets,
    required this.month,
    required this.year,
  });

  factory Budget.fromMap(Map<String, dynamic> data, String id) {
    return Budget(
      id: id,
      familyId: data['familyId'] ?? '',
      totalBudget: (data['totalBudget'] ?? 0).toDouble(),
      categoryBudgets: Map<String, double>.from(
        (data['categoryBudgets'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'totalBudget': totalBudget,
      'categoryBudgets': categoryBudgets,
      'month': month,
      'year': year,
    };
  }
}