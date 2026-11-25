import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/tts_service.dart';

enum EquationMode { voice, manual }

class EquationScreen extends StatefulWidget {
  const EquationScreen({super.key});

  @override
  State<EquationScreen> createState() => _EquationScreenState();
}

class _EquationScreenState extends State<EquationScreen> {
  EquationMode _mode = EquationMode.voice;
  int _selectedDegree = 2; // 1: Bậc 1, 2: Bậc 2, 3: Bậc 3

  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  final TextEditingController _cController = TextEditingController();
  final TextEditingController _dController = TextEditingController();

  String _resultText = '';
  List<String> _solutionSteps = [];

  // Speech To Text State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }
  }

  void _solveEquation() {
    final double? a = double.tryParse(_aController.text.trim());
    final double? b = double.tryParse(_bController.text.trim());
    final double? c = double.tryParse(_cController.text.trim());
    final double? d = double.tryParse(_dController.text.trim());

    FocusScope.of(context).unfocus();

    List<String> steps = [];

    if (_selectedDegree == 1) {
      if (a == null || b == null) {
        _setResult('Vui lòng nhập/nói đầy đủ hệ số a và b.', []);
        return;
      }

      steps.add('Phương trình ban đầu: ${_formatCoeff(a)}x ${_formatSign(b)} = 0');
      steps.add('Chuyển vế hệ số tự do: ${_formatCoeff(a)}x = ${_formatNumber(-b)}');

      if (a == 0) {
        if (b == 0) {
          steps.add('Vì 0x = 0 đúng với mọi x => Phương trình vô số nghiệm.');
          _setResult('Phương trình có vô số nghiệm.', steps);
        } else {
          steps.add('Vì 0x = ${_formatNumber(-b)} (vô lý) => Phương trình vô nghiệm.');
          _setResult('Phương trình vô nghiệm.', steps);
        }
      } else {
        final x = -b / a;
        steps.add('Chia hai vế cho a (${_formatNumber(a)}): x = (${_formatNumber(-b)}) / (${_formatNumber(a)})');
        steps.add('=> Kết quả nghiệm: x = ${_formatNumber(x)}');
        _setResult('Nghiệm x = ${_formatNumber(x)}', steps);
      }
    } else if (_selectedDegree == 2) {
      if (a == null || b == null || c == null) {
        _setResult('Vui lòng nhập/nói đầy đủ hệ số a, b và c.', []);
        return;
      }

      steps.add('Phương trình: ${_formatCoeff(a)}x² ${_formatSign(b)}x ${_formatSign(c)} = 0');

      if (a == 0) {
        steps.add('Hệ số a = 0, phương trình trở thành bậc 1: ${_formatCoeff(b)}x ${_formatSign(c)} = 0');
        if (b == 0) {
          _setResult(c == 0 ? 'Phương trình vô số nghiệm.' : 'Phương trình vô nghiệm.', steps);
        } else {
          final x = -c / b;
          steps.add('=> x = -c / b = ${_formatNumber(x)}');
          _setResult('Phương trình bậc 1 có nghiệm x = ${_formatNumber(x)}', steps);
        }
        return;
      }

      final delta = b * b - 4 * a * c;
      steps.add('Tính biệt thức Δ (Delta) = b² - 4ac');
      steps.add('Δ = (${_formatNumber(b)})² - 4 × (${_formatNumber(a)}) × (${_formatNumber(c)})');
      steps.add('=> Δ = ${_formatNumber(delta)}');

      if (delta < 0) {
        steps.add('Vì Δ = ${_formatNumber(delta)} < 0 nên phương trình không có nghiệm thực.');
        _setResult('Phương trình vô nghiệm thực (Δ = ${_formatNumber(delta)} < 0).', steps);
      } else if (delta == 0) {
        final x = -b / (2 * a);
        steps.add('Vì Δ = 0 nên phương trình có nghiệm kép: x = -b / (2a)');
        steps.add('x = -(${_formatNumber(b)}) / (2 × ${_formatNumber(a)}) = ${_formatNumber(x)}');
        _setResult('Phương trình có nghiệm kép:\nx = ${_formatNumber(x)}', steps);
      } else {
        final sqrtDelta = sqrt(delta);
        steps.add('Vì Δ > 0 nên √Δ = ${_formatNumber(sqrtDelta)}');
        final x1 = (-b + sqrtDelta) / (2 * a);
        final x2 = (-b - sqrtDelta) / (2 * a);
        steps.add('Nghiệm x₁ = (-b + √Δ) / (2a) = ( -(${_formatNumber(b)}) + ${_formatNumber(sqrtDelta)} ) / (2 × ${_formatNumber(a)}) = ${_formatNumber(x1)}');
        steps.add('Nghiệm x₂ = (-b - √Δ) / (2a) = ( -(${_formatNumber(b)}) - ${_formatNumber(sqrtDelta)} ) / (2 × ${_formatNumber(a)}) = ${_formatNumber(x2)}');
        _setResult('Phương trình có 2 nghiệm phân biệt:\nx₁ = ${_formatNumber(x1)}\nx₂ = ${_formatNumber(x2)}', steps);
      }
    } else if (_selectedDegree == 3) {
      if (a == null || b == null || c == null || d == null) {
        _setResult('Vui lòng nhập/nói đầy đủ hệ số a, b, c và d.', []);
        return;
      }
      if (a == 0) {
        _setResult('Hệ số a phải khác 0 đối với phương trình bậc 3.', []);
        return;
      }

      steps.add('Phương trình: ${_formatCoeff(a)}x³ ${_formatSign(b)}x² ${_formatSign(c)}x ${_formatSign(d)} = 0');
      steps.add('Áp dụng công thức Cardano giải phương trình bậc 3 chuẩn hóa.');

      final double p = (3 * a * c - b * b) / (3 * a * a);
      final double q = (2 * b * b * b - 9 * a * b * c + 27 * a * a * d) / (27 * a * a * a);
      final double delta = (q * q / 4) + (p * p * p / 27);

      steps.add('Tính p = ${_formatNumber(p)}, q = ${_formatNumber(q)}');
      steps.add('Biệt thức Δ (Cubic Delta) = (q/2)² + (p/3)³ = ${_formatNumber(delta)}');

      if (delta > 0) {
        final double u = _cbrt(-q / 2 + sqrt(delta));
        final double v = _cbrt(-q / 2 - sqrt(delta));
        final double x1 = u + v - (b / (3 * a));
        steps.add('Vì Δ > 0 nên phương trình có 1 nghiệm thực duy nhất: x = ${_formatNumber(x1)}');
        _setResult('Phương trình có 1 nghiệm thực:\nx = ${_formatNumber(x1)}', steps);
      } else if (delta == 0) {
        final double u = _cbrt(-q / 2);
        final double x1 = 2 * u - (b / (3 * a));
        final double x2 = -u - (b / (3 * a));
        steps.add('Vì Δ = 0 nên phương trình có nghiệm kép.');
        steps.add('x₁ = ${_formatNumber(x1)}, x₂ = ${_formatNumber(x2)}');
        _setResult('Phương trình có nghiệm kép:\nx₁ = ${_formatNumber(x1)}\nx₂ = ${_formatNumber(x2)}', steps);
      } else {
        final double r = sqrt(-p * p * p / 27);
        final double phi = acos(-q / (2 * r));
        final double x1 = 2 * _cbrt(r) * cos(phi / 3) - (b / (3 * a));
        final double x2 = 2 * _cbrt(r) * cos((phi + 2 * pi) / 3) - (b / (3 * a));
        final double x3 = 2 * _cbrt(r) * cos((phi + 4 * pi) / 3) - (b / (3 * a));
        steps.add('Vì Δ < 0 nên phương trình có 3 nghiệm thực phân biệt.');
        steps.add('x₁ = ${_formatNumber(x1)}, x₂ = ${_formatNumber(x2)}, x₃ = ${_formatNumber(x3)}');
        _setResult('Phương trình có 3 nghiệm thực phân biệt:\nx₁ = ${_formatNumber(x1)}\nx₂ = ${_formatNumber(x2)}\nx₃ = ${_formatNumber(x3)}', steps);
      }
    }
  }

  String _formatCoeff(double val) {
    if (val == 1) return '';
    if (val == -1) return '-';
    return _formatNumber(val);
  }

  String _formatSign(double val) {
    if (val >= 0) return '+ ${_formatNumber(val)}';
    return '- ${_formatNumber(-val)}';
  }

  double _cbrt(double x) {
    return x < 0 ? -pow(-x, 1 / 3).toDouble() : pow(x, 1 / 3).toDouble();
  }

  void _setResult(String text, List<String> steps) {
    setState(() {
      _resultText = text;
      _solutionSteps = steps;
    });
    TtsService().speak(text.replaceAll('\n', ', '));
  }

  String _formatNumber(double val) {
    if (val == val.truncateToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
    });

    if (_speechAvailable) {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _spokenText = val.recognizedWords;
            _parseSpokenCoefficients(_spokenText);
          });
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'vi_VN',
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    }
  }

  void _parseSpokenCoefficients(String input) {
    final numbers = RegExp(r'-?\d+(\.\d+)?')
        .allMatches(input)
        .map((m) => m.group(0)!)
        .toList();

    if (numbers.isNotEmpty) _aController.text = numbers[0];
    if (numbers.length > 1) _bController.text = numbers[1];
    if (numbers.length > 2) _cController.text = numbers[2];
    if (numbers.length > 3) _dController.text = numbers[3];

    if (numbers.isNotEmpty) {
      _solveEquation();
    }
  }

  @override
  void dispose() {
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();
    _dController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF020817) : const Color(0xFFFAFAFA);
    final cardBgColor = isDark ? const Color(0x330284C7) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFFFFEDD5);

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
          'Giải phương trình',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Mode Switcher (Giọng nói / Tính thủ công)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x2000E5FF) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: isDark ? Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      title: 'Giọng nói',
                      icon: Icons.mic_none,
                      isSelected: _mode == EquationMode.voice,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _mode = EquationMode.voice;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      title: 'Tính thủ công',
                      icon: Icons.edit_note_outlined,
                      isSelected: _mode == EquationMode.manual,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _mode = EquationMode.manual;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Degree Selection Chips
                    Text(
                      'Chọn bậc phương trình',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [1, 2, 3].map((degree) {
                        final isSelected = _selectedDegree == degree;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDegree = degree;
                                _resultText = '';
                                _solutionSteps = [];
                                _spokenText = '';
                                _aController.clear();
                                _bController.clear();
                                _cController.clear();
                                _dController.clear();
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0x33F97316) : const Color(0xFFFFF7ED))
                                    : (isDark ? const Color(0x2000E5FF) : const Color(0xFFF3F4F6)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFFF97316) : const Color(0xFFF97316))
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Bậc $degree',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C))
                                      : subtitleColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Equation Template Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x25EA580C) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.5) : const Color(0xFFFFEDD5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _selectedDegree == 1
                            ? 'Dạng: ax + b = 0'
                            : (_selectedDegree == 2
                                ? 'Dạng: ax² + bx + c = 0'
                                : 'Dạng: ax³ + bx² + cx + d = 0'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mode 1: Voice Mode
                    if (_mode == EquationMode.voice) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: isDark ? 1.5 : 1),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hệ số đã nhận diện từ giọng nói:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Scrollable Row for coefficients to prevent overflow
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildVoiceCoeffBox('a', _aController.text, isDark),
                                  const SizedBox(width: 12),
                                  _buildVoiceCoeffBox('b', _bController.text, isDark),
                                  if (_selectedDegree >= 2) ...[
                                    const SizedBox(width: 12),
                                    _buildVoiceCoeffBox('c', _cController.text, isDark),
                                  ],
                                  if (_selectedDegree == 3) ...[
                                    const SizedBox(width: 12),
                                    _buildVoiceCoeffBox('d', _dController.text, isDark),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Result Card & Solution Steps
                      if (_resultText.isNotEmpty) _buildSolutionViewCard(isDark, cardBgColor, textColor, subtitleColor),

                      const SizedBox(height: 36),

                      // Voice Mic Button
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _toggleListening,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFFEA580C) : const Color(0xFFEA580C),
                                  shape: BoxShape.circle,
                                  border: isDark ? Border.all(color: const Color(0xFFF97316), width: 1.5) : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEA580C)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isListening ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isListening
                                  ? 'Đang lắng nghe...'
                                  : 'Chạm mic và đọc các hệ số',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ví dụ: "1 âm 5 6"',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[600] : const Color(0xFF9CA3AF),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Mode 2: Manual Mode
                    if (_mode == EquationMode.manual) ...[
                      Row(
                        children: [
                          Expanded(child: _buildCoeffField('Hệ số a', _aController, isDark, textColor, subtitleColor)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildCoeffField('Hệ số b', _bController, isDark, textColor, subtitleColor)),
                          if (_selectedDegree >= 2) ...[
                            const SizedBox(width: 12),
                            Expanded(child: _buildCoeffField('Hệ số c', _cController, isDark, textColor, subtitleColor)),
                          ],
                          if (_selectedDegree == 3) ...[
                            const SizedBox(width: 12),
                            Expanded(child: _buildCoeffField('Hệ số d', _dController, isDark, textColor, subtitleColor)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Solve Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _solveEquation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Giải phương trình',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Result Card & Solution Steps
                      if (_resultText.isNotEmpty) _buildSolutionViewCard(isDark, cardBgColor, textColor, subtitleColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionViewCard(bool isDark, Color cardBgColor, Color textColor, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.6) : const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Title
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFFEA580C), size: 20),
              SizedBox(width: 8),
              Text(
                'KẾT QUẢ NGHIỆM',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA580C),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _resultText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.4,
            ),
          ),

          if (_solutionSteps.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: isDark ? const Color(0xFFEA580C).withValues(alpha: 0.4) : const Color(0xFFFED7AA), thickness: 1),
            const SizedBox(height: 14),

            // Solution Steps Section Title
            const Row(
              children: [
                Icon(Icons.format_list_bulleted_rounded,
                    color: Color(0xFFC2410C), size: 18),
                SizedBox(width: 8),
                Text(
                  'CÁC BƯỚC GIẢI CHI TIẾT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2410C),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Steps List
            ..._solutionSteps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEDD5),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$idx',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceCoeffBox(String label, String value, bool isDark) {
    final displayVal = value.isNotEmpty ? value : '?';
    return Column(
      children: [
        const Text(
          'Hệ số',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEA580C),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x33EA580C) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Text(
            '$label = $displayVal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0284C7) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFFEA580C))
                  : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF111827))
                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoeffField(String label, TextEditingController controller, bool isDark, Color textColor, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: subtitleColor),
            filled: true,
            fillColor: isDark ? const Color(0x20000000) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
