import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../utils/utils.dart';
import '../utils/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  final _totalController = TextEditingController();
  final Map<String, TextEditingController> _catControllers = {};
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.familyId != null) {
      final bp = context.read<BillProvider>();
      final now = DateTime.now();
      bp.loadBudget(now.month, now.year);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _totalController.dispose();
    for (final c in _catControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '预算管控',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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

        return FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Total budget card
              _TotalBudgetCard(
                controller: _totalController,
                onSave: _saveTotalBudget,
              ),

              const SizedBox(height: 16),

              // Usage overview
              if (totalBudget > 0) ...[
                _UsageCard(
                  totalExpense: totalExpense,
                  totalBudget: totalBudget,
                  remaining: remaining,
                  usedPct: usedPct,
                ),
                const SizedBox(height: 16),
              ],

              // Category breakdown
              _CategoryBudgetSection(
                bp: bp,
                catControllers: _catControllers,
                onSave: _saveCategoryBudgets,
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _saveTotalBudget() async {
    final bp = context.read<BillProvider>();
    final budget = double.tryParse(_totalController.text) ?? 0;
    final now = DateTime.now();

    await bp.setBudget(budget, {}, now.month, now.year);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 预算已保存'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  Future<void> _saveCategoryBudgets() async {
    final bp = context.read<BillProvider>();
    final now = DateTime.now();

    final catBudgets = <String, double>{};
    for (final entry in _catControllers.entries) {
      final val = double.tryParse(entry.value.text) ?? 0;
      if (val > 0) catBudgets[entry.key] = val;
    }

    await bp.setBudget(bp.budget?.totalBudget ?? 0, catBudgets, now.month, now.year);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 分类预算已保存'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }
}

class _TotalBudgetCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _TotalBudgetCard({
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.xlR,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.mdR,
                ),
                child: const Center(
                  child: Text('🎯', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '月度总预算',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                '¥',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdR,
                ),
              ),
              child: const Text(
                '设置预算',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageCard extends StatefulWidget {
  final double totalExpense;
  final double totalBudget;
  final double remaining;
  final double usedPct;

  const _UsageCard({
    required this.totalExpense,
    required this.totalBudget,
    required this.remaining,
    required this.usedPct,
  });

  @override
  State<_UsageCard> createState() => _UsageCardState();
}

class _UsageCardState extends State<_UsageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnim = Tween<double>(
      begin: 0,
      end: (widget.usedPct / 100).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOver = widget.remaining < 0;
    final isWarning = widget.usedPct > 80 && !isOver;

    final statusColor = isOver
        ? AppColors.expense
        : isWarning
            ? const Color(0xFFFF9F43)
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgR,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _UsageStatColumn(
                  label: '已使用',
                  value: Utils.formatMoney(widget.totalExpense),
                  color: AppColors.expense,
                  icon: '📤',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: const Color(0xFFF0F0F0),
              ),
              Expanded(
                child: _UsageStatColumn(
                  label: '剩余可用',
                  value: Utils.formatMoney(widget.remaining.abs()),
                  color: isOver ? AppColors.expense : AppColors.income,
                  icon: isOver ? '⚠️' : '💚',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              return Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.r(6),
                        child: LinearProgressIndicator(
                          value: _progressAnim.value,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                          minHeight: 10,
                        ),
                      ),
                      if (isOver)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: AppRadius.r(6),
                            child: CustomPaint(
                              painter: _StripePainter(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.usedPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '¥${Utils.formatMoney(widget.totalBudget)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          if (isWarning && !isOver) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F43).withValues(alpha: 0.1),
                borderRadius: AppRadius.fullR,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚠️', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    '预算已使用超过 80%，注意控制支出',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF9F43),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isOver) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.1),
                borderRadius: AppRadius.fullR,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🚨', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    '已超出预算，请注意控制支出',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.expense,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageStatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String icon;

  const _UsageStatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _CategoryBudgetSection extends StatelessWidget {
  final BillProvider bp;
  final Map<String, TextEditingController> catControllers;
  final VoidCallback onSave;

  const _CategoryBudgetSection({
    required this.bp,
    required this.catControllers,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cats = bp.expenseCategories;
    if (cats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgR,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📂', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                '分类预算',
                style: AppTextStyles.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...cats.map((cat) {
            catControllers.putIfAbsent(
              cat.name,
              () => TextEditingController(
                text: bp.budget?.categoryBudgets[cat.name]?.toStringAsFixed(0) ?? '',
              ),
            );
            final catBudget = bp.budget?.categoryBudgets[cat.name] ?? 0.0;
            final catExpense = bp.getCategoryExpenses()[cat.name] ?? 0.0;
            final catPct = catBudget > 0 ? (catExpense / catBudget).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (catBudget > 0)
                        Text(
                          '${(catExpense / catBudget * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: catPct >= 1.0
                                ? AppColors.expense
                                : catPct >= 0.8
                                    ? const Color(0xFFFF9F43)
                                    : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  if (catBudget > 0) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: AppRadius.r(4),
                      child: LinearProgressIndicator(
                        value: catPct,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation(
                          catPct >= 1.0
                              ? AppColors.expense
                              : catPct >= 0.8
                                  ? const Color(0xFFFF9F43)
                                  : AppColors.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已花 ${Utils.formatMoney(catExpense)} / 预算 ${Utils.formatMoney(catBudget)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      '已花 ${Utils.formatMoney(catExpense)}（暂未设置预算）',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '设置预算: ¥',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: catControllers[cat.name]!,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.r(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFEEEEEE),
                              ),
                            ),
                            hintText: '0',
                            hintStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSave,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdR,
                ),
              ),
              child: const Text('保存分类预算'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const stripeSpacing = 8.0;
    for (double x = 0; x < size.width; x += stripeSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}