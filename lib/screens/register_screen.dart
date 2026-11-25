import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _onRegister() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _isLoading = true;
    });

    final error = await AuthService().register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đăng ký thành công! Vui lòng đăng nhập.'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.pop(context);
  }

  Widget _buildRuleItem({required String text, required bool isValid, required bool isDark}) {
    final activeTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final inactiveTextColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isValid
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isValid ? FontWeight.bold : FontWeight.w500,
                color: isValid ? activeTextColor : inactiveTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final passwordText = _passwordController.text;

    final hasMinLength = passwordText.length >= 6;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(passwordText);
    final hasNumber = RegExp(r'[0-9]').hasMatch(passwordText);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(passwordText);

    final boxBgColor = isDark ? const Color(0x550284C7) : const Color(0xFFF1F5F9);
    final boxBorderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.6) : const Color(0xFFCBD5E1);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF031024),
                    Color(0xFF020817),
                    Color(0xFF01040D),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFFF3F4F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x330284C7)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00E5FF).withValues(alpha: 0.8)
                        : Colors.transparent,
                    width: isDark ? 1.8 : 0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.25)
                          : const Color(0xFF2563EB).withValues(alpha: 0.08),
                      blurRadius: isDark ? 25 : 30,
                      spreadRadius: isDark ? 2 : 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      'Tạo tài khoản mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      'Nhanh chóng & hoàn toàn miễn phí',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Full Name Field
                    CustomTextField(
                      label: 'Họ và tên',
                      hintText: 'Nguyễn Văn A',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    // Email Field
                    CustomTextField(
                      label: 'Email',
                      hintText: 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    CustomTextField(
                      label: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu an toàn',
                      isPassword: true,
                      controller: _passwordController,
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),

                    // High Contrast Password Guidelines Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: boxBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: boxBorderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Yêu cầu mật khẩu an toàn:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildRuleItem(
                            text: 'Có ít nhất 6 ký tự',
                            isValid: hasMinLength,
                            isDark: isDark,
                          ),
                          _buildRuleItem(
                            text: 'Có ít nhất 1 chữ cái in hoa (A-Z)',
                            isValid: hasUppercase,
                            isDark: isDark,
                          ),
                          _buildRuleItem(
                            text: 'Có ít nhất 1 chữ số (0-9)',
                            isValid: hasNumber,
                            isDark: isDark,
                          ),
                          _buildRuleItem(
                            text: 'Có ít nhất 1 ký tự đặc biệt (!@#\$%^&*...)',
                            isValid: hasSpecialChar,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    CustomTextField(
                      label: 'Nhập lại mật khẩu',
                      hintText: '••••••••',
                      isPassword: true,
                      controller: _confirmPasswordController,
                    ),
                    const SizedBox(height: 28),
                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: isDark
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              )
                            : null,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            side: isDark
                                ? const BorderSide(color: Color(0xFF00E5FF), width: 1.5)
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Đăng ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
