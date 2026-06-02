import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import '../utils/utils.dart';
import '../utils/app_theme.dart';
import 'add_bill_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.familyId != null) {
      final bp = context.read<BillProvider>();
      bp.init(auth.user!.familyId!);
      final now = DateTime.now();
      bp.loadMonthlyBills(now.year, now.month);
      bp.loadBudget(now.month, now.year);
    }
  }

  void _openAddBill({String? category}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AddBillScreen(defaultCategory: category),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _deleteBill(Bill bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        title: const Text('删除账单'),
        content: const Text('确定要删除这条账单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
            ),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<BillProvider>().deleteBill(bill.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<BillProvider>(builder: (context, bp, _) {
          final totalExpense = bp.getTotalExpense();
          final totalIncome = bp.getTotalIncome();
          final budget = bp.budget?.totalBudget ?? 0;
          final budgetUsed = budget > 0 ? (totalExpense / budget * 100) : 0.0;
          final remaining = budget - totalExpense;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Utils.formatMonth(DateTime.now()),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '家庭账本',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.mdR,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Month Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _MonthSummaryCard(
                    totalExpense: totalExpense,
                    totalIncome: totalIncome,
                    budget: budget,
                    budgetUsed: budgetUsed,
                    remaining: remaining,
                  ),
                ),
              ),

              // Quick Add Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => _openAddBill(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: AppRadius.mdR,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '记一笔',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '记录一笔支出或收入',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: AppRadius.fullR,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category Pills
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('快捷记账', style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryPillItem(icon: '🍜', label: '餐饮', color: const Color(0xFFFF7F50), onTap: () => _openAddBill(category: '餐饮')),
                            _CategoryPillItem(icon: '🛒', label: '购物', color: const Color(0xFF9370DB), onTap: () => _openAddBill(category: '购物')),
                            _CategoryPillItem(icon: '🏠', label: '住房', color: const Color(0xFF20B2AA), onTap: () => _openAddBill(category: '住房')),
                            _CategoryPillItem(icon: '🚗', label: '交通', color: const Color(0xFF4682B4), onTap: () => _openAddBill(category: '交通')),
                            _CategoryPillItem(icon: '💊', label: '医疗', color: const Color(0xFFFF6B6B), onTap: () => _openAddBill(category: '医疗')),
                            _CategoryPillItem(icon: '🎮', label: '娱乐', color: const Color(0xFFFFD700), onTap: () => _openAddBill(category: '娱乐')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Bills Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('最近账单', style: AppTextStyles.sectionTitle),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.r(12),
                        ),
                        child: Text(
                          '${bp.bills.length} 条',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bills List
              if (bp.bills.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyBillsView(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 10) return null;
                      final bill = bp.bills[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: _BillCardView(
                          bill: bill,
                          onDelete: () => _deleteBill(bill),
                        ),
                      );
                    },
                    childCount: bp.bills.length.clamp(0, 10),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBill(),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '记一笔',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

class _CategoryPillItem extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryPillItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Month Summary Card =====
class _MonthSummaryCard extends StatelessWidget {
  final double totalExpense;
  final double totalIncome;
  final double budget;
  final double budgetUsed;
  final double remaining;

  const _MonthSummaryCard({
    required this.totalExpense,
    required this.totalIncome,
    required this.budget,
    required this.budgetUsed,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.xlR,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatColumn(label: '支出', amount: totalExpense, icon: Icons.arrow_downward),
              ),
              Container(width: 1, height: 50, color: Colors.white.withValues(alpha: 0.25)),
              Expanded(
                child: _StatColumn(label: '收入', amount: totalIncome, icon: Icons.arrow_upward),
              ),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: AppRadius.mdR,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('预算剩余', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        Utils.formatMoney(remaining),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (budgetUsed / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(budgetUsed > 80 ? Colors.redAccent : Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('已用 ${budgetUsed.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('¥${Utils.formatMoney(budget)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
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

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _StatColumn({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          Utils.formatMoney(amount),
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ===== Bill Card =====
class _BillCardView extends StatelessWidget {
  final Bill bill;
  final VoidCallback onDelete;

  const _BillCardView({required this.bill, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isExpense = bill.type == BillType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;
    final prefix = isExpense ? '-' : '+';

    String payer = '共同';
    IconData payerIcon = Icons.favorite;
    Color payerColor = AppColors.expense;
    if (bill.payType == PayType.husband) {
      payer = '老公';
      payerIcon = Icons.person;
      payerColor = const Color(0xFF6679EE);
    }
    if (bill.payType == PayType.wife) {
      payer = '老婆';
      payerIcon = Icons.person;
      payerColor = const Color(0xFFFF7F50);
    }

    return Dismissible(
      key: Key(bill.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
            title: const Text('删除账单'),
            content: const Text('确定要删除这条账单吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
                ),
                child: const Text('删除', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await context.read<BillProvider>().deleteBill(bill.id);
        }
        return confirmed ?? false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: AppRadius.mdR,
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.expense, size: 24),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.mdR,
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.12),
                borderRadius: AppRadius.mdR,
              ),
              child: Icon(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.category,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(payerIcon, size: 13, color: payerColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Text(payer, style: TextStyle(fontSize: 12, color: payerColor.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      Container(width: 3, height: 3, decoration: BoxDecoration(color: AppColors.textDisabled, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text(Utils.formatRelativeDate(bill.date), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix${Utils.formatMoney(bill.amount)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
                if (bill.note != null && bill.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(bill.note!, style: const TextStyle(fontSize: 11, color: AppColors.textDisabled), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Empty State =====
class _EmptyBillsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: AppRadius.xlR,
            ),
            child: const Center(child: Text('📋', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 16),
          const Text('还没有账单记录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('点击上方「记一笔」开始记账吧', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}