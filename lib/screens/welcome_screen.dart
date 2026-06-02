import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _familyNameController = TextEditingController(text: '我们的家');
  final _nameController = TextEditingController();
  final _joinCodeController = TextEditingController();

  Gender _gender = Gender.husband;
  bool _isJoining = false;
  bool _loading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _familyNameController.dispose();
    _nameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EEFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Logo mark
                  _buildLogo(),
                  const SizedBox(height: 24),

                  // App name
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ).createShader(bounds),
                    child: const Text(
                      '家账小记',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '夫妻共同记账，让财务更透明',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tab switcher
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _buildTabSwitcher(),
                  ),

                  const SizedBox(height: 24),

                  // Form card
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isJoining ? _buildJoinForm() : _buildCreateForm(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.r(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '💰',
          style: TextStyle(fontSize: 44),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.fullR,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              label: '创建账本',
              selected: !_isJoining,
              onTap: () => setState(() => _isJoining = false),
            ),
          ),
          Expanded(
            child: _TabItem(
              label: '加入账本',
              selected: _isJoining,
              onTap: () => setState(() => _isJoining = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Column(
      key: const ValueKey('create'),
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(label: '账本名称'),
              const SizedBox(height: 10),
              TextField(
                controller: _familyNameController,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: '给你们的账本起个名字',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('📒', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: '你的昵称'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: '对方怎么称呼你',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('✏️', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: '你的身份'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      emoji: '👨',
                      label: '老公',
                      selected: _gender == Gender.husband,
                      onTap: () => setState(() => _gender = Gender.husband),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderCard(
                      emoji: '👩',
                      label: '老婆',
                      selected: _gender == Gender.wife,
                      onTap: () => setState(() => _gender = Gender.wife),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _createFamily,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('创建账本 →'),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildJoinForm() {
    return Column(
      key: const ValueKey('join'),
      children: [
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(label: '账本邀请码'),
              const SizedBox(height: 10),
              TextField(
                controller: _joinCodeController,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: '输入账本 ID（向另一半索取）',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('🔑', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: '你的昵称'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: '对方怎么称呼你',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('✏️', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: '你的身份'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      emoji: '👨',
                      label: '老公',
                      selected: _gender == Gender.husband,
                      onTap: () => setState(() => _gender = Gender.husband),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderCard(
                      emoji: '👩',
                      label: '老婆',
                      selected: _gender == Gender.wife,
                      onTap: () => setState(() => _gender = Gender.wife),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _joinFamily,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('加入账本 →'),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _createFamily() async {
    if (_nameController.text.isEmpty) {
      _showError('请输入你的昵称');
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    await auth.createFamilyAndJoin(
      _familyNameController.text,
      _nameController.text,
      _gender == Gender.husband ? 'husband' : 'wife',
    );
    setState(() => _loading = false);
  }

  Future<void> _joinFamily() async {
    if (_joinCodeController.text.isEmpty || _nameController.text.isEmpty) {
      _showError('请填写完整信息');
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    await auth.joinFamily(
      _joinCodeController.text,
      _nameController.text,
      _gender == Gender.husband ? 'husband' : 'wife',
    );
    setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.expense,
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.fullR,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: AppRadius.xlR,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.label,
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surfaceLight,
          borderRadius: AppRadius.mdR,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}