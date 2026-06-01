import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import '../models/settlement.dart';
import '../utils/utils.dart';

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
      context.read<BillProvider>().watchSettlements(auth.user!.familyId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('对账结算'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: Consumer<BillProvider>(builder: (context, bp, _) {
        final husbandExpense = bp.getHusbandExpense();
        final wifeExpense = bp.getWifeExpense();
        final diff = husbandExpense - wifeExpense;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 垫付差额卡片
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '本月垫付差额',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        children: [
                          const Text('老公', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                          const SizedBox(height: 4),
                          Text(
                            Utils.formatMoney(husbandExpense),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6679EE),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('—', style: TextStyle(fontSize: 24, color: Color(0xFFCCCCCC))),
                      ),
                      Column(
                        children: [
                          const Text('老婆', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                          const SizedBox(height: 4),
                          Text(
                            Utils.formatMoney(wifeExpense),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7F50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: diff > 0
                          ? const Color(0xFFFF6B6B).withOpacity(0.1)
                          : diff < 0
                              ? const Color(0xFF52C41A).withOpacity(0.1)
                              : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      diff > 0
                          ? '老公多垫了 ${Utils.formatMoney(diff)}，老婆需要还给他'
                          : diff < 0
                              ? '老婆多垫了 ${Utils.formatMoney(-diff)}，老公需要还给她'
                              : '已结清，互不相欠',
                      style: TextStyle(
                        fontSize: 13,
                        color: diff > 0
                            ? const Color(0xFFFF6B6B)
                            : diff < 0
                                ? const Color(0xFF52C41A)
                                : const Color(0xFF999999),
                        fontWeight: diff == 0 ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 快速结算按钮
            if (diff.abs() > 0.01)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Color(0xFF6679EE)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        diff > 0
                            ? '老婆 转给老公 ${Utils.formatMoney(diff)}'
                            : '老公 转给老婆 ${Utils.formatMoney(-diff)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showSettleDialog(diff),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6679EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('确认结算'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 结算记录
            const Text(
              '结算记录',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),

            if (bp.settlements.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 40, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 8),
                      Text('暂无结算记录', style: TextStyle(color: Color(0xFF999999))),
                    ],
                  ),
                ),
              )
            else
              ...bp.settlements.map((s) => _SettlementItem(settlement: s)),
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
        title: const Text('确认结算'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diff > 0
                  ? '老婆 转给老公 ${Utils.formatMoney(diff)}'
                  : '老公 转给老婆 ${Utils.formatMoney(-diff)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: '备注（可选）',
                border: OutlineInputBorder(),
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
              final fromId = diff > 0 ? auth.user!.id : auth.user!.id;
              final toId = diff > 0 ? 'other' : auth.user!.id;
              await bp.addSettlement(
                familyId: auth.user!.familyId!,
                amount: diff.abs(),
                fromUserId: diff > 0 ? auth.user!.id : 'other',
                toUserId: diff > 0 ? 'other' : auth.user!.id,
                note: noteController.text.isEmpty ? null : noteController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6679EE),
            ),
            child: const Text('确认', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SettlementItem extends StatelessWidget {
  final Settlement settlement;

  const _SettlementItem({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF52C41A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF52C41A), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Utils.formatMoney(settlement.amount)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (settlement.note != null)
                  Text(
                    settlement.note!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
              ],
            ),
          ),
          Text(
            Utils.formatDate(settlement.date),
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}