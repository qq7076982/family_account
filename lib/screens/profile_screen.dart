import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../services/cloudbase_service.dart';
import '../models/bill.dart';
import '../models/user.dart';
import '../utils/utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(builder: (context, auth, _) {
        final user = auth.user;
        final isHusband = user?.gender == Gender.husband;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 成员卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6679EE), Color(0xFF8B9EFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        isHusband ? '👨' : '👩',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHusband ? '老公' : '老婆',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditNameDialog(context, user?.name ?? ''),
                    icon: const Icon(Icons.edit, color: Color(0xFF6679EE)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 账本信息
            if (user?.familyId != null)
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
                      '账本信息',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _ProfileItem(
                      icon: Icons.book,
                      label: '家庭账本 ID',
                      value: user!.familyId!.substring(0, 8),
                      copyable: true,
                    ),
                    const Divider(),
                    _ProfileItem(
                      icon: Icons.share,
                      label: '邀请码',
                      value: user.familyId!,
                      copyable: true,
                      subtitle: '分享给另一半加入账本',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 数据管理
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
                    '数据管理',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download, color: Color(0xFF6679EE)),
                    title: const Text('导出账单 (Excel)'),
                    subtitle: const Text('导出所有账单记录', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportData(context),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category, color: Color(0xFF6679EE)),
                    title: const Text('管理分类'),
                    subtitle: const Text('添加、修改支出收入分类', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCategoryManager(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 安全
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
                    '安全与隐私',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.lock, color: Color(0xFF6679EE)),
                    title: Text('数据加密'),
                    subtitle: Text('所有数据仅夫妻双方可见', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                    title: const Text('退出登录', style: TextStyle(color: Color(0xFFFF6B6B))),
                    onTap: () => _showSignOutDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 版本信息
            const Center(
              child: Text(
                '家账小记 v1.0.0\n夫妻共同记账工具',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
              ),
            ),

            const SizedBox(height: 100),
          ],
        );
      }),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6679EE),
            ),
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final cs = await CloudBaseService.getInstance();
    final rawBills = await cs.getAllBills(auth.user!.familyId!);

    final rows = <List<String>>[
      ['日期', '类型', '分类', '金额', '付款人', '备注'],
    ];
    for (final raw in rawBills) {
      final bill = Bill.fromMap(Map<String, dynamic>.from(raw), raw['_id'] ?? '');
      rows.add([
        Utils.formatDate(bill.date),
        bill.type == BillType.expense ? '支出' : '收入',
        bill.category,
        bill.amount.toString(),
        bill.payType == PayType.husband
            ? '老公'
            : bill.payType == PayType.wife
                ? '老婆'
                : '共同',
        bill.note ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/家账小记_export.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: '家账小记账单导出');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出 ${rawBills.length} 条记录')),
      );
    }
  }

  void _showCategoryManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CategoryManagerSheet(),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
            ),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final String? subtitle;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF6679EE)),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: copyable
          ? IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制')),
                );
              },
            )
          : null,
    );
  }
}

class CategoryManagerSheet extends StatefulWidget {
  const CategoryManagerSheet({super.key});

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('管理分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add, color: Color(0xFF6679EE)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BillProvider>(builder: (context, bp, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text('支出分类', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  const SizedBox(height: 8),
                  ...bp.expenseCategories.map((c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(c.icon, style: const TextStyle(fontSize: 20)),
                        title: Text(c.name),
                        trailing: c.isDefault
                            ? const Text('默认', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
                                onPressed: () {},
                              ),
                      )),
                  const SizedBox(height: 16),
                  const Text('收入分类', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                  const SizedBox(height: 8),
                  ...bp.incomeCategories.map((c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text(c.icon, style: const TextStyle(fontSize: 20)),
                        title: Text(c.name),
                        trailing: c.isDefault
                            ? const Text('默认', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))
                            : IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
                                onPressed: () {},
                              ),
                      )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String icon = '📦';
    bool isExpense = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新增分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: '分类名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('图标: '),
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final icons = ['🍜', '🏠', '🚗', '🛒', '🎁', '💊', '👶', '🎮', '💰', '🧧', '📦'];
                      setState(() => icon = icons[(icons.indexOf(icon) + 1) % icons.length]);
                    },
                    child: const Text('换图标'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('类型: '),
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: isExpense,
                    onSelected: (v) => setState(() => isExpense = v),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('收入'),
                    selected: !isExpense,
                    onSelected: (v) => setState(() => isExpense = !v),
                  ),
                ],
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
                if (nameController.text.isNotEmpty) {
                  final auth = context.read<AuthProvider>();
                  await context.read<BillProvider>().addCategory(
                        auth.user!.familyId!,
                        nameController.text,
                        icon,
                        isExpense,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6679EE),
              ),
              child: const Text('添加', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}