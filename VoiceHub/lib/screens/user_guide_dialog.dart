import 'package:flutter/material.dart';

class UserGuideDialog extends StatelessWidget {
  final String userName;

  const UserGuideDialog({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF021B38) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final primaryColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF0088ED);

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.8) : const Color(0xFF38BDF8),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore_rounded, color: primaryColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chào mừng $userName!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hướng dẫn sử dụng nhanh các tính năng trên VoiceHub:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 14),

              _buildGuideStep(
                icon: Icons.mic_rounded,
                title: '1. Ghi âm',
                desc: 'Bấm nút micro đỏ để bắt đầu ghi âm chất lượng cao 44.1 kHz không nén. Vòng sáng sẽ co giãn mượt mượt theo âm lượng giọng nói.',
                primaryColor: primaryColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildGuideStep(
                icon: Icons.article_rounded,
                title: '2. Ghi chú & Quản lý',
                desc: 'Tạo, lưu trữ và tìm kiếm các ghi chú nhanh chóng. Bạn có thể vuốt hoặc bấm icon thùng rác để xóa ghi chú.',
                primaryColor: primaryColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildGuideStep(
                icon: Icons.calculate_rounded,
                title: '3. Máy tính bằng Giọng nói',
                desc: 'Nhấn mic và nói biểu thức toán học (ví dụ: "năm cộng mười ba") để máy tính tự tính kết quả tức thì.',
                primaryColor: primaryColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildGuideStep(
                icon: Icons.photo_camera_rounded,
                title: '4. Đổi Ảnh đại diện',
                desc: 'Bấm thẳng vào hình tròn Avatar góc trên bên phải màn hình chính để chọn ảnh từ thư viện điện thoại của bạn.',
                primaryColor: primaryColor,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(height: 12),

              _buildGuideStep(
                icon: Icons.workspace_premium_rounded,
                title: '5. Tính năng PRO',
                desc: 'Nâng cấp gói PRO để mở khóa công cụ Giải phương trình bậc 1-3 và Chuyển đổi hệ nhị phân vĩnh viễn qua VietQR OCB.',
                primaryColor: const Color(0xFFF59E0B),
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Bắt đầu sử dụng VoiceHub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep({
    required IconData icon,
    required String title,
    required String desc,
    required Color primaryColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: subColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
