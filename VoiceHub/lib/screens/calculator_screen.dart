import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/calculator_parser.dart';

enum CalculatorMode { manual, voice }

class CalculationHistory {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.day}/${timestamp.month} - $hour:$minute';
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  CalculatorMode _mode = CalculatorMode.voice;

  // History List
  final List<CalculationHistory> _historyList = [];

  // Voice Mode State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _spokenText = '';
  String _wordsOnlyText = '';
  String _expression = '';
  String _resultStr = '';

  // Manual Mode State
  String _manualInput = '';
  String _manualResult = '';

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
            if (val.recognizedWords.isNotEmpty) {
              _spokenText = val.recognizedWords;
              // Converts to Vietnamese words entirely for "Đã nghe được" display
              _wordsOnlyText =
                  CalculatorParser.convertToVietnameseWords(_spokenText);

              // Standardized math expression stopping before '=' or 'bằng'
              _expression =
                  CalculatorParser.parseVietnameseSpeech(_spokenText);

              final evaluated =
                  CalculatorParser.evaluateExpression(_expression);
              if (evaluated != null) {
                _resultStr = CalculatorParser.formatResult(evaluated);
                _addToHistory(_expression, _resultStr);
              } else {
                _resultStr = '---';
              }
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'vi_VN',
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } else {
      // Simulation / demo if speech recognition is unavailable on device
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Thiết bị không hỗ trợ thu âm speech-to-text. Hiển thị chế độ xem thử.'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _isListening = false;
      });
    }
  }

  void _addToHistory(String expr, String res) {
    if (expr.trim().isEmpty || res == 'Lỗi' || res == '---') return;
    // Tránh lưu trùng lặp phép tính vừa thực hiện
    if (_historyList.isNotEmpty &&
        _historyList.first.expression == expr &&
        _historyList.first.result == res) {
      return;
    }
    _historyList.insert(
      0,
      CalculationHistory(
        expression: expr,
        result: res,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'C') {
        _manualInput = '';
        _manualResult = '';
      } else if (value == '⌫') {
        if (_manualInput.isNotEmpty) {
          _manualInput = _manualInput.substring(0, _manualInput.length - 1);
        }
      } else if (value == '=') {
        final res = CalculatorParser.evaluateExpression(_manualInput);
        if (res != null) {
          _manualResult = CalculatorParser.formatResult(res);
          _addToHistory(_manualInput, _manualResult);
        } else {
          _manualResult = 'Lỗi';
        }
      } else {
        _manualInput += value;
        final res = CalculatorParser.evaluateExpression(_manualInput);
        if (res != null) {
          _manualResult = CalculatorParser.formatResult(res);
        }
      }
    });
  }

  void _showHistoryBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A192F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB), size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Lịch sử tính toán',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  if (_historyList.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _historyList.clear();
                        });
                        setModalState(() {});
                      },
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Xóa hết',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: borderColor),
              const SizedBox(height: 8),
              Expanded(
                child: _historyList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off_rounded, size: 48, color: subtitleColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'Chưa có lịch sử tính toán nào',
                              style: TextStyle(color: subtitleColor, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _historyList.length,
                        separatorBuilder: (context, index) => Divider(color: borderColor.withValues(alpha: 0.4)),
                        itemBuilder: (context, index) {
                          final item = _historyList[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (_mode == CalculatorMode.voice) {
                                  _expression = item.expression;
                                  _resultStr = item.result;
                                } else {
                                  _manualInput = item.expression;
                                  _manualResult = item.result;
                                }
                              });
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.expression,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.formattedTime,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '= ${item.result}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
          'Máy tính',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Lịch sử tính toán',
            icon: Icon(Icons.history_rounded, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB), size: 24),
            onPressed: _showHistoryBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Mode Segmented Switcher (Tính thủ công / Giọng nói)
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
                      isSelected: _mode == CalculatorMode.voice,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _mode = CalculatorMode.voice;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      title: 'Tính thủ công',
                      icon: Icons.calculate_outlined,
                      isSelected: _mode == CalculatorMode.manual,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _mode = CalculatorMode.manual;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Mode Content View
            Expanded(
              child: _mode == CalculatorMode.voice
                  ? _buildVoiceCalculatorView(isDark, cardBgColor, textColor, subtitleColor, borderColor)
                  : _buildManualCalculatorView(isDark, cardBgColor, textColor, subtitleColor),
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
                  ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
                  : subtitleColorForTab(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF111827))
                    : subtitleColorForTab(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color subtitleColorForTab(bool isDark) =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  // Voice Calculator View
  Widget _buildVoiceCalculatorView(
    bool isDark,
    Color cardBgColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen Title
                Text(
                  'Tính toán bằng giọng nói',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),

                if (_spokenText.isNotEmpty) ...[
                  // Card 1: Đã nghe được
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
                          'Đã nghe được',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${_wordsOnlyText.isNotEmpty ? _wordsOnlyText : _spokenText}"',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 2: Biểu thức nhận diện
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
                          'Biểu thức nhận diện',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _expression,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF111827),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Result Section
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Kết quả',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _resultStr,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.mic_none_outlined,
                          size: 64,
                          color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hãy nói phép tính của bạn',
                          style: TextStyle(
                            fontSize: 15,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ví dụ: "năm nhân năm"',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[600] : const Color(0xFFD1D5DB),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Voice Mic Button & Label
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: isDark ? Border.all(color: const Color(0xFF00E5FF), width: 1.5) : null,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isListening ? 'Đang lắng nghe...' : 'Chạm để nói phép tính',
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
    );
  }

  // Manual Calculator View with Scrollable Keypad & Flexible Layout
  Widget _buildManualCalculatorView(
    bool isDark,
    Color cardBgColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Display Area
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            _manualInput.isEmpty ? '0' : _manualInput,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _manualResult.isEmpty ? '' : _manualResult,
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Keypad Grid Container
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A192F) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      border: isDark
                          ? Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4), width: 1)
                          : null,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildKeypadRow(['C', '(', ')', '÷'], isDark),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['7', '8', '9', '×'], isDark),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['4', '5', '6', '-'], isDark),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['1', '2', '3', '+'], isDark),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['0', '.', '⌫', '='], isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) => _buildKeypadBtn(key, isDark)).toList(),
    );
  }

  Widget _buildKeypadBtn(String text, bool isDark) {
    final isOperator = ['÷', '×', '-', '+', '='].contains(text);
    final isSpecial = ['C', '(', ')', '⌫'].contains(text);

    Color btnColor = isDark ? const Color(0x2000E5FF) : const Color(0xFFF9FAFB);
    Color textColor = isDark ? Colors.white : const Color(0xFF111827);

    if (text == '=') {
      btnColor = isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB);
      textColor = Colors.white;
    } else if (isOperator) {
      btnColor = isDark ? const Color(0x3300E5FF) : const Color(0xFFEFF6FF);
      textColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);
    } else if (isSpecial) {
      btnColor = isDark ? const Color(0x33FFFFFF) : const Color(0xFFF3F4F6);
      textColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 52,
        child: ElevatedButton(
          onPressed: () => _onKeypadTap(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            elevation: 0,
            side: isDark ? BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)) : BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
