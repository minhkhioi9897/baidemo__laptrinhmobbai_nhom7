import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  final String featureName;

  const PaymentScreen({
    super.key,
    required this.featureName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPaymentMethod = 0; // 0: VietQR / OCB, 1: Google Play Store
  bool _isProcessing = false;

  // Cấu hình thông tin ngân hàng OCB mới theo hình QR chính thức
  final String _bankId = 'OCB'; // Ngân hàng Phương Đông
  final String _accountNo = '0888320050';
  final String _accountName = 'NGUYEN MINH KHOI';
  final int _amount = 49000;

  String get _vietQrUrl {
    final addInfo = Uri.encodeComponent('VOICEHUB PRO ${_amount}k');
    return 'https://img.vietqr.io/image/$_bankId-$_accountNo-compact2.png?amount=$_amount&addInfo=$addInfo&accountName=${Uri.encodeComponent(_accountName)}';
  }

  Future<void> _processBankingPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final Uri qrUri = Uri.parse(_vietQrUrl);
    try {
      if (await canLaunchUrl(qrUri)) {
        await launchUrl(qrUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 2));

    await AuthService().upgradeToPro();

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    _showSuccessDialog();
  }

  Future<void> _processGooglePlayPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final Uri googlePlayUri = Uri.parse('https://play.google.com/store/account/subscriptions');
    try {
      if (await canLaunchUrl(googlePlayUri)) {
        await launchUrl(googlePlayUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 2));

    await AuthService().upgradeToPro();

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Nạp tiền thành công!'),
          ],
        ),
        content: const Text(
          'Chúc mừng bạn đã nâng cấp thành công gói PRO Vĩnh viễn. Tất cả tính năng nâng cao đã được kích hoạt!',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context, true); // Return to HomeScreen with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Bắt đầu trải nghiệm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF001024) : const Color(0xFFE2F4FE);
    final cardBgColor = isDark ? const Color(0xFF021B38) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.6) : const Color(0xFF38BDF8).withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nạp tiền nâng cấp PRO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Highlight Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0284C7), const Color(0xFF00E5FF)]
                        : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'GÓI PRO VĨNH VIỄN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '49.000đ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mở khóa toàn bộ tính năng cao cấp (${widget.featureName},...) không giới hạn.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Payment Method Section Title
              Text(
                'Chọn phương thức thanh toán:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),

              // Option 1: App Ngân Hàng OCB / VietQR
              _buildPaymentOption(
                index: 0,
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Ngân hàng OCB (VietQR / Napas 247)',
                subtitle: 'Quét mã QR chuyển khoản trực tiếp qua Ngân hàng OCB.',
                isDark: isDark,
                cardBgColor: cardBgColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 12),

              // Option 2: Google Play Billing
              _buildPaymentOption(
                index: 1,
                icon: Icons.shop_two_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Thanh toán qua Google Play Store',
                subtitle: 'Thanh toán qua ví MoMo, ZaloPay, Viettel Money hoặc Thẻ VISA.',
                isDark: isDark,
                cardBgColor: cardBgColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 28),

              // Details for selected payment
              if (_selectedPaymentMethod == 0) ...[
                // VietQR Code Details Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Quét mã QR OCB để thanh toán:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _vietQrUrl,
                          width: 240,
                          height: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 240,
                            height: 280,
                            color: isDark ? const Color(0xFF0A192F) : const Color(0xFFF1F5F9),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 48, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7)),
                                const SizedBox(height: 8),
                                Text(
                                  'Mã VietQR OCB - 49.000đ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ngân hàng:', style: TextStyle(color: subtitleColor, fontSize: 13)),
                          Text('OCB (Phương Đông)', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Số tài khoản:', style: TextStyle(color: subtitleColor, fontSize: 13)),
                          Text(_accountNo, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chủ tài khoản:', style: TextStyle(color: subtitleColor, fontSize: 13)),
                          Text(_accountName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Action Confirm Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : (_selectedPaymentMethod == 0
                          ? _processBankingPayment
                          : _processGooglePlayPayment),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_rounded, size: 20),
                  label: Text(
                    _isProcessing
                        ? 'ĐANG XÁC NHẬN GIAO DỊCH...'
                        : (_selectedPaymentMethod == 0
                            ? 'MỞ APP NGÂN HÀNG THANH TOÁN'
                            : 'THANH TOÁN QUA GOOGLE PLAY'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color cardBgColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final isSelected = _selectedPaymentMethod == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF10B981) : subtitleColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
