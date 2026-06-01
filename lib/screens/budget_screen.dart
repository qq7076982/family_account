import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../utils/utils.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _totalController = TextEditingController();
  final Map<String, TextEditingController> _catControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.familyId != null) {
      final bp = context.read<BillProvider>();
      final now = DateTime.now();
      bp.loadBudget(auth.user!.familyId!, now.month, now.year);
    }
  }

  @override
  void dispose() {
    _totalController.dispose();
    for (final c in _catControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('预算管控'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: Consumer<BillProvider>(builder: (context, bp, _) {
        final budget = bp.budget;
        final totalBudget = budget?.totalBudget ?? 0;
        final totalExpense = bp.getTotalExpense();
        final remaining = totalBudget - totalExpense;
        final usedPct = totalBudget > 0 ? (totalExpense / totalBudget * 100) : 0.0;

        if (_totalController.text.isEmpty && totalBudget > 0) {
          _totalController.text = totalBudget.toStringAsFixed(0);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 总预算
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '月度总预算',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('¥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _totalController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveTotalBudget(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6679EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('设置预算'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 使用情况
            if (totalBudget > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('已使用', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                            const SizedBox(height: 4),
                            Text(
                              Utils.formatMoney(totalExpense),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('剩余', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                            const SizedBox(height: 4),
                            Text(
                              Utils.formatMoney(remaining),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: remaining >= 0 ? const Color(0xFF52C41A) : const Color(0xFFFF6B6B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (usedPct / 100).clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF5F5F5),
                        valueColor: AlwaysStoppedAnimation(
                          usedPct > 100
                              ? Colors.red
                              : usedPct > 80
                                  ? Colors.orange
                                  : const Color(0xFF6679EE),
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${usedPct.toStringAsFixed(1)}% 已使用',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                        ),
                        if (usedPct > 80)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '⚠️ 预警',
                              style: TextStyle(fontSize: 11, color: Colors.orange),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // 分类预算
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '分类预算',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...bp.expenseCategories.map((cat) {
                    _catControllers.putIfAbsent(
                      cat.name,
                      () => TextEditingController(
                        text: budget?.categoryBudgets[cat.name]?.toStringAsFixed(0) ?? '',
                      ),
                    );
                    final catBudget = budget?.categoryBudgets[cat.name] ?? 0.0;
                    final catExpense = bp.getCategoryExpenses()[cat.name] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text('${cat.icon} ${cat.name}', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (catBudget > 0) ...[
                                  Text(
                                    '预算 ${Utils.formatMoney(catBudget)} / 已花 ${Utils.formatMoney(catExpense)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: (catExpense / catBudget).clamp(0.0, 1.0),
                                      backgroundColor: const Color(0xFFF5F5F5),
                                      valueColor: AlwaysStoppedAnimation(
                                        catExpense > catBudget
                                            ? Colors.red
                                            : catExpense > catBudget * 0.8
                                                ? Colors.orange
                                                : const Color(0xFF6679EE),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '已花 ${Utils.formatMoney(catExpense)}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _catControllers[cat.name]!,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                                hintText: '预算',
                                hintStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _saveCategoryBudgets,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6679EE),
                        side: const BorderSide(color: Color(0xFF6679EE)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('保存分类预算'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        );
      }),
    );
  }

  Future<void> _saveTotalBudget() async {
    final auth = context.read<AuthProvider>();
    final bp = context.read<BillProvider>();
    final budget = double.tryParse(_totalController.text) ?? 0;
    final now = DateTime.now();

    await bp.setBudget(
      auth.user!.familyId!,
      budget,
      {},
      now.month,
      now.year,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已保存')),
      );
    }
  }

  Future<void> _saveCategoryBudgets() async {
    final auth = context.read<AuthProvider>();
    final bp = context.read<BillProvider>();
    final now = DateTime.now();

    final catBudgets = <String, double>{};
    for (final entry in _catControllers.entries) {
      final val = double.tryParse(entry.value.text) ?? 0;
      if (val > 0) catBudgets[entry.key] = val;
    }

    await bp.setBudget(
      auth.user!.familyId!,
      bp.budget?.totalBudget ?? 0,
      catBudgets,
      now.month,
      now.year,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('分类预算已保存')),
      );
    }
  }
}