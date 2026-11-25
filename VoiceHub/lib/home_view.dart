import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'fx.dart';

/// Chỉ lo GIAO DIỆN. Mọi chức năng cũ của bạn truyền vào qua các hàm onXxx,
/// nên logic (đăng nhập, PRO, mở trang...) giữ nguyên, không phải viết lại.
class HomeView extends StatelessWidget {
  final String name;
  final bool isPro;
  final ImageProvider? avatar;
  final VoidCallback onNotes, onCalc, onDiary, onEquation, onBinary, onRecord;
  final VoidCallback onTerms, onLogout, onHelp, onSettings;
  final VoidCallback? onProLocked; // gọi khi chưa PRO mà bấm ô PRO

  const HomeView({
    super.key,
    required this.name,
    required this.isPro,
    this.avatar,
    required this.onNotes,
    required this.onCalc,
    required this.onDiary,
    required this.onEquation,
    required this.onBinary,
    required this.onRecord,
    required this.onTerms,
    required this.onLogout,
    required this.onHelp,
    required this.onSettings,
    this.onProLocked,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<VoiceColors>()!;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // nền sáng: làm đậm màu biểu tượng cho nổi trên thẻ trắng
    Color dk(Color x) {
      if (dark) return x;
      final h = HSLColor.fromColor(x);
      return h.withLightness((h.lightness - .12).clamp(0.0, 1.0)).toColor();
    }
    Widget gi(Widget child, Color a, Color b) => _gradIcon(child, dk(a), dk(b));

    VoidCallback guard(bool pro, VoidCallback go) =>
        (pro && !isPro) ? (onProLocked ?? () {}) : go;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // chữ/biểu tượng thanh trạng thái tự đổi đen/trắng theo nền
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
      child: Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.bg1, c.bg2, c.bg3],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _WavePainter(c, dark))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 16),
              _Header(c: c, name: name, isPro: isPro, avatar: avatar, onHelp: onHelp, onSettings: onSettings),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  padding: EdgeInsets.zero,
                  children: [
                    _Tile(index: 0, c: c, title: 'Ghi chú', sub: 'Tạo & lưu trữ', onTap: onNotes,
                        edge: const Color(0xFF38BDF8),
                        icon: gi(const Icon(Icons.description_rounded, size: 46, color: Colors.white),
                            const Color(0xFF38BDF8), const Color(0xFF2563EB))),
                    _Tile(index: 1, c: c, title: 'Tính toán', sub: 'Máy tính thông minh', onTap: onCalc,
                        edge: const Color(0xFF60A5FA),
                        icon: gi(const Icon(Icons.calculate_rounded, size: 46, color: Colors.white),
                            const Color(0xFF60A5FA), const Color(0xFF3B82F6))),
                    _Tile(index: 2, c: c, title: 'Nhật ký', sub: 'Ghi chép cảm xúc', onTap: onDiary,
                        edge: const Color(0xFF818CF8),
                        icon: gi(const Icon(Icons.menu_book_rounded, size: 46, color: Colors.white),
                            const Color(0xFF818CF8), const Color(0xFF6366F1))),
                    _Tile(index: 3, c: c, title: 'Phương trình', sub: 'Bậc 1 đến bậc 3', pro: true,
                        onTap: guard(true, onEquation), edge: const Color(0xFFA78BFA),
                        icon: gi(
                            const Text('f(x)', style: TextStyle(fontSize: 34, fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600, color: Colors.white)),
                            const Color(0xFFA78BFA), const Color(0xFF7C3AED))),
                    _Tile(index: 4, c: c, title: 'Nhị phân', sub: 'Chuyển hệ số', pro: true,
                        onTap: guard(true, onBinary), edge: const Color(0xFF22D3EE),
                        icon: gi(
                            const Text('01\n10', style: TextStyle(fontSize: 22, height: 1.0,
                                fontWeight: FontWeight.w800, color: Colors.white)),
                            const Color(0xFF22D3EE), const Color(0xFF38BDF8))),
                    _Tile(index: 5, c: c, title: 'Ghi âm', sub: 'Giọng thực WAV', onTap: onRecord,
                        edge: const Color(0xFF818CF8),
                        icon: gi(const Icon(Icons.mic_rounded, size: 46, color: Colors.white),
                            const Color(0xFF818CF8), const Color(0xFFA78BFA))),
                  ],
                ),
              ),
              _Footer(c: c, dark: dark, isPro: isPro, onTerms: onTerms, onLogout: onLogout),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ]),
    ));
  }
}

Widget _gradIcon(Widget child, Color a, Color b) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight)
          .createShader(r),
      child: child,
    );

// ------------------------------------------------------------ Header
class _Header extends StatelessWidget {
  final VoiceColors c;
  final String name;
  final bool isPro;
  final ImageProvider? avatar;
  final VoidCallback onHelp, onSettings;
  const _Header({required this.c, required this.name, required this.isPro, required this.avatar,
      required this.onHelp, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      FxOrb(
        size: 68,
        color: c.accent,
        child: Container(
        width: 68, height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [c.orbA, c.orbB]),
          border: Border.all(color: c.accent.withAlpha(150), width: 1.5),
          boxShadow: [BoxShadow(color: c.accent.withAlpha(80), blurRadius: 22)],
        ),
        child: Icon(Icons.mic_rounded, size: 34, color: c.orbIcon),
      )),
      Container(width: 1, height: 70, margin: const EdgeInsets.symmetric(horizontal: 12), color: c.sub.withAlpha(90)),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.chipBg, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.chipBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isPro) Icon(Icons.workspace_premium_rounded, size: 16, color: c.gold),
              if (isPro) const SizedBox(width: 4),
              Text(isPro ? 'Thành viên PRO' : 'Thành viên',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.chipText)),
            ]),
          ),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: c.text, height: 1.15)),
          FittedBox(
            fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text('Voice Hub  ·  Smart & Powerful', style: TextStyle(fontSize: 12.5, color: c.sub)),
          ),
        ]),
      ),
      FxPress(
        onTap: onHelp,
        radius: BorderRadius.circular(19),
        burstColor: c.accent,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.helpBg, border: Border.all(color: c.sub, width: 1.5)),
          child: Icon(Icons.question_mark_rounded, size: 20, color: c.sub),
        ),
      ),
      const SizedBox(width: 10),
      FxPress(
        onTap: onSettings,
        burst: false,
        child: Stack(clipBehavior: Clip.none, children: [

          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.gold, width: 2)),
            child: CircleAvatar(
              radius: 24, backgroundImage: avatar,
              backgroundColor: c.accent.withAlpha(60),
              child: avatar == null
                  ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text))
                  : null,
            ),
          ),
          Positioned(
            right: -3, bottom: -3,
            child: Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2B3A66)),
              child: const Icon(Icons.settings_rounded, size: 13, color: Colors.white),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ------------------------------------------------------------ Tile
class _Tile extends StatelessWidget {
  final VoiceColors c;
  final String title, sub;
  final Widget icon;
  final bool pro;
  final VoidCallback onTap;
  final Color edge;
  final int index;
  const _Tile({required this.c, required this.title, required this.sub, required this.icon,
      required this.onTap, required this.edge, this.pro = false, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(26);
    return FxEntrance(
      index: index,
      child: FxPress.builder(
      onTap: onTap,
      radius: r,
      burstColor: edge,
      builder: (context, press) => Container(
        decoration: BoxDecoration(borderRadius: r, boxShadow: [BoxShadow(color: c.useEdge ? edge.withAlpha(40) : c.cardShadow, blurRadius: 18, offset: Offset(0, c.useEdge ? 0 : 8))]),
        child: ClipRRect(
          borderRadius: r,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [c.cardTop, c.cardBottom]),
                border: Border.all(color: c.useEdge ? edge.withAlpha(150) : c.cardBorder, width: 1.4),
              ),
              child: Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: 50, child: Align(alignment: Alignment.centerLeft,
                          child: Transform.scale(scale: 1 + .16 * press, alignment: Alignment.centerLeft, child: icon))),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                                    child: Text(title, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: c.text))),
                                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.5, color: c.sub)),
                              ]),
                        ),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: c.text.withAlpha(22),
                            border: Border.all(color: c.text.withAlpha(50)),
                          ),
                          child: Transform.translate(offset: Offset(5 * press, 0),
                              child: Icon(Icons.chevron_right_rounded, size: 20, color: c.text)),
                        ),
                      ]),
                    ]),
                if (pro)
                  Positioned(
                    top: 0, right: 0,
                    child: FxShimmer(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [Color(0xFFFFE19A), Color(0xFFF5B544)]),
                        boxShadow: [BoxShadow(color: c.gold.withAlpha(90), blurRadius: 10)],
                      ),
                      child: const Text('PRO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic, color: Color(0xFF3B2A00))),
                    )),
                  ),
              ]),
            ),
          ),
        ),
      ),
    ));
  }
}

// ------------------------------------------------------------ Footer
class _Footer extends StatelessWidget {
  final VoiceColors c;
  final bool dark, isPro;
  final VoidCallback onTerms, onLogout;
  const _Footer({required this.c, required this.dark, required this.isPro, required this.onTerms, required this.onLogout});

  Widget _seg(IconData i, String t, Color col, {VoidCallback? onTap, Widget? lead}) => Expanded(
        child: FxPress(
          onTap: onTap,
          scale: .9,
          burstColor: col,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                lead ?? Icon(i, size: 20, color: col),
                const SizedBox(width: 6),
                Text(t, style: TextStyle(fontSize: 13, color: col, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      );

  Widget _div() => Container(width: 1, height: 28, color: c.sub.withAlpha(70));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 58,
      decoration: BoxDecoration(
        color: c.bar, borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.text.withAlpha(24)),
      ),
      child: Row(children: [
        // Nút chế độ: Theo điện thoại -> Sáng -> Tối -> (quay lại) Theo điện thoại
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (_, m, child) => IconButton(
            tooltip: m == ThemeMode.system ? 'Theo điện thoại' : (m == ThemeMode.light ? 'Chế độ sáng' : 'Chế độ tối'),
            onPressed: () => themeMode.value =
                m == ThemeMode.system ? ThemeMode.light : (m == ThemeMode.light ? ThemeMode.dark : ThemeMode.system),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (w, a) => RotationTransition(
                  turns: Tween(begin: .75, end: 1.0).animate(a), child: ScaleTransition(scale: a, child: w)),
              child: Icon(
                m == ThemeMode.system
                    ? Icons.brightness_auto_rounded
                    : (m == ThemeMode.light ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                key: ValueKey(m),
                color: c.accent,
              ),
            ),
          ),
        ),
        _div(),
        _seg(Icons.stars_rounded, isPro ? 'Đã kích hoạt' : 'Chưa kích hoạt', c.activeText,
            lead: c.starCircle
                ? Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.starBg),
                    child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                  )
                : null),
        _div(),
        _seg(Icons.description_outlined, 'Điều khoản', c.text, onTap: onTerms),
        _div(),
        _seg(Icons.logout_rounded, 'Đăng xuất', c.danger, onTap: onLogout),
      ]),
    );
  }
}

// ------------------------------------------------------------ Nền sóng
class _WavePainter extends CustomPainter {
  final VoiceColors c;
  final bool dark;
  _WavePainter(this.c, this.dark);

  @override
  void paint(Canvas canvas, Size s) {
    // quầng sáng mờ góc trên trái
    final glow = Rect.fromCircle(center: Offset(s.width * .15, s.height * .12), radius: 190);
    canvas.drawCircle(glow.center, 190,
        Paint()..shader = RadialGradient(colors: [c.waveB.withAlpha(dark ? 70 : 60), Colors.transparent]).createShader(glow));

    void wave(Path p, double w, int a, double blur) {
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..shader = LinearGradient(colors: [c.waveA.withAlpha(a), c.waveB.withAlpha(a)])
              .createShader(Offset.zero & s)
          ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null,
      );
    }

    final top = Path()
      ..moveTo(s.width * .22, s.height * .21)
      ..cubicTo(s.width * .55, s.height * .26, s.width * .72, s.height * .05, s.width * 1.02, s.height * .03);
    final top2 = Path()
      ..moveTo(s.width * .30, s.height * .22)
      ..cubicTo(s.width * .60, s.height * .27, s.width * .78, s.height * .08, s.width * 1.02, s.height * .065);
    final bottom = Path()
      ..moveTo(-10, s.height * .93)
      ..cubicTo(s.width * .30, s.height * .86, s.width * .62, s.height * 1.0, s.width * 1.02, s.height * .90);
    final bottom2 = Path()
      ..moveTo(-10, s.height * .96)
      ..cubicTo(s.width * .32, s.height * .89, s.width * .65, s.height * 1.02, s.width * 1.02, s.height * .94);

    final a = dark ? 210 : 130;
    for (final p in [top, top2, bottom, bottom2]) {
      wave(p, dark ? 9 : 24, a ~/ 3, dark ? 12 : 18); // lớp sáng mờ
      wave(p, 1.6, a, 0); // đường nét mảnh
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.c != c || old.dark != dark;
}
