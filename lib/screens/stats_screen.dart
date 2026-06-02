import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../utils/utils.dart';
import '../utils/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.familyId != null) {
      context.read<BillProvider>().loadMonthlyBills(
            auth.user!.familyId!,
            _selectedYear,
            _selectedMonth,
          );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _animController.reset();
    _animController.forward();
    final auth = context.read<AuthProvider>();
    if (auth.user?.familyId != null) {
      context.read<BillProvider>().loadMonthlyBills(
            auth.user!.familyId!,
            _selectedYear,
            _selectedMonth,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '收支统计',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<BillProvider>(builder: (context, bp, _) {
        final totalExpense = bp.getTotalExpense();
        final totalIncome = bp.getTotalIncome();
        final balance = totalIncome - totalExpense;
        final catExpenses = bp.getCategoryExpenses();

        final sortedCats = catExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return FadeTransition(
          opacity: _fadeAnim,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Month selector
              _MonthSelector(
                year: _selectedYear,
                month: _selectedMonth,
                onPrev: () => _changeMonth(-1),
                onNext: _selectedYear == DateTime.now().year &&
                        _selectedMonth == DateTime.now().month
                    ? null
                    : () => _changeMonth(1),
              ),

              const SizedBox(height: 20),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: '支出',
                      amount: totalExpense,
                      color: AppColors.expense,
                      icon: '📤',
                      gradient: AppColors.expenseGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: '收入',
                      amount: totalIncome,
                      color: AppColors.income,
                      icon: '📥',
                      gradient: AppColors.incomeGradient,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Balance card
              _BalanceCard(balance: balance),

              const SizedBox(height: 24),

              // Pie chart
              if (sortedCats.isNotEmpty) ...[
                _SectionTitle(title: '消费结构', emoji: '📊'),
                const SizedBox(height: 12),
                _PieChartCard(
                  sortedCats: sortedCats,
                  totalExpense: totalExpense,
                ),
                const SizedBox(height: 24),
              ],

              // Category breakdown
              _SectionTitle(title: '分类明细', emoji: '📋'),
              const SizedBox(height: 12),
              _CategoryList(
                sortedCats: sortedCats,
                totalExpense: totalExpense,
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthSelector({
    required this.year,
    required this.month,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
          ),
          Text(
            '$year年${month.toString().padLeft(2, '0')}月',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right,
              color: onNext != null ? AppColors.textSecondary : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String icon;
  final LinearGradient gradient;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.lgR,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
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
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Utils.formatMoney(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.lgR,
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdR,
            ),
            child: Center(
              child: Text(
                isPositive ? '💚' : '💔',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '本月结余',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? '+' : ''}${Utils.formatMoney(balance)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.fullR,
            ),
            child: Text(
              isPositive ? '盈余' : '亏损',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String emoji;

  const _SectionTitle({required this.title, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$emoji $title',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PieChartCard extends StatefulWidget {
  final List<MapEntry<String, double>> sortedCats;
  final double totalExpense;

  const _PieChartCard({
    required this.sortedCats,
    required this.totalExpense,
  });

  @override
  State<_PieChartCard> createState() => _PieChartCardState();
}

class _PieChartCardState extends State<_PieChartCard> {
  int? _touchedIndex;

  static const _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF6679EE),
    Color(0xFF52C41A),
    Color(0xFFFF7F50),
    Color(0xFF9370DB),
    Color(0xFF20B2AA),
    Color(0xFFFFD700),
    Color(0xFF4682B4),
  ];

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = null;
                        return;
                      }
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: widget.sortedCats.asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  final isTouched = _touchedIndex == idx;
                  final pct = widget.totalExpense > 0
                      ? entry.value / widget.totalExpense * 100
                      : 0.0;
                  return PieChartSectionData(
                    color: _colors[idx % _colors.length],
                    value: entry.value,
                    title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    radius: isTouched ? 68 : 58,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: widget.sortedCats.asMap().entries.map((e) {
              final color = _colors[e.key % _colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: AppRadius.r(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    e.value.key,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<MapEntry<String, double>> sortedCats;
  final double totalExpense;

  const _CategoryList({
    required this.sortedCats,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (sortedCats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgR,
        ),
        child: const Center(
          child: Text(
            '本月无支出记录',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return Container(
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
        children: sortedCats.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          final pct = totalExpense > 0 ? entry.value / totalExpense : 0.0;
          final isLast = idx == sortedCats.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(
                        color: Color(0xFFF5F5F5),
                        width: 1,
                      ),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.smR,
                  ),
                  child: Center(
                    child: Text(
                      '📁',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: AppRadius.r(3),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(
                            _getBarColor(pct),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Utils.formatMoney(entry.value),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pct * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getBarColor(double pct) {
    if (pct >= 0.4) return AppColors.expense;
    if (pct >= 0.2) return const Color(0xFFFF9F43);
    return AppColors.primary;
  }
}