import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';
import '../utils/utils.dart';

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
      bp.watchBills(auth.user!.familyId!);
      bp.watchCategories(auth.user!.familyId!);
      final now = DateTime.now();
      bp.loadMonthlyBills(auth.user!.familyId!, now.year, now.month);
      bp.loadBudget(auth.user!.familyId!, now.month, now.year);
    }
  }

  void _showAddBillDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddBillSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Consumer<BillProvider>(builder: (context, bp, _) {
          final totalExpense = bp.getTotalExpense();
          final totalIncome = bp.getTotalIncome();
          final budget = bp.budget?.totalBudget ?? 0;
          final budgetUsed = budget > 0 ? (totalExpense / budget * 100) : 0.0;

          return CustomScrollView(
            slivers: [
              // 顶部：本月概览
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6679EE), Color(0xFF8B9EFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6679EE).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            Utils.formatMonth(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            '家庭账本',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '本月支出',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Utils.formatMoney(totalExpense),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '本月收入',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Utils.formatMoney(totalIncome),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (budget > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (budgetUsed / 100).clamp(0.0, 1.0),
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation(
                                    budgetUsed > 80
                                        ? Colors.redAccent
                                        : Colors.white,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${budgetUsed.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '预算 ¥${Utils.formatMoney(budget)}，剩余 ${Utils.formatMoney(budget - totalExpense)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 快速记一笔按钮
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _showAddBillDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
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
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6679EE), Color(0xFF8B9EFF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            '记一笔',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 快捷模板
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '快捷操作',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickButton(
                            icon: Icons.restaurant,
                            label: '餐饮',
                            color: const Color(0xFFFF7F50),
                            onTap: () => _quickAdd('餐饮'),
                          ),
                          const SizedBox(width: 12),
                          _QuickButton(
                            icon: Icons.shopping_bag,
                            label: '购物',
                            color: const Color(0xFF9370DB),
                            onTap: () => _quickAdd('购物'),
                          ),
                          const SizedBox(width: 12),
                          _QuickButton(
                            icon: Icons.home,
                            label: '住房',
                            color: const Color(0xFF20B2AA),
                            onTap: () => _quickAdd('住房'),
                          ),
                          const SizedBox(width: 12),
                          _QuickButton(
                            icon: Icons.directions_car,
                            label: '交通',
                            color: const Color(0xFF4682B4),
                            onTap: () => _quickAdd('交通'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 最近账单
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '最近账单',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('查看全部', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),

              // 账单列表
              if (bp.bills.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long, size: 48, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 12),
                          Text('暂无账单', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= 10) return null;
                      final bill = bp.bills[index];
                      return _BillItem(bill: bill);
                    },
                    childCount: bp.bills.length.clamp(0, 10),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBillDialog,
        backgroundColor: const Color(0xFF6679EE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _quickAdd(String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddBillSheet(defaultCategory: category),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillItem extends StatelessWidget {
  final Bill bill;

  const _BillItem({required this.bill});

  @override
  Widget build(BuildContext context) {
    final isExpense = bill.type == BillType.expense;
    final color = isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF52C41A);
    final prefix = isExpense ? '-' : '+';

    String payer = '共同';
    if (bill.payType == PayType.husband) payer = '老公';
    if (bill.payType == PayType.wife) payer = '老婆';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.category,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '$payer · ${Utils.formatRelativeDate(bill.date)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Text(
            '$prefix${Utils.formatMoney(bill.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== 记一笔表单 ==========
class AddBillSheet extends StatefulWidget {
  final String? defaultCategory;

  const AddBillSheet({super.key, this.defaultCategory});

  @override
  State<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<AddBillSheet> {
  BillType _type = BillType.expense;
  final _amountController = TextEditingController();
  String? _category;
  PayType _payType = PayType.husband;
  DateTime _date = DateTime.now();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _category = widget.defaultCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写金额和分类')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final bp = context.read<BillProvider>();

    await bp.addBill(
      familyId: auth.user!.familyId!,
      type: _type,
      amount: amount,
      category: _category!,
      payType: _payType,
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      creatorId: auth.user!.id,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BillProvider>();
    final cats = _type == BillType.expense ? bp.expenseCategories : bp.incomeCategories;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 拖动条
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '记一笔',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 收支切换
            Row(
              children: [
                _TabButton(
                  label: '支出',
                  selected: _type == BillType.expense,
                  color: const Color(0xFFFF6B6B),
                  onTap: () => setState(() {
                    _type = BillType.expense;
                    _category = null;
                  }),
                ),
                const SizedBox(width: 12),
                _TabButton(
                  label: '收入',
                  selected: _type == BillType.income,
                  color: const Color(0xFF52C41A),
                  onTap: () => setState(() {
                    _type = BillType.income;
                    _category = null;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 金额输入
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    '¥',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 分类选择
            const Text('分类', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((cat) {
                final selected = _category == cat.name;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6679EE)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat.icon} ${cat.name}',
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 付款人
            const Text('付款人', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            const SizedBox(height: 10),
            Row(
              children: [
                _PayTypeChip(
                  label: '老公',
                  selected: _payType == PayType.husband,
                  onTap: () => setState(() => _payType = PayType.husband),
                ),
                const SizedBox(width: 10),
                _PayTypeChip(
                  label: '老婆',
                  selected: _payType == PayType.wife,
                  onTap: () => setState(() => _payType = PayType.wife),
                ),
                const SizedBox(width: 10),
                _PayTypeChip(
                  label: '共同',
                  selected: _payType == PayType.shared,
                  onTap: () => setState(() => _payType = PayType.shared),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 日期
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, size: 20),
              title: Text(Utils.formatDate(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),

            // 备注
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: '添加备注（可选）',
                hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
              ),
            ),
            const SizedBox(height: 20),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6679EE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}

class _PayTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PayTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6679EE) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}