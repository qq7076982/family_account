import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../utils/utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadData();
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('统计报表'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: Consumer<BillProvider>(builder: (context, bp, _) {
        final totalExpense = bp.getTotalExpense();
        final totalIncome = bp.getTotalIncome();
        final catExpenses = bp.getCategoryExpenses();

        final sortedCats = catExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 月份切换
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '$_selectedYear年${_selectedMonth.toString().padLeft(2, '0')}月',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: (_selectedYear == DateTime.now().year &&
                            _selectedMonth == DateTime.now().month)
                        ? null
                        : () => _changeMonth(1),
                    icon: Icon(
                      Icons.chevron_right,
                      color: (_selectedYear == DateTime.now().year &&
                              _selectedMonth == DateTime.now().month)
                          ? const Color(0xFFCCCCCC)
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 收支概览
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('支出', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                        const SizedBox(height: 6),
                        Text(
                          Utils.formatMoney(totalExpense),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFEEEEEE),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('收入', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                        const SizedBox(height: 6),
                        Text(
                          Utils.formatMoney(totalIncome),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52C41A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFEEEEEE),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('结余', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                        const SizedBox(height: 6),
                        Text(
                          Utils.formatMoney(totalIncome - totalExpense),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: totalIncome >= totalExpense
                                ? const Color(0xFF6679EE)
                                : const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 消费结构饼图
            if (sortedCats.isNotEmpty) ...[
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
                      '消费结构',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: sortedCats.asMap().entries.map((e) {
                            final colors = [
                              const Color(0xFFFF6B6B),
                              const Color(0xFF6679EE),
                              const Color(0xFF52C41A),
                              const Color(0xFFFF7F50),
                              const Color(0xFF9370DB),
                              const Color(0xFF20B2AA),
                              const Color(0xFFFFD700),
                              const Color(0xFF4682B4),
                            ];
                            final pct = totalExpense > 0 ? e.value.value / totalExpense * 100 : 0;
                            return PieChartSectionData(
                              color: colors[e.key % colors.length],
                              value: e.value.value,
                              title: '${pct.toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 60,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: sortedCats.asMap().entries.map((e) {
                        final colors = [
                          const Color(0xFFFF6B6B),
                          const Color(0xFF6679EE),
                          const Color(0xFF52C41A),
                          const Color(0xFFFF7F50),
                          const Color(0xFF9370DB),
                          const Color(0xFF20B2AA),
                          const Color(0xFFFFD700),
                          const Color(0xFF4682B4),
                        ];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[e.key % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.value.key} ${Utils.formatMoney(e.value.value)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 分类明细
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
                    '分类明细',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (sortedCats.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          '本月无支出',
                          style: TextStyle(color: Color(0xFF999999)),
                        ),
                      ),
                    )
                  else
                    ...sortedCats.map((e) {
                      final pct = totalExpense > 0 ? e.value / totalExpense : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                e.key,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6679EE)),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: Text(
                                Utils.formatMoney(e.value),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        );
      }),
    );
  }
}