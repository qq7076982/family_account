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
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '我的',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(builder: (context, auth, _) {
        final user = auth.user;
        final isHusband = user?.gender == Gender.husband;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // Profile card
            _ProfileCard(
              user: user,
              isHusband: isHusband,
              onEditName: () => _showEditNameDialog(context, user?.name ?? ''),
            ),

            const SizedBox(height: 16),

            // Account info
            if (user?.familyId != null) ...[
              _AccountInfoCard(user: user!),
              const SizedBox(height: 16),
            ],

            // Data management
            _DataManagementCard(
              onExport: () => _exportData(context),
              onManageCategories: () => _showCategoryManager(context),
            ),

            const SizedBox(height: 16),

            // Security
            _SecurityCard(
              onSignOut: () => _showSignOutDialog(context),
            ),

            const SizedBox(height: 32),

            // Version info
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: AppRadius.mdR,
                    ),
                    child: const Center(
                      child: Text('💰', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '家账小记',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v1.0.0 · 夫妻共同记账工具',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
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

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入昵称',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdR,
              ),
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

    if (rawBills.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('暂无账单可导出'),
            backgroundColor: AppColors.textTertiary,
          ),
        );
      }
      return;
    }

    final rows = <List<String>>[
      ['日期', '类型', '分类', '金额', '付款人', '备注'],
    ];
    for (final raw in rawBills) {
      final bill = Bill.fromMap(
        Map<String, dynamic>.from(raw),
        raw['_id']?.toString() ?? '',
      );
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
    final file = File('${dir.path}/family_account_export.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: '家账小记账单导出',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导出 ${rawBills.length} 条记录'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  void _showCategoryManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CategoryManagerSheet(),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
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
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdR,
              ),
            ),
            child: const Text('确定', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final AppUser? user;
  final bool isHusband;
  final VoidCallback onEditName;

  const _ProfileCard({
    required this.user,
    required this.isHusband,
    required this.onEditName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.xlR,
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.lgR,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isHusband ? '👨' : '👩',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '未设置',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isHusband
                            ? const Color(0xFF6679EE)
                            : const Color(0xFFFF7F50))
                        .withValues(alpha: 0.1),
                    borderRadius: AppRadius.fullR,
                  ),
                  child: Text(
                    isHusband ? '👨 老公' : '👩 老婆',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isHusband
                          ? const Color(0xFF6679EE)
                          : const Color(0xFFFF7F50),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditName,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppRadius.smR,
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final AppUser user;

  const _AccountInfoCard({required this.user});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('📒', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                '账本信息',
                style: AppTextStyles.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: '账本 ID',
            value: user.familyId!.length > 12
                ? '${user.familyId!.substring(0, 8)}...'
                : user.familyId!,
            copyable: true,
            onCopy: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制账本 ID'),
                  backgroundColor: AppColors.income,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: '邀请码',
            value: user.familyId!,
            copyable: true,
            subtitle: '分享给另一半加入账本',
            onCopy: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已复制邀请码'),
                  backgroundColor: AppColors.income,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final String? subtitle;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.subtitle,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (copyable && onCopy != null)
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onManageCategories;

  const _DataManagementCard({
    required this.onExport,
    required this.onManageCategories,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('📦', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                '数据管理',
                style: AppTextStyles.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: '📊',
            label: '导出账单',
            subtitle: '导出为 Excel 表格',
            onTap: onExport,
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: '🏷️',
            label: '管理分类',
            subtitle: '添加、修改支出收入分类',
            onTap: onManageCategories,
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SecurityCard({required this.onSignOut});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🔒', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                '安全与隐私',
                style: AppTextStyles.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.06),
              borderRadius: AppRadius.mdR,
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.income,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '所有数据仅夫妻双方可见，全程加密保护',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: '🚪',
            label: '退出登录',
            subtitle: '退出当前账户',
            isDestructive: true,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.expense : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Category Manager Sheet =====
class _CategoryManagerSheet extends StatefulWidget {
  const _CategoryManagerSheet();

  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,
              borderRadius: AppRadius.r(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('🏷️ ', style: TextStyle(fontSize: 20)),
                const Text(
                  '管理分类',
                  style: AppTextStyles.screenTitle,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showAddCategoryDialog(context),
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smR,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<BillProvider>(builder: (context, bp, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Text(
                    '💸 支出分类',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...bp.expenseCategories.map((c) => _CategoryTile(
                        icon: c.icon,
                        name: c.name,
                        isDefault: c.isDefault,
                      )),
                  const SizedBox(height: 20),
                  const Text(
                    '💰 收入分类',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...bp.incomeCategories.map((c) => _CategoryTile(
                        icon: c.icon,
                        name: c.name,
                        isDefault: c.isDefault,
                      )),
                  const SizedBox(height: 40),
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
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
          title: const Text('新增分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: '分类名称',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('图标: '),
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      final icons = ['🍜', '🏠', '🚗', '🛒', '🎁', '💊', '👶', '🎮', '💰', '🧧', '📦'];
                      setState(() {
                        final idx = (icons.indexOf(icon) + 1) % icons.length;
                        icon = icons[idx];
                      });
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
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdR,
                ),
              ),
              child: const Text('添加', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String icon;
  final String name;
  final bool isDefault;

  const _CategoryTile({
    required this.icon,
    required this.name,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.mdR,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textDisabled.withValues(alpha: 0.2),
                  borderRadius: AppRadius.fullR,
                ),
                child: const Text(
                  '默认',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}