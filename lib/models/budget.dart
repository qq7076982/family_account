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
    double _d(dynamic v) => v is double ? v : double.tryParse(v?.toString() ?? '0') ?? 0.0;
    int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;

    final catBudgetsRaw = data['categoryBudgets'] ?? data['category_budgets'] ?? {};
    Map<String, double> catBudgets = {};
    if (catBudgetsRaw is Map) {
      catBudgets = catBudgetsRaw.map((k, v) => MapEntry(k.toString(), _d(v)));
    }

    return Budget(
      id: id,
      familyId: data['familyId']?.toString() ?? data['family_id']?.toString() ?? '',
      totalBudget: _d(data['totalBudget'] ?? data['total_budget']),
      categoryBudgets: catBudgets,
      month: _i(data['month'] ?? data['month']),
      year: _i(data['year'] ?? data['year']),
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