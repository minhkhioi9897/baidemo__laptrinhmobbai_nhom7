import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/journal_model.dart';
import '../services/journal_service.dart';

class JournalEditorScreen extends StatefulWidget {
  final JournalModel? journal;
  final bool autoStartVoice;

  const JournalEditorScreen({
    super.key,
    this.journal,
    this.autoStartVoice = false,
  });

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final JournalService _journalService = JournalService();
  final TextEditingController _contentController = TextEditingController();

  String _selectedEmoji = '😊';
  final List<String> _emojis = ['😊', '😄', '😐', '😔', '😡', '🥳', '😴', '❤️'];

  // Speech To Text State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  int _listenSeconds = 0;
  Timer? _timer;
  String _baseContent = '';

  @override
  void initState() {
    super.initState();
    if (widget.journal != null) {
      _contentController.text = widget.journal!.content;
      _selectedEmoji = widget.journal!.emoji;
    }

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            _stopListening();
          }
        },
      );
      if (_speechAvailable && widget.autoStartVoice) {
        _startListening();
      }
    } catch (_) {
      _speechAvailable = false;
    }
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _listenSeconds = 0;
      _baseContent = _contentController.text.trim();
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _listenSeconds++;
      });
    });

    if (_speechAvailable) {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            if (val.recognizedWords.isNotEmpty) {
              final recognized = val.recognizedWords;
              if (_baseContent.isEmpty) {
                _contentController.text = recognized;
              } else {
                _contentController.text = '$_baseContent $recognized';
              }
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    }
  }

  void _stopListening() async {
    _timer?.cancel();
    if (_speechAvailable) {
      await _speech.stop();
    }
    setState(() {
      _isListening = false;
    });
  }

  void _saveJournal() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.journal == null) {
      final newJournal = JournalModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        emoji: _selectedEmoji,
        createdAt: DateTime.now(),
      );
      await _journalService.addJournal(newJournal);
    } else {
      final updatedJournal = JournalModel(
        id: widget.journal!.id,
        content: content,
        emoji: _selectedEmoji,
        createdAt: DateTime.now(),
      );
      await _journalService.updateJournal(updatedJournal);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF020817) : const Color(0xFFFAFAFA);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            _saveJournal();
          },
        ),
        title: Text(
          widget.journal == null ? 'Viết nhật ký' : 'Chỉnh sửa nhật ký',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB), size: 26),
            onPressed: _saveJournal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Emoji Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x330284C7) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.3) : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Tâm trạng:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _emojis.map((emoji) {
                          final isSelected = emoji == _selectedEmoji;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEmoji = emoji;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? const Color(0x4000E5FF) : const Color(0xFFEFF6FF))
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB), width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Hôm nay của bạn thế nào? Viết hoặc nói cho tôi nghe nhé...',
                    hintStyle: TextStyle(
                      color: subtitleColor,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Bottom Voice Mic Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A192F) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.3) : const Color(0xFFF3F4F6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? const Color(0xFFEF4444)
                            : (isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB)),
                        shape: BoxShape.circle,
                        border: isDark ? Border.all(color: const Color(0xFF00E5FF), width: 1) : null,
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isListening
                          ? 'Đang lắng nghe... (${_formatTimer(_listenSeconds)})'
                          : 'Chạm mic để nhập bằng giọng nói',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isListening
                            ? const Color(0xFFEF4444)
                            : subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
