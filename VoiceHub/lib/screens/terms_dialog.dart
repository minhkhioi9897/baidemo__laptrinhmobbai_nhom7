import 'package:flutter/material.dart';

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

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
            child: Icon(Icons.gavel_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Điều khoản & Dịch vụ',
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
              _buildSection(
                title: '1. Quyền riêng tư & Bảo mật dữ liệu',
                content:
                    'VoiceHub cam kết bảo vệ thông tin cá nhân và dữ liệu ghi âm của bạn. Mọi bản ghi âm và nhật ký cá nhân được lưu trữ an toàn trên thiết bị của bạn và cơ sở dữ liệu mã hóa.',
                textColor: textColor,
                subColor: subColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: '2. Quyền truy cập Micro & Thư viện',
                content:
                    'Ứng dụng chỉ sử dụng Micro khi bạn thực hiện các tính năng ghi âm hoặc ra lệnh bằng giọng nói. Quyền truy cập thư viện ảnh chỉ dùng khi bạn thay đổi ảnh đại diện cá nhân.',
                textColor: textColor,
                subColor: subColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: '3. Quyền sở hữu nội dung',
                content:
                    'Bạn sở hữu toàn bộ các file ghi âm, ghi chú và nhật ký tạo ra trên VoiceHub. Bạn có quyền xuất hoặc xóa toàn bộ dữ liệu bất kỳ lúc nào.',
                textColor: textColor,
                subColor: subColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: '4. Dịch vụ Nâng cấp PRO',
                content:
                    'Gói PRO được mở khóa vĩnh viễn sau khi hoàn tất thanh toán. Dịch vụ hỗ trợ giải phương trình và chuyển đổi hệ cơ số nhị phân không giới hạn.',
                textColor: textColor,
                subColor: subColor,
                primaryColor: primaryColor,
              ),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tôi đã hiểu & Đồng ý',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color subColor,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: subColor,
          ),
        ),
      ],
    );
  }
}
