import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSentSuccess = false;

  void _onSendResetLink() async {
    final email = _emailController.text;

    if (email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ email của bạn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await AuthService().sendPasswordResetEmail(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isSentSuccess = true;
    });
  }

  Future<void> _openGmailApp() async {
    final Uri gmailUri = Uri.parse('https://mail.google.com');
    try {
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(gmailUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở ứng dụng Gmail. Vui lòng mở thủ công trong máy.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          child: Column(
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: isDark ? Colors.white : const Color(0xFF111827), size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(Icons.home,
                          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB), size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Khôi Phục Mật Khẩu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x330284C7) : Colors.white,
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
                      child: _isSentSuccess
                          ? _buildSuccessInstructionsView(isDark)
                          : _buildRequestFormView(isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestFormView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        // Title
        Text(
          'Quên mật khẩu?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00A8B5),
          ),
        ),
        const SizedBox(height: 12),
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Vui lòng nhập email đăng ký để nhận liên kết khôi phục mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF757575),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Email Input Field
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Địa chỉ Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF424242),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF212121),
          ),
          decoration: InputDecoration(
            hintText: 'example@gmail.com',
            hintStyle: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : const Color(0xFFBDBDBD),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                Icons.email_outlined,
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00A8B5),
                size: 24,
              ),
            ),
            filled: true,
            fillColor: isDark ? const Color(0x20000000) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.6) : const Color(0xFF00A8B5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00838F),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Send Button
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
              onPressed: _isLoading ? null : _onSendResetLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF0284C7) : const Color(0xFF00A8B5),
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
                      'Gửi yêu cầu khôi phục',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessInstructionsView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        // Big Success Mail Icon
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0284C7) : const Color(0xFF00A8B5),
            borderRadius: BorderRadius.circular(20),
            border: isDark ? Border.all(color: const Color(0xFF00E5FF), width: 1.5) : null,
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              const Center(
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00A8B5),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Success Title
        Text(
          'Đã gửi email thành công!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00A8B5),
          ),
        ),
        const SizedBox(height: 20),

        // Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x2010B981) : const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(20),
            border: isDark
                ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6))
                : null,
          ),
          child: Column(
            children: [
              Text(
                'Vui lòng kiểm tra hộp thư:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _emailController.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00695C),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lưu ý: Nếu không thấy email, vui lòng kiểm tra thư mục Spam hoặc Thư rác.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF558B2F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Open Email App Button (launches Gmail app directly)
        SizedBox(
          width: double.infinity,
          height: 50,
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
              onPressed: _openGmailApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF0284C7) : const Color(0xFF00A8B5),
                foregroundColor: Colors.white,
                elevation: 0,
                side: isDark
                    ? const BorderSide(color: Color(0xFF00E5FF), width: 1.5)
                    : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Mở ứng dụng Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Return to Login Link
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Quay lại Đăng nhập',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF00A8B5),
            ),
          ),
        ),
      ],
    );
  }
}
