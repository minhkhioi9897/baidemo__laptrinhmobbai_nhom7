import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/tts_service.dart';
import '../utils/calculator_parser.dart';

enum BinaryMode { voice, manual }

class BinaryScreen extends StatefulWidget {
  const BinaryScreen({super.key});

  @override
  State<BinaryScreen> createState() => _BinaryScreenState();
}

class _BinaryScreenState extends State<BinaryScreen> {
  BinaryMode _mode = BinaryMode.voice;
  final TextEditingController _inputController = TextEditingController();

  String _binaryResult = '';
  String _decimalResult = '';
  String _hexResult = '';
  String _octalResult = '';

  // Speech To Text State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _inputController.addListener(_convertBase);
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

  void _convertBase() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _binaryResult = '';
        _decimalResult = '';
        _hexResult = '';
        _octalResult = '';
      });
      return;
    }

    try {
      int? number;

      // Check if input is binary string e.g. "1010"
      if (RegExp(r'^[01]+$').hasMatch(input)) {
        number = int.tryParse(input, radix: 2);
      } else {
        // Assume decimal input
        number = int.tryParse(input);
      }

      if (number != null) {
        final validNum = number;
        setState(() {
          _decimalResult = validNum.toString();
          _binaryResult = validNum.toRadixString(2);
          _hexResult = validNum.toRadixString(16).toUpperCase();
          _octalResult = validNum.toRadixString(8);
        });
      } else {
        setState(() {
          _binaryResult = 'Lỗi nhập liệu';
          _decimalResult = '---';
          _hexResult = '---';
          _octalResult = '---';
        });
      }
    } catch (_) {
      setState(() {
        _binaryResult = 'Lỗi';
      });
    }
  }

  void _processSpokenWords(String speechText) {
    if (speechText.trim().isEmpty) return;

    // 1. Convert spoken words ("năm", "hai mươi lăm") to numeric string ("5", "25")
    String parsedMath = CalculatorParser.parseVietnameseSpeech(speechText);

    // 2. Extract digits only so "Giọng nói nhận diện" displays purely numbers
    String digitsOnly = parsedMath.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      digitsOnly = speechText.replaceAll(RegExp(r'[^\d]'), '');
    }

    if (digitsOnly.isNotEmpty) {
      _spokenText = digitsOnly;
      _inputController.text = digitsOnly;
      _convertBase();
    }
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
        onResult: (val) async {
          setState(() {
            _processSpokenWords(val.recognizedWords);
          });

          // When spoken result is final, stop microphone & reset mic icon
          if (val.finalResult) {
            await _speech.stop();
            setState(() {
              _isListening = false;
            });

            if (_binaryResult.isNotEmpty && _binaryResult != 'Lỗi') {
              await TtsService().speak('Kết quả nhị phân là $_binaryResult');
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF020817) : const Color(0xFFFAFAFA);
    final cardBgColor = isDark ? const Color(0x330284C7) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFFF3F4F6);

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
          'Chuyển đổi hệ cơ số',
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
                      isSelected: _mode == BinaryMode.voice,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _mode = BinaryMode.voice;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      title: 'Tính thủ công',
                      icon: Icons.calculate_outlined,
                      isSelected: _mode == BinaryMode.manual,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _mode = BinaryMode.manual;
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
                    // Mode 1: Voice Mode
                    if (_mode == BinaryMode.voice) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x2000E5FF) : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.6) : const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHUYỂN ĐỔI BẰNG GIỌNG NÓI',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chạm mic bên dưới và đọc số. Đọc xong ngắt giọng mic sẽ tự tắt và đọc kết quả.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0369A1),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_spokenText.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: isDark ? 1.5 : 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giọng nói nhận diện:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '"$_spokenText"',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Results
                      _buildResultTile(
                        title: 'Nhị phân (Binary - Cơ số 2)',
                        value: _binaryResult,
                        icon: Icons.looks_two_outlined,
                        color: const Color(0xFF0284C7),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildResultTile(
                        title: 'Thập phân (Decimal - Cơ số 10)',
                        value: _decimalResult,
                        icon: Icons.numbers_outlined,
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildResultTile(
                        title: 'Thập lục phân (Hex - Cơ số 16)',
                        value: _hexResult,
                        icon: Icons.code_outlined,
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildResultTile(
                        title: 'Bát phân (Octal - Cơ số 8)',
                        value: _octalResult,
                        icon: Icons.tag_outlined,
                        color: const Color(0xFFEA580C),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),

                      const SizedBox(height: 40),

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
                                  color: _isListening
                                      ? const Color(0xFFDC2626)
                                      : (isDark ? const Color(0xFF0284C7) : const Color(0xFF0284C7)),
                                  shape: BoxShape.circle,
                                  border: isDark ? Border.all(color: const Color(0xFF00E5FF), width: 1.5) : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isListening
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF0284C7))
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
                                  ? 'Đang nghe...'
                                  : 'Chạm mic và đọc số để chuyển đổi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Mode 2: Manual Mode
                    if (_mode == BinaryMode.manual) ...[
                      Text(
                        'Giá trị nhập thủ công',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _inputController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: 25 hoặc 11001',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: subtitleColor,
                            letterSpacing: 0,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0x20000000) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Results
                      _buildResultTile(
                        title: 'Nhị phân (Binary - Cơ số 2)',
                        value: _binaryResult,
                        icon: Icons.looks_two_outlined,
                        color: const Color(0xFF0284C7),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildResultTile(
                        title: 'Thập phân (Decimal - Cơ số 10)',
                        value: _decimalResult,
                        icon: Icons.numbers_outlined,
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildResultTile(
                        title: 'Thập lục phân (Hex - Cơ số 16)',
                        value: _hexResult,
                        icon: Icons.code_outlined,
                        color: const Color(0xFF7C3AED),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const SizedBox(height: 12),
                      _buildResultTile(
                        title: 'Bát phân (Octal - Cơ số 8)',
                        value: _octalResult,
                        icon: Icons.tag_outlined,
                        color: const Color(0xFFEA580C),
                        isDark: isDark,
                        cardBgColor: cardBgColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
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
          border: isSelected && isDark
              ? Border.all(color: const Color(0xFF00E5FF), width: 1)
              : null,
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
                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7))
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

  Widget _buildResultTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Color cardBgColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? color.withValues(alpha: 0.5) : const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.25 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '---' : value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: value.isEmpty
                        ? (isDark ? Colors.grey[600] : const Color(0xFF9CA3AF))
                        : (isDark ? Colors.white : const Color(0xFF111827)),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
