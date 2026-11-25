import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/note_model.dart';
import '../services/notes_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;
  final bool autoStartVoice;

  const NoteEditorScreen({
    super.key,
    this.note,
    this.autoStartVoice = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NotesService _notesService = NotesService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

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
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
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

  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final finalTitle = title.isNotEmpty ? title : 'Ghi chú mới';

    if (widget.note == null) {
      final newNote = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: finalTitle,
        content: content,
        updatedAt: DateTime.now(),
      );
      await _notesService.addNote(newNote);
    } else {
      final updatedNote = NoteModel(
        id: widget.note!.id,
        title: finalTitle,
        content: content,
        updatedAt: DateTime.now(),
      );
      await _notesService.updateNote(updatedNote);
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
    _titleController.dispose();
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
            _saveNote();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB), size: 26),
            onPressed: _saveNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tiêu đề...',
                        hintStyle: TextStyle(
                          color: subtitleColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Viết ghi chú hoặc bấm mic để nói...',
                        hintStyle: TextStyle(
                          color: subtitleColor,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Voice Bar
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
                          : 'Chạm mic để thêm bằng giọng nói',
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
