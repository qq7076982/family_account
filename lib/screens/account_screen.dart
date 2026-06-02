import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/settlement.dart';
import '../utils/utils.dart';
import '../utils/app_theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    if (auth.user?.familyId != null) {
      context.read<BillProvider>().loadSettlements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '对账结算',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<BillProvider>(builder: (context, bp, _) {
        final husbandExpense = bp.getHusbandExpense();
        final wifeExpense = bp.getWifeExpense();
        final diff = husbandExpense - wifeExpense;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Balance overview
            _SettlementCard(
              husbandExpense: husbandExpense,
              wifeExpense: wifeExpense,
              diff: diff,
              onSettle: diff.abs() > 0.01 ? () => _showSettleDialog(diff) : null,
            ),

            const SizedBox(height: 20),

            // Settlement logic explanation
            if (diff.abs() > 0.01) ...[
              _SettlementLogic(diff: diff),
              const SizedBox(height: 20),
            ],

            // Settlement history
            Row(
              children: [
                const Text('💰 ', style: TextStyle(fontSize: 16)),
                const Text(
                  '结算记录',
                  style: AppTextStyles.sectionTitle,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (bp.settlements.isEmpty)
              _EmptySettlements()
            else
              ...bp.settlements.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SettlementItemCard(settlement: s),
                  )),

            const SizedBox(height: 100),
          ],
        );
      }),
    );
  }

  void _showSettleDialog(double diff) {
    final auth = context.read<AuthProvider>();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        title: const Text('确认结算'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: AppRadius.mdR,
              ),
              child: Row(
                children: [
                  Text(
                    diff > 0 ? '👩' : '👨',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diff > 0
                              ? '老婆 需要转账给老公'
                              : '老公 需要转账给老婆',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Utils.formatMoney(diff.abs()),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '添加备注（可选）',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text('📝', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final bp = context.read<BillProvider>();
              // 查找对方用户 ID
              final otherId = await bp.getOtherUserId();
              await bp.addSettlement(
                fromUserId: diff > 0 ? auth.user!.id : (otherId ?? auth.user!.id),
                toUserId: diff > 0 ? (otherId ?? auth.user!.id) : auth.user!.id,
                amount: diff.abs(),
                note: noteController.text.isEmpty ? null : noteController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdR,
              ),
            ),
            child: const Text('确认结算', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final double husbandExpense;
  final double wifeExpense;
  final double diff;
  final VoidCallback? onSettle;

  const _SettlementCard({
    required this.husbandExpense,
    required this.wifeExpense,
    required this.diff,
    this.onSettle,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = diff.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.xlR,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '本月各自垫付',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),

          // Two columns
          Row(
            children: [
              Expanded(
                child: _PersonExpenseColumn(
                  emoji: '👨',
                  name: '老公',
                  amount: husbandExpense,
                  color: const Color(0xFF6679EE),
                  isLeading: diff > 0.01,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: const Color(0xFFF0F0F0),
              ),
              Expanded(
                child: _PersonExpenseColumn(
                  emoji: '👩',
                  name: '老婆',
                  amount: wifeExpense,
                  color: const Color(0xFFFF7F50),
                  isLeading: diff < -0.01,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status badge
          if (isEven)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.1),
                borderRadius: AppRadius.fullR,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✅', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text(
                    '已结清，互不相欠',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.08),
                borderRadius: AppRadius.fullR,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(diff > 0 ? '👩' : '👨', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    diff > 0
                        ? '老婆欠老公 ${Utils.formatMoney(diff)}'
                        : '老公欠老婆 ${Utils.formatMoney(-diff)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),

          if (!isEven && onSettle != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onSettle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdR,
                  ),
                ),
                child: const Text('发起结算 →'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonExpenseColumn extends StatelessWidget {
  final String emoji;
  final String name;
  final double amount;
  final Color color;
  final bool isLeading;

  const _PersonExpenseColumn({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.color,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          Utils.formatMoney(amount),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        if (isLeading)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.r(8),
            ),
            child: const Text(
              '多垫',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _SettlementLogic extends StatelessWidget {
  final double diff;

  const _SettlementLogic({required this.diff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: AppRadius.lgR,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '结算说明',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  diff > 0
                      ? '本月老公垫付更多，差额为 ${Utils.formatMoney(diff)}，老婆应付给老公。'
                      : '本月老婆垫付更多，差额为 ${Utils.formatMoney(-diff)}，老公应付给老婆。',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementItemCard extends StatelessWidget {
  final Settlement settlement;

  const _SettlementItemCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: AppRadius.mdR,
            ),
            child: const Center(
              child: Text('✅', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Utils.formatMoney(settlement.amount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (settlement.note != null && settlement.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      settlement.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Utils.formatRelativeDate(settlement.date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySettlements extends StatelessWidget {
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
              color: AppColors.income.withValues(alpha: 0.08),
              borderRadius: AppRadius.xlR,
            ),
            child: const Center(
              child: Text('📜', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无结算记录',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '当双方有垫付差额时，可以发起结算',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}