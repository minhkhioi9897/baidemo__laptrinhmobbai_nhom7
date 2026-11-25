import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// ===================== BỘ HIỆU ỨNG NÚT BẤM CHO VOICEHUB =====================
/// FxPress      : nhấn -> thu nhỏ + nghiêng 3D + đốm sáng theo ngón tay + vòng sáng lan + rung nhẹ + nảy lại
/// FxShimmer    : vệt sáng chạy ngang (dùng cho nhãn PRO, nút chính)
/// FxEntrance   : hiện lần lượt từng ô (trượt lên + phóng nhẹ + mờ dần vào)
/// FxPulseRings : các vòng sóng lan ra (nút ghi âm đang thu, quả cầu micro)
/// FxFloat      : nhấp nhô nhẹ như đang "thở"
/// FxOrb        : quả cầu micro = sóng + nhấp nhô + nảy khi chạm
/// FxButton     : nút chính dạng gradient (Đăng nhập, Lưu...) có đủ hiệu ứng

// ---------------------------------------------------------------- FxPress
class FxPress extends StatefulWidget {
  final Widget Function(BuildContext context, double press) builder;
  final VoidCallback? onTap;
  final double scale; // độ thu nhỏ khi nhấn (0.95 = còn 95%)
  final bool tilt, burst, haptic;
  final Color burstColor;
  final BorderRadius? radius; // bo góc để cắt hiệu ứng cho vừa nút

  /// Bọc bất kỳ widget nào: FxPress(onTap: ..., child: ...)
  FxPress({
    super.key,
    required Widget child,
    this.onTap,
    this.scale = .95,
    this.tilt = true,
    this.burst = true,
    this.haptic = true,
    this.burstColor = const Color(0xFF38BDF8),
    this.radius,
  }) : builder = ((_, __) => child);

  /// Dùng khi muốn biết độ nhấn (0..1) để làm hiệu ứng riêng bên trong (vd: mũi tên nhích sang phải)
  const FxPress.builder({
    super.key,
    required this.builder,
    this.onTap,
    this.scale = .95,
    this.tilt = true,
    this.burst = true,
    this.haptic = true,
    this.burstColor = const Color(0xFF38BDF8),
    this.radius,
  });

  @override
  State<FxPress> createState() => _FxPressState();
}

class _FxPressState extends State<FxPress> with TickerProviderStateMixin {
  late final AnimationController _p =
      AnimationController(vsync: this, lowerBound: -.35, upperBound: 1, value: 0);
  late final AnimationController _b =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  Offset _pos = Offset.zero, _tilt = Offset.zero;

  void _down(TapDownDetails d) {
    if (widget.haptic) HapticFeedback.lightImpact();
    final s = context.size ?? Size.zero;
    _pos = d.localPosition;
    _tilt = (s.isEmpty)
        ? Offset.zero
        : Offset((d.localPosition.dx / s.width - .5) * 2, (d.localPosition.dy / s.height - .5) * 2);
    _p.animateTo(1, duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  // thả tay: nảy lại như lò xo (vượt qua 1.0 một chút rồi ổn định)
  void _release() => _p.animateWith(
      SpringSimulation(const SpringDescription(mass: 1, stiffness: 420, damping: 15), _p.value, 0, 0));

  void _tap() {
    _b.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _p.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.builder(context, 0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: _tap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_p, _b]),
        builder: (context, _) {
          final v = _p.value;
          final press = v.clamp(0.0, 1.0);
          final s = 1 - v * (1 - widget.scale);
          Widget body = widget.builder(context, press);
          if (widget.burst) {
            Widget overlay = IgnorePointer(
              child: CustomPaint(
                painter: _FxPainter(pos: _pos, press: press, burst: _b.value, color: widget.burstColor),
              ),
            );
            overlay = widget.radius != null
                ? ClipRRect(borderRadius: widget.radius!, child: overlay)
                : ClipRect(child: overlay);
            body = Stack(fit: StackFit.passthrough, children: [body, Positioned.fill(child: overlay)]);
          }
          final m = Matrix4.identity()..setEntry(3, 2, 0.0014);
          if (widget.tilt) {
            m.rotateX(-_tilt.dy * .10 * press);
            m.rotateY(_tilt.dx * .10 * press);
          }
          m.scale(s, s, 1.0);
          return Transform(alignment: Alignment.center, transform: m, child: body);
        },
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  final Offset pos;
  final double press, burst;
  final Color color;
  _FxPainter({required this.pos, required this.press, required this.burst, required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    // 1) đốm sáng bám theo ngón tay khi đang giữ
    if (press > .01) {
      final r = s.shortestSide * .9;
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color.withAlpha((80 * press).round()), color.withAlpha(0)])
              .createShader(Rect.fromCircle(center: pos, radius: r)),
      );
    }
    // 2) vòng sáng lan ra từ điểm chạm khi bấm
    if (burst > 0 && burst < 1) {
      final maxR = math.sqrt(s.width * s.width + s.height * s.height);
      final r = maxR * .75 * Curves.easeOutCubic.transform(burst);
      final a = 1 - burst;
      canvas.drawCircle(pos, r, Paint()..color = color.withAlpha((40 * a).round()));
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 6 * a
          ..color = color.withAlpha((170 * a).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter o) => true;
}

// ---------------------------------------------------------------- FxShimmer
class _Slide extends GradientTransform {
  final double p;
  const _Slide(this.p);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * p, 0, 0);
}

class FxShimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  const FxShimmer({super.key, required this.child, this.period = const Duration(milliseconds: 3000)});
  @override
  State<FxShimmer> createState() => _FxShimmerState();
}

class _FxShimmerState extends State<FxShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = (_c.value / .45).clamp(0.0, 1.0); // quét trong 45% đầu, nghỉ phần còn lại
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (r) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [Color(0x00FFFFFF), Color(0xB3FFFFFF), Color(0x00FFFFFF)],
              stops: const [.35, .5, .65],
              transform: _Slide(-1 + 2 * t),
            ).createShader(r),
            child: child,
          );
        },
      );
}

// ---------------------------------------------------------------- FxEntrance
class FxEntrance extends StatefulWidget {
  final Widget child;
  final int index; // thứ tự ô: càng lớn càng hiện sau
  final Duration step;
  const FxEntrance({super.key, required this.child, this.index = 0, this.step = const Duration(milliseconds: 80)});
  @override
  State<FxEntrance> createState() => _FxEntranceState();
}

class _FxEntranceState extends State<FxEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.step * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = Curves.easeOutBack.transform(_c.value);
          final o = Curves.easeOut.transform(_c.value).clamp(0.0, 1.0);
          return Opacity(
            opacity: o,
            child: Transform.translate(
              offset: Offset(0, 36 * (1 - t)),
              child: Transform.scale(scale: .92 + .08 * t, child: child),
            ),
          );
        },
      );
}

// ---------------------------------------------------------------- FxPulseRings
class FxPulseRings extends StatefulWidget {
  final bool active;
  final Color color;
  final double size;
  final int rings;
  final Widget? child;
  const FxPulseRings({super.key, required this.active, required this.color, required this.size, this.rings = 3, this.child});
  @override
  State<FxPulseRings> createState() => _FxPulseRingsState();
}

class _FxPulseRingsState extends State<FxPulseRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant FxPulseRings old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) _c.repeat();
    if (!widget.active) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: widget.active ? 1 : 0),
                duration: const Duration(milliseconds: 300),
                builder: (_, on, __) => AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => CustomPaint(painter: _RingPainter(_c.value, widget.color, widget.rings, on)),
                ),
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ]),
      );
}

class _RingPainter extends CustomPainter {
  final double t, on;
  final Color color;
  final int rings;
  _RingPainter(this.t, this.color, this.rings, this.on);

  @override
  void paint(Canvas canvas, Size s) {
    if (on <= 0) return;
    final c = s.center(Offset.zero);
    final base = s.width / 2;
    for (var i = 0; i < rings; i++) {
      final ph = (t + i / rings) % 1.0;
      final r = base * (1 + ph * 1.1);
      final a = (1 - ph) * on;
      canvas.drawCircle(c, r, Paint()..color = color.withAlpha((38 * a).round()));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = color.withAlpha((150 * a).round()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => true;
}

// ---------------------------------------------------------------- FxFloat
class FxFloat extends StatefulWidget {
  final Widget child;
  final double amplitude;
  const FxFloat({super.key, required this.child, this.amplitude = 5});
  @override
  State<FxFloat> createState() => _FxFloatState();
}

class _FxFloatState extends State<FxFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, -widget.amplitude * Curves.easeInOut.transform(_c.value)),
          child: child,
        ),
      );
}

// ---------------------------------------------------------------- FxOrb
class FxOrb extends StatelessWidget {
  final double size;
  final Color color;
  final Widget child;
  const FxOrb({super.key, required this.size, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => FxPulseRings(
        active: true,
        color: color,
        size: size,
        rings: 2,
        child: FxFloat(
          child: FxPress(onTap: () {}, burst: false, tilt: false, scale: .9, child: child),
        ),
      );
}

// ---------------------------------------------------------------- FxButton
/// Nút chính: FxButton(label: 'Đăng nhập', icon: Icons.login_rounded, onPressed: ..., loading: dangTai)
class FxButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final List<Color> colors;
  final double height;

  const FxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.colors = const [Color(0xFF1C9BF0), Color(0xFF1E6FE0)],
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: FxPress(
        onTap: loading ? null : onPressed,
        radius: r,
        burstColor: Colors.white,
        child: FxShimmer(
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: colors.last.withAlpha(110), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('load'),
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : Row(key: const ValueKey('label'), mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white), const SizedBox(width: 8)],
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}
