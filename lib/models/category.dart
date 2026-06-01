class Category {
  final String id;
  final String name;
  final String icon;
  final bool isDefault;
  final bool isExpense;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.isDefault = false,
    this.isExpense = true,
  });

  factory Category.fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📦',
      isDefault: data['isDefault'] ?? false,
      isExpense: data['isExpense'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'isDefault': isDefault,
      'isExpense': isExpense,
    };
  }

  static List<Category> defaultCategories() {
    return [
      Category(id: 'meal', name: '餐饮', icon: '🍜', isDefault: true, isExpense: true),
      Category(id: 'housing', name: '住房', icon: '🏠', isDefault: true, isExpense: true),
      Category(id: 'transport', name: '交通', icon: '🚗', isDefault: true, isExpense: true),
      Category(id: 'shopping', name: '购物', icon: '🛒', isDefault: true, isExpense: true),
      Category(id: 'social', name: '人情', icon: '🎁', isDefault: true, isExpense: true),
      Category(id: 'medical', name: '医疗', icon: '💊', isDefault: true, isExpense: true),
      Category(id: 'childcare', name: '育儿', icon: '👶', isDefault: true, isExpense: true),
      Category(id: 'entertainment', name: '娱乐', icon: '🎮', isDefault: true, isExpense: true),
      Category(id: 'other_exp', name: '其他', icon: '📦', isDefault: true, isExpense: true),
      Category(id: 'salary', name: '工资', icon: '💰', isDefault: true, isExpense: false),
      Category(id: 'bonus', name: '奖金', icon: '🎉', isDefault: true, isExpense: false),
      Category(id: 'red_packet', name: '红包', icon: '🧧', isDefault: true, isExpense: false),
      Category(id: 'other_inc', name: '其他收入', icon: '💵', isDefault: true, isExpense: false),
    ];
  }
}