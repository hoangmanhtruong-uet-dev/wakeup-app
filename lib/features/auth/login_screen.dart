import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/services/supabase_service.dart';
import '../home/presentation/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  int _state = 0; // 0: form, 1: loading, 2: success

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _skipToGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', true);
    } catch (e) {
      debugPrint('[WakeUp] Không thể lưu trạng thái khách: $e');
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) return;
    
    if (!isLogin) {
      if (password != _confirmController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu không khớp')));
        return;
      }
    }

    setState(() => _state = 1);
    
    try {
      if (isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      } else {
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuestMode', false);
      } catch (_) {}

      if (!mounted) return;
      setState(() => _state = 2);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = 0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  void _socialLogin(bool isGoogle) async {
    try {
      if (isGoogle) {
        await SupabaseService.signInWithGoogle();
      } else {
        await SupabaseService.signInWithApple();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thanh điều hướng trên cùng với nút Bỏ qua
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _skipToGuest,
                    icon: const Icon(Icons.arrow_forward, size: 18, color: AppTheme.primary),
                    label: const Text(
                      'Bỏ qua',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))
                  ]
                ),
                child: const Icon(Icons.alarm, color: AppTheme.primary, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('WakeUp+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Đánh thức năng lượng mỗi ngày', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 32),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = true),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isLogin ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          child: Text('Đăng nhập', style: TextStyle(color: isLogin ? Colors.black : AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isLogin = false),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: !isLogin ? AppTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          child: Text('Đăng ký', style: TextStyle(color: !isLogin ? Colors.black : AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Morphing area
              SizedBox(
                height: isLogin ? 310 : 420,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    width: _state == 0 ? MediaQuery.of(context).size.width : (_state == 1 ? 64 : 80),
                    height: _state == 0 ? (isLogin ? 310 : 420) : (_state == 1 ? 64 : 80),
                    decoration: BoxDecoration(
                      color: _state == 0 ? Colors.transparent : (_state == 1 ? AppTheme.primary : Colors.green),
                      borderRadius: BorderRadius.circular(_state == 0 ? 0 : 40),
                    ),
                    child: _state == 0 
                      ? _buildForm() 
                      : (_state == 1 
                        ? const Center(child: CircularProgressIndicator(color: Colors.black))
                        : const Center(child: Icon(Icons.check, color: Colors.white, size: 40))),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.borderLight)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Hoặc tiếp tục với', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  Expanded(child: Divider(color: AppTheme.borderLight)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialBtn(Icons.g_mobiledata),
                  _buildSocialBtn(Icons.apple),
                  _buildSocialBtn(Icons.facebook),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _skipToGuest,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 20, color: AppTheme.textMuted),
                      SizedBox(width: 8),
                      Text(
                        'Tiếp tục với tư cách Khách',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildInput('Email hoặc Số điện thoại', Icons.email, false, _emailController),
        const SizedBox(height: 16),
        _buildInput('Mật khẩu', Icons.lock, true, _passwordController),
        if (!isLogin) ...[
          const SizedBox(height: 16),
          _buildInput('Nhập lại mật khẩu', Icons.lock_outline, true, _confirmController),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _submit,
            child: Text(isLogin ? 'Đăng nhập' : 'Tạo tài khoản', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildInput(String label, IconData icon, bool isPassword, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialBtn(IconData icon) {
    return InkWell(
      onTap: () => _socialLogin(icon == Icons.g_mobiledata),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 28),
      ),
    );
  }
}
