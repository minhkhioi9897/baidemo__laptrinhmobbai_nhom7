import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../home_view.dart';
import '../record_page.dart';
import '../services/auth_service.dart';
import 'binary_screen.dart';
import 'calculator_screen.dart';
import 'equation_screen.dart';
import 'journal_screen.dart';
import 'login_screen.dart';
import 'notes_screen.dart';
import 'payment_screen.dart';
import 'terms_dialog.dart';
import 'user_guide_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({
    super.key,
    this.userName = 'khoi',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Tự động hiển thị Hướng dẫn sử dụng nhanh ngay khi vào màn hình chính
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUserGuideDialog();
    });
  }

  void _showUserGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => UserGuideDialog(userName: widget.userName),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => const TermsDialog(),
    );
  }

  Future<void> _pickAvatarImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await AuthService().updateAvatar(pickedFile.path);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã đổi ảnh đại diện từ thư viện!',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi chọn ảnh đại diện: $e');
    }
  }

  void _showUpgradeProDialog({required String featureName, required VoidCallback onUnlocked}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF021B38) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF38BDF8),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nâng cấp PRO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tính năng "$featureName" chỉ dành cho thành viên PRO!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Chọn thanh toán qua App Ngân hàng (VietQR OCB) hoặc Cổng Google Play Billing để mở khóa vĩnh viễn.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x3300E5FF) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFF38BDF8),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gói Mở Khóa PRO:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '49.000đ / Vĩnh viễn',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Bỏ qua',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final bool? isPaymentSuccessful = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(featureName: featureName),
                ),
              );

              if (isPaymentSuccessful == true && mounted) {
                setState(() {});
                onUnlocked();
              }
            },
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: const Text('NẠP TIỀN NÂNG CẤP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = AuthService().isProUser;
    final customAvatarPath = AuthService().avatarPath;
    ImageProvider? avatarProvider;
    if (customAvatarPath != null && File(customAvatarPath).existsSync()) {
      avatarProvider = FileImage(File(customAvatarPath));
    }

    return HomeView(
      name: widget.userName,
      isPro: isPro,
      avatar: avatarProvider,
      onNotes: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotesScreen()),
      ),
      onCalc: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalculatorScreen()),
      ),
      onDiary: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const JournalScreen()),
      ),
      onEquation: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EquationScreen()),
      ),
      onBinary: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BinaryScreen()),
      ),
      onRecord: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RecordPage()),
      ),
      onTerms: _showTermsDialog,
      onLogout: () async {
        await AuthService().logout();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      onHelp: _showUserGuideDialog,
      onSettings: _pickAvatarImage,
      onProLocked: () {
        _showUpgradeProDialog(
          featureName: 'Tính năng PRO',
          onUnlocked: () {
            setState(() {});
          },
        );
      },
    );
  }
}
