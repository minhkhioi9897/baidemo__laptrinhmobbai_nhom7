import 'package:flutter/material.dart';

/// Mặc định THEO ĐIỆN THOẠI: máy để chế độ tối thì app tối, máy để sáng thì app sáng.
/// Muốn ép cố định:  themeMode.value = ThemeMode.light;  hoặc  ThemeMode.dark;
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

@immutable
class VoiceColors extends ThemeExtension<VoiceColors> {
  final Color bg1, bg2, bg3; // nền chuyển màu (trên -> dưới)
  final Color waveA, waveB; // 2 màu của các đường sóng trang trí
  final Color cardTop, cardBottom; // nền thẻ kính
  final Color cardBorder, cardShadow; // viền + bóng thẻ (dùng khi useEdge = false)
  final bool useEdge; // true: viền thẻ lấy màu riêng từng ô (nền tối); false: viền trắng (nền sáng)
  final Color text, sub; // chữ chính, chữ phụ
  final Color gold, goldBg, goldText; // màu PRO
  final Color chipBg, chipText, chipBorder; // chip "Thành viên PRO"
  final Color orbA, orbB, orbIcon; // quả cầu micro
  final Color helpBg; // nền nút "?"
  final bool starCircle; // sao "Đã kích hoạt" nằm trong vòng tròn đặc
  final Color starBg, activeText;
  final Color accent, danger, bar;

  const VoiceColors({
    required this.bg1, required this.bg2, required this.bg3,
    required this.waveA, required this.waveB,
    required this.cardTop, required this.cardBottom,
    required this.cardBorder, required this.cardShadow, required this.useEdge,
    required this.text, required this.sub, required this.gold, required this.goldBg, required this.goldText,
    required this.chipBg, required this.chipText, required this.chipBorder,
    required this.orbA, required this.orbB, required this.orbIcon,
    required this.helpBg, required this.starCircle, required this.starBg, required this.activeText,
    required this.accent, required this.danger, required this.bar,
  });

  // ===== NỀN TỐI: màu ĐEN làm chủ đạo =====
  static const dark = VoiceColors(
    bg1: Color(0xFF000000), bg2: Color(0xFF04060C), bg3: Color(0xFF0A0D18),
    waveA: Color(0xFF3B6FE0), waveB: Color(0xFF7C5CF0),
    cardTop: Color(0x4D1E2745), cardBottom: Color(0x99080B14),
    cardBorder: Color(0x00000000), cardShadow: Color(0x00000000), useEdge: true,
    text: Color(0xFFF5F7FF), sub: Color(0xFF8D97B2), gold: Color(0xFFFFC857), goldBg: Color(0x33FFC857), goldText: Color(0xFFFFD98A),
    chipBg: Color(0x33FFC857), chipText: Color(0xFFFFD98A), chipBorder: Color(0x6EFFC857),
    orbA: Color(0x5A38BDF8), orbB: Color(0xFF04060C), orbIcon: Color(0xDCF2F6FF),
    helpBg: Color(0x00000000), starCircle: false, starBg: Color(0x00000000), activeText: Color(0xFFFFD98A),
    accent: Color(0xFF38BDF8), danger: Color(0xFFFF4D6D), bar: Color(0x14FFFFFF),
  );

  // ===== NỀN SÁNG: màu TRẮNG làm chủ đạo =====
  static const light = VoiceColors(
    bg1: Color(0xFFFFFFFF), bg2: Color(0xFFF8FAFF), bg3: Color(0xFFF0F4FF),
    waveA: Color(0xFFCFE0FF), waveB: Color(0xFFE0D6FF),
    cardTop: Color(0xFFFFFFFF), cardBottom: Color(0xE6F3F6FF),
    cardBorder: Color(0xFFDDE6F6), cardShadow: Color(0x1F4A66C8), useEdge: false,
    text: Color(0xFF0B1226), sub: Color(0xFF5B6784), gold: Color(0xFFF5B544), goldBg: Color(0xFFFFF0CC), goldText: Color(0xFF8A5A00),
    chipBg: Color(0xFF2A3C8F), chipText: Color(0xFFFFD98A), chipBorder: Color(0xFF4A5FC0),
    orbA: Color(0xFF6FA0F5), orbB: Color(0xFF2F55D4), orbIcon: Color(0xFFFFFFFF),
    helpBg: Color(0xFFFFFFFF), starCircle: true, starBg: Color(0xFF0B1226), activeText: Color(0xFF0B1226),
    accent: Color(0xFF3B6FE0), danger: Color(0xFFE5484D), bar: Color(0xFFFFFFFF),
  );

  @override
  VoiceColors copyWith() => this;

  @override
  VoiceColors lerp(ThemeExtension<VoiceColors>? other, double t) {
    if (other is! VoiceColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    bool pick(bool a, bool b) => t < .5 ? a : b;
    return VoiceColors(
      bg1: l(bg1, other.bg1), bg2: l(bg2, other.bg2), bg3: l(bg3, other.bg3),
      waveA: l(waveA, other.waveA), waveB: l(waveB, other.waveB),
      cardTop: l(cardTop, other.cardTop), cardBottom: l(cardBottom, other.cardBottom),
      cardBorder: l(cardBorder, other.cardBorder), cardShadow: l(cardShadow, other.cardShadow),
      useEdge: pick(useEdge, other.useEdge),
      text: l(text, other.text), sub: l(sub, other.sub), gold: l(gold, other.gold),
      goldBg: l(goldBg, other.goldBg), goldText: l(goldText, other.goldText),
      chipBg: l(chipBg, other.chipBg), chipText: l(chipText, other.chipText), chipBorder: l(chipBorder, other.chipBorder),
      orbA: l(orbA, other.orbA), orbB: l(orbB, other.orbB), orbIcon: l(orbIcon, other.orbIcon),
      helpBg: l(helpBg, other.helpBg), starCircle: pick(starCircle, other.starCircle),
      starBg: l(starBg, other.starBg), activeText: l(activeText, other.activeText),
      accent: l(accent, other.accent), danger: l(danger, other.danger), bar: l(bar, other.bar),
    );
  }
}

class AppTheme {
  static ThemeData get dark => _build(Brightness.dark, VoiceColors.dark, Colors.black, const Color(0xFF121212));
  static ThemeData get light => _build(Brightness.light, VoiceColors.light, Colors.white, const Color(0xFFF8FAFC));

  static ThemeData _build(Brightness b, VoiceColors c, Color scaffoldBg, Color cardColor) => ThemeData(
        useMaterial3: true,
        brightness: b,
        scaffoldBackgroundColor: scaffoldBg,
        cardColor: cardColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: b,
          surface: cardColor,
        ),
        extensions: [c],
      );
}
