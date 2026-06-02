import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import '../utils/utils.dart';
import '../utils/app_theme.dart';

class AddBillScreen extends StatefulWidget {
  final String? defaultCategory;

  const AddBillScreen({super.key, this.defaultCategory});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen>
    with SingleTickerProviderStateMixin {
  BillType _type = BillType.expense;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _category;
  PayType _payType = PayType.husband;
  DateTime _date = DateTime.now();
  bool _saving = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _category = widget.defaultCategory;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || _category == null) {
      _showError('请填写金额和分类');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('请输入有效金额');
      return;
    }

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final bp = context.read<BillProvider>();

    // 找到分类 ID
    final allCats = [...bp.expenseCategories, ...bp.incomeCategories];
    final cat = allCats.firstWhere(
      (c) => c.name == _category || c.icon == _category,
      orElse: () => allCats.first,
    );

    await bp.addBill(
      userId: auth.user!.id,
      categoryId: cat.id,
      amount: amount,
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      type: _type,
      payType: _payType,
    );

    setState(() => _saving = false);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BillProvider>();
    final cats = _type == BillType.expense ? bp.expenseCategories : bp.incomeCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.r(10),
            ),
            child: const Icon(Icons.close, size: 20),
          ),
        ),
        title: const Text('记一笔'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // Type selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.fullR,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeTab(
                      label: '支出',
                      emoji: '📤',
                      selected: _type == BillType.expense,
                      color: AppColors.expense,
                      onTap: () => setState(() {
                        _type = BillType.expense;
                        _category = null;
                      }),
                    ),
                  ),
                  Expanded(
                    child: _TypeTab(
                      label: '收入',
                      emoji: '📥',
                      selected: _type == BillType.income,
                      color: AppColors.income,
                      onTap: () => setState(() {
                        _type = BillType.income;
                        _category = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount display
                    _AmountDisplay(
                      controller: _amountController,
                      isExpense: _type == BillType.expense,
                    ),

                    const SizedBox(height: 28),

                    // Category grid
                    const Text('选择分类', style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    _CategoryGrid(
                      categories: cats,
                      selectedCategory: _category,
                      onSelect: (name) => setState(() => _category = name),
                    ),

                    const SizedBox(height: 28),

                    // Pay type
                    const Text('付款人', style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    _PayTypeSelector(
                      selected: _payType,
                      onSelect: (v) => setState(() => _payType = v),
                    ),

                    const SizedBox(height: 28),

                    // Date
                    const Text('日期', style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    _DateSelector(
                      date: _date,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                    ),

                    const SizedBox(height: 28),

                    // Note
                    const Text('备注（选填）', style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: '添加备注...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 12, bottom: 20),
                          child: Text('📝', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: AppRadius.fullR,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpense;

  const _AmountDisplay({
    required this.controller,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.xlR,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '¥',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -2,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List categories;
  final String? selectedCategory;
  final Function(String) onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFF7F50),
      const Color(0xFF9370DB),
      const Color(0xFF20B2AA),
      const Color(0xFF4682B4),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD700),
      const Color(0xFF52C41A),
      const Color(0xFFFF9F43),
      const Color(0xFF6679EE),
      const Color(0xFFEC407A),
      const Color(0xFF26A69A),
      const Color(0xFF78909C),
    ];

    final items = categories.isEmpty
        ? [
            {'name': '餐饮', 'icon': '🍜'},
            {'name': '购物', 'icon': '🛒'},
            {'name': '住房', 'icon': '🏠'},
            {'name': '交通', 'icon': '🚗'},
            {'name': '医疗', 'icon': '💊'},
            {'name': '娱乐', 'icon': '🎮'},
            {'name': '日用', 'icon': '📦'},
            {'name': '其他', 'icon': '📚'},
          ]
        : categories.map((c) => {'name': c.name, 'icon': c.icon}).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.asMap().entries.map((e) {
        final idx = e.key;
        final cat = e.value;
        final selected = selectedCategory == cat['name'];
        final color = colors[idx % colors.length];

        return GestureDetector(
          onTap: () => onSelect(cat['name'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : Colors.white,
              borderRadius: AppRadius.mdR,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                if (!selected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat['icon'] as String,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? color : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PayTypeSelector extends StatelessWidget {
  final PayType selected;
  final Function(PayType) onSelect;

  const _PayTypeSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'type': PayType.husband, 'emoji': '👨', 'label': '老公', 'color': const Color(0xFF6679EE)},
      {'type': PayType.wife, 'emoji': '👩', 'label': '老婆', 'color': const Color(0xFFFF7F50)},
      {'type': PayType.shared, 'emoji': '💑', 'label': '共同', 'color': const Color(0xFF52C41A)},
    ];

    return Row(
      children: items.map((item) {
        final type = item['type'] as PayType;
        final selectedThis = selected == type;
        final color = item['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selectedThis ? color.withValues(alpha: 0.1) : Colors.white,
                borderRadius: AppRadius.mdR,
                border: Border.all(
                  color: selectedThis ? color : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(item['emoji'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selectedThis ? color : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdR,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(
              Utils.formatDate(date),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}