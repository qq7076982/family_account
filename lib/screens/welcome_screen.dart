import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _familyNameController = TextEditingController(text: '家庭账本');
  final _nameController = TextEditingController();
  Gender _gender = Gender.husband;
  bool _isJoining = false;
  final _joinCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6679EE), Color(0xFF8B9EFF)],
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
                child: const Center(
                  child: Text('💰', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '家账小记',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '夫妻共同记账，财务透明更轻松',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 40),

              // Tab: 创建/加入
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isJoining = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isJoining
                                ? const Color(0xFF6679EE)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '创建账本',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: !_isJoining ? Colors.white : const Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isJoining = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isJoining
                                ? const Color(0xFF6679EE)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '加入账本',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isJoining ? Colors.white : const Color(0xFF999999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!_isJoining) ...[
                // 创建账本表单
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '账本名称',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _familyNameController,
                        decoration: InputDecoration(
                          hintText: '给你们的账本起个名字',
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
                      const Text(
                        '你的昵称',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '对方怎么称呼你',
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
                      const Text(
                        '你的身份',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _GenderOption(
                              label: '老公 👨',
                              selected: _gender == Gender.husband,
                              onTap: () => setState(() => _gender = Gender.husband),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GenderOption(
                              label: '老婆 👩',
                              selected: _gender == Gender.wife,
                              onTap: () => setState(() => _gender = Gender.wife),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createFamily,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6679EE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '创建账本',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 加入账本表单
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '账本邀请码',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _joinCodeController,
                        decoration: InputDecoration(
                          hintText: '输入账本 ID（向另一半索取）',
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
                      const Text(
                        '你的昵称',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '对方怎么称呼你',
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
                      const Text(
                        '你的身份',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _GenderOption(
                              label: '老公 👨',
                              selected: _gender == Gender.husband,
                              onTap: () => setState(() => _gender = Gender.husband),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GenderOption(
                              label: '老婆 👩',
                              selected: _gender == Gender.wife,
                              onTap: () => setState(() => _gender = Gender.wife),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _joinFamily,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6679EE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '加入账本',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入你的昵称')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    await auth.createFamilyAndJoin(
      _familyNameController.text,
      _nameController.text,
      _gender == Gender.husband ? 'husband' : 'wife',
    );
  }

  Future<void> _joinFamily() async {
    if (_joinCodeController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整信息')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    await auth.joinFamily(
      _joinCodeController.text,
      _nameController.text,
      _gender == Gender.husband ? 'husband' : 'wife',
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6679EE) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }
}