import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recording_model.dart';
import '../services/recordings_service.dart';

class RecordingEditorScreen extends StatefulWidget {
  const RecordingEditorScreen({super.key});

  @override
  State<RecordingEditorScreen> createState() => _RecordingEditorScreenState();
}

class _RecordingEditorScreenState extends State<RecordingEditorScreen> {
  final RecordingsService _recordingsService = RecordingsService();
  final TextEditingController _titleController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String _recordedFilePath = '';

  @override
  void initState() {
    super.initState();
  }

  /// 1. Xin quyền truy cập Micro (Permissions) & Khởi tạo (Initialization)
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDocDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // 2. Thiết lập định dạng file đầu ra (.m4a AAC-LC) & tần số lấy mẫu (44100Hz)
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 44100,
            bitRate: 128000,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordingSeconds = 0;
          _recordedFilePath = filePath;
        });

        // 3. Điều khiển ghi âm (Control Flow - Timer count)
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isPaused) {
            setState(() {
              _recordingSeconds++;
            });
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng cấp quyền truy cập Microphone để ghi âm!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo thu âm: $e');
    }
  }

  /// Tạm dừng thu âm (Pause Event)
  Future<void> _pauseRecording() async {
    try {
      if (_isRecording && !_isPaused) {
        await _audioRecorder.pause();
        setState(() {
          _isPaused = true;
        });
      } else if (_isRecording && _isPaused) {
        await _audioRecorder.resume();
        setState(() {
          _isPaused = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tạm dừng thu âm: $e');
    }
  }

  /// Dừng thu âm (Stop Event)
  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      final String? path = await _audioRecorder.stop();
      if (path != null && path.isNotEmpty) {
        _recordedFilePath = path;
      }
    } catch (e) {
      debugPrint('Lỗi dừng thu âm: $e');
    }
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }

  /// Dừng lại / Lưu (Stop & Save Flow)
  Future<void> _saveRecording() async {
    if (_isRecording) {
      await _stopRecording();
    }

    final titleText = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Bản ghi âm ${_formatTimer(_recordingSeconds)}';

    final newRecording = RecordingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleText,
      filePath: _recordedFilePath,
      contentText: titleText,
      durationSeconds: _recordingSeconds > 0 ? _recordingSeconds : 1,
      createdAt: DateTime.now(),
    );

    await _recordingsService.addRecording(newRecording);

    if (!mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã lưu bản ghi âm m4a chất lượng cao thành công!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    navigator.pop();
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _titleController.dispose();
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
          onPressed: () async {
            final nav = Navigator.of(context);
            if (_isRecording) {
              await _stopRecording();
            }
            if (!mounted) return;
            nav.pop();
          },
        ),
        title: Text(
          'Ghi âm giọng nói',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _saveRecording,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Lưu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                side: isDark ? const BorderSide(color: Color(0xFF00E5FF), width: 1) : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Big Mic Icon Container
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? (_isPaused
                            ? (isDark ? const Color(0x33F59E0B) : const Color(0xFFFEF3C7))
                            : (isDark ? const Color(0x33EF4444) : const Color(0xFFFEF2F2)))
                        : (isDark ? const Color(0x3300E5FF) : const Color(0xFFEFF6FF)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording
                          ? (_isPaused ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                          : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB)),
                      width: 2.5,
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: (_isPaused ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                                  .withValues(alpha: 0.35),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isRecording
                        ? (_isPaused ? Icons.pause_rounded : Icons.mic)
                        : Icons.mic_none_outlined,
                    size: 64,
                    color: _isRecording
                        ? (_isPaused ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                        : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recording Timer Text
              Text(
                _formatTimer(_recordingSeconds),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                _isRecording
                    ? (_isPaused ? 'Đang tạm dừng thu âm...' : 'Đang thu âm chất lượng cao (.m4a)...')
                    : 'Chạm nút mic bên dưới để bắt đầu thu âm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _isRecording
                      ? (_isPaused ? const Color(0xFFF59E0B) : const Color(0xFFEF4444))
                      : subtitleColor,
                ),
              ),
              const SizedBox(height: 36),

              // Title Input Field
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: isDark ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên / Tiêu đề bản ghi âm:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập tên tiêu đề gợi nhớ...',
                        hintStyle: TextStyle(
                          color: subtitleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 44),

              // Control Action Flow Row: Start / Pause / Stop / Save
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Start / Stop Main Record Button
                  GestureDetector(
                    onTap: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? const Color(0xFFEF4444)
                            : (isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB)),
                        shape: BoxShape.circle,
                        border: isDark ? Border.all(color: const Color(0xFF00E5FF), width: 1.5) : null,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB)))
                                .withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // Pause / Resume Button
                  if (_isRecording)
                    GestureDetector(
                      onTap: _pauseRecording,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isPaused ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                  // Big Save Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _saveRecording,
                      icon: const Icon(Icons.check_circle_outline, size: 22),
                      label: const Text(
                        'LƯU BẢN GHI ÂM',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
