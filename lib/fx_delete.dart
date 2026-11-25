import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// ===================== HIỆU ỨNG XOÁ "BÚNG TAY THANOS" =====================
/// 1) FxDeleteButton : nút thùng rác GIỮ để xoá. Giữ -> vòng tiến độ chạy quanh nút, nắp thùng mở dần,
///                     nút rung mạnh dần + rung điện thoại từng nấc. Nhả sớm -> vòng tự thu lại (không xoá nhầm).
/// 2) FxDismiss      : khi xác nhận, thẻ vỡ thành hàng trăm mảnh bụi bay lên rồi tan biến (quét từ trái sang phải),
///                     sau đó các thẻ bên dưới trượt lên lấp chỗ trống.
/// 3) FxDeletable    : ghép 1 + 2 lại cho dễ dùng. Chỉ cần:
///       FxDeletable(onDeleted: () => xoaDuLieu(), builder: (context, nutXoa) => TheCuaBan(trailing: nutXoa))

// ------------------------------------------------------------ giành quyền chạm ngay lập tức
class _ClaimRecognizer extends OneSequenceGestureRecognizer {
  VoidCallback? onDown;
  void Function(bool cancelled)? onUp;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted); // thắng ngay: thẻ phía sau không bị "nhấn" theo, danh sách không cuộn
    onDown?.call();
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
      onUp?.call(event is PointerCancelEvent);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'fxClaim';
}

// ------------------------------------------------------------ nút xoá (giữ để xoá)
class FxDeleteButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final Duration hold;
  final Color color;
  final double size;
  final String hint;

  const FxDeleteButton({
    super.key,
    required this.onConfirmed,
    this.hold = const Duration(milliseconds: 900),
    this.color = const Color(0xFFFF4D5E),
    this.size = 48,
    this.hint = 'Giữ để xoá',
  });

  @override
  State<FxDeleteButton> createState() => _FxDeleteButtonState();
}

class _FxDeleteButtonState extends State<FxDeleteButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.hold);
  final _tip = GlobalKey<TooltipState>();
  DateTime _downAt = DateTime.now();
  int _tick = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final t = (_c.value * 3).floor(); // rung nhẹ ở 1/3 và 2/3
      if (_c.status == AnimationStatus.forward && t != _tick && t > 0 && t < 3) {
        _tick = t;
        HapticFeedback.selectionClick();
      }
    });
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down() {
    if (_done) return;
    _downAt = DateTime.now();
    _tick = 0;
    _c.forward();
  }

  void _up(bool cancelled) {
    if (_done) return;
    final held = DateTime.now().difference(_downAt);
    if (!cancelled && held < const Duration(milliseconds: 280)) {
      // chạm nhanh: nắp thùng "gật" một cái + hiện chữ nhắc "Giữ để xoá"
      HapticFeedback.lightImpact();
      _tip.currentState?.ensureTooltipVisible();
      _c.animateTo(.3, duration: const Duration(milliseconds: 110)).whenComplete(
          () => _c.animateBack(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut));
    } else {
      _c.animateBack(0, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: _tip,
      message: widget.hint,
      triggerMode: TooltipTriggerMode.manual,
      showDuration: const Duration(milliseconds: 1400),
      preferBelow: false,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          _ClaimRecognizer: GestureRecognizerFactoryWithHandlers<_ClaimRecognizer>(
            () => _ClaimRecognizer(),
            (r) {
              r.onDown = _down;
              r.onUp = _up;
            },
          ),
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final p = _c.value;
            return Transform.rotate(
              angle: math.sin(p * 70) * .08 * p, // rung mạnh dần
              child: Transform.scale(
                scale: 1 + .14 * p,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(painter: _DelPainter(p, widget.color)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DelPainter extends CustomPainter {
  final double p;
  final Color color;
  _DelPainter(this.p, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final u = s.width / 48;
    final r = s.width / 2;

    // nền tròn đậm dần theo tiến độ
    canvas.drawCircle(c, r - 1, Paint()..color = Color.lerp(color.withAlpha(34), color.withAlpha(150), p)!);
    // vòng tiến độ
    canvas.drawCircle(c, r - 2.5,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = color.withAlpha(50));
    if (p > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 2.5),
        -math.pi / 2,
        2 * math.pi * p,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    // thùng rác
    canvas.save();
    canvas.translate(c.dx, c.dy + 2 * u);
    final st = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(color, Colors.white, p * .85)!;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(-7 * u, -3 * u, 7 * u, 11 * u,
          bottomLeft: Radius.circular(3 * u), bottomRight: Radius.circular(3 * u)),
      st,
    );
    canvas.drawLine(Offset(-2.6 * u, 1 * u), Offset(-2.6 * u, 8 * u), st);
    canvas.drawLine(Offset(2.6 * u, 1 * u), Offset(2.6 * u, 8 * u), st);
    // nắp: bản lề bên trái, mở dần theo tiến độ
    canvas.save();
    canvas.translate(-8 * u, -5.5 * u - 2 * u * p);
    canvas.rotate(-p * 1.0);
    canvas.drawLine(Offset.zero, Offset(16 * u, 0), st);
    canvas.drawPath(
      Path()
        ..moveTo(5 * u, 0)
        ..lineTo(5 * u, -2.6 * u)
        ..lineTo(11 * u, -2.6 * u)
        ..lineTo(11 * u, 0),
      st,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DelPainter o) => o.p != p || o.color != color;
}

// ------------------------------------------------------------ thẻ tan thành bụi
class FxDismiss extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed; // gọi SAU KHI hiệu ứng xong -> lúc này mới xoá dữ liệu
  final Color dust; // màu các đốm sáng li ti
  const FxDismiss({super.key, required this.child, required this.onDismissed, this.dust = const Color(0xFFFF6B6B)});

  @override
  State<FxDismiss> createState() => FxDismissState();
}

class FxDismissState extends State<FxDismiss> with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  ui.Image? _img;
  Size _size = Size.zero;
  double _ratio = 1;
  bool _collapsed = false;

  /// Gọi để bắt đầu hiệu ứng tan biến.
  Future<void> dismiss() async {
    if (_img != null) return;
    final ro = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (ro == null) {
      widget.onDismissed();
      return;
    }
    _ratio = MediaQuery.of(context).devicePixelRatio;
    final img = await ro.toImage(pixelRatio: _ratio); // chụp lại thẻ
    if (!mounted) return;
    setState(() {
      _img = img;
      _size = ro.size;
    });
    await _c.forward();
    if (!mounted) return;
    setState(() => _collapsed = true); // các thẻ dưới trượt lên
    await Future.delayed(const Duration(milliseconds: 320));
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _c.dispose();
    _img?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none, // để bụi bay ra ngoài khung thẻ
      child: _collapsed
          ? const SizedBox(width: double.infinity, height: 0)
          : _img == null
              ? RepaintBoundary(key: _key, child: widget.child)
              : SizedBox(
                  width: _size.width,
                  height: _size.height,
                  child: CustomPaint(painter: _DustPainter(_img!, _c, _size, _ratio, widget.dust)),
                ),
    );
  }
}

class _DustPainter extends CustomPainter {
  final ui.Image img;
  final Animation<double> t;
  final Size size;
  final double ratio;
  final Color glow;
  final double cell;
  _DustPainter(this.img, this.t, this.size, this.ratio, this.glow)
      : cell = math.max(6.0, math.sqrt(size.width * size.height / 1100)), // ~1100 mảnh
        super(repaint: t);

  static double _h(int n) {
    n = (n ^ 61) ^ (n >> 16);
    n *= 9;
    n ^= n >> 4;
    n *= 0x27d4eb2d;
    n ^= n >> 15;
    return (n & 0xFFFF) / 65535.0;
  }

  @override
  void paint(Canvas canvas, Size _) {
    final cols = (size.width / cell).ceil(), rows = (size.height / cell).ceil();
    final tt = t.value;
    final paint = Paint()..filterQuality = FilterQuality.low;
    final dot = Paint();

    for (var i = 0; i < cols; i++) {
      final start = (i / cols) * .5; // cột bên trái tan trước, lan sang phải
      for (var j = 0; j < rows; j++) {
        final seed = (i * 73856093) ^ (j * 19349663);
        final r1 = _h(seed), r2 = _h(seed + 1), r3 = _h(seed + 2);
        final local = ((tt - start - r1 * .08) / .5).clamp(0.0, 1.0);
        if (local >= 1) continue;

        // vùng ảnh nguồn (chừa mép ảnh)
        final sx = i * cell * ratio, sy = j * cell * ratio;
        final sw = math.min(cell * ratio, img.width - sx), sh = math.min(cell * ratio, img.height - sy);
        if (sw <= 0 || sh <= 0) continue;
        final src = Rect.fromLTWH(sx, sy, sw, sh);
        final dw = sw / ratio, dh = sh / ratio;
        final home = Offset(i * cell, j * cell);

        if (local <= 0) {
          canvas.drawImageRect(img, src, Rect.fromLTWH(home.dx, home.dy, dw, dh), paint);
          continue;
        }
        final e = Curves.easeIn.transform(local);
        final dx = (30 + 110 * r2) * e; // bay sang phải
        final dy = (-30 - 100 * r3) * e + 50 * e * e * r1; // bay lên rồi hơi rơi
        final ang = (r1 - .5) * 7 * e;
        final scale = 1 - .65 * e;
        paint.color = Color.fromRGBO(255, 255, 255, 1 - local);

        canvas.save();
        canvas.translate(home.dx + dw / 2 + dx, home.dy + dh / 2 + dy);
        canvas.rotate(ang);
        canvas.drawImageRect(img, src, Rect.fromCenter(center: Offset.zero, width: dw * scale, height: dh * scale), paint);
        canvas.restore();

        // đốm sáng li ti bay cùng bụi
        if ((i + j) % 3 == 0) {
          final a = math.sin(local * math.pi); // sáng nhất ở giữa vòng đời
          dot.color = glow.withAlpha((200 * a).round());
          canvas.drawCircle(Offset(home.dx + dw / 2 + dx * 1.15, home.dy + dh / 2 + dy * 1.15), 1.1 + 1.6 * r2, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter o) => false; // đã có repaint: t
}

// ------------------------------------------------------------ ghép lại cho dễ dùng
class FxDeletable extends StatefulWidget {
  /// builder nhận sẵn `deleteButton` để bạn đặt vào bất cứ chỗ nào trong thẻ.
  final Widget Function(BuildContext context, Widget deleteButton) builder;
  final VoidCallback onDeleted; // gọi khi hiệu ứng xong -> xoá dữ liệu ở đây
  final VoidCallback? onStart; // gọi ngay lúc vừa xác nhận (vd: dừng phát âm thanh)
  final Color color; // màu nút xoá
  final Color dust; // màu đốm sáng
  final Duration hold;

  const FxDeletable({
    super.key,
    required this.builder,
    required this.onDeleted,
    this.onStart,
    this.color = const Color(0xFFFF4D5E),
    this.dust = const Color(0xFFFF6B6B),
    this.hold = const Duration(milliseconds: 900),
  });

  @override
  State<FxDeletable> createState() => _FxDeletableState();
}

class _FxDeletableState extends State<FxDeletable> {
  final _k = GlobalKey<FxDismissState>();

  @override
  Widget build(BuildContext context) {
    return FxDismiss(
      key: _k,
      dust: widget.dust,
      onDismissed: widget.onDeleted,
      child: widget.builder(
        context,
        FxDeleteButton(
          color: widget.color,
          hold: widget.hold,
          onConfirmed: () {
            widget.onStart?.call();
            _k.currentState?.dismiss();
          },
        ),
      ),
    );
  }
}
