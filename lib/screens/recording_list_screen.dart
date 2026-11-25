import 'dart:io';
import 'package:flutter/material.dart';
import '../models/recording_model.dart';
import '../services/recordings_service.dart';
import '../services/voice_hybrid_service.dart';
import '../widgets/animated_delete_card.dart';
import 'recording_editor_screen.dart';

class RecordingListScreen extends StatefulWidget {
  const RecordingListScreen({super.key});

  @override
  State<RecordingListScreen> createState() => _RecordingListScreenState();
}

class _RecordingListScreenState extends State<RecordingListScreen> {
  final RecordingsService _recordingsService = RecordingsService();
  final VoiceHybridService _hybridService = VoiceHybridService();

  String? _currentlyPlayingId;

  void _openEditor() async {
    await _hybridService.stopAudioPlayback();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordingEditorScreen(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopPlayback() async {
    await _hybridService.stopAudioPlayback();
    if (mounted) {
      setState(() {
        _currentlyPlayingId = null;
      });
    }
  }

  /// Phát lại âm thanh giọng thật (.m4a) sử dụng just_audio
  Future<void> _togglePlay(RecordingModel recording) async {
    if (_currentlyPlayingId == recording.id) {
      await _stopPlayback();
    } else {
      await _stopPlayback();

      final String path = recording.filePath;
      final bool fileExists = path.isNotEmpty && File(path).existsSync();

      if (fileExists) {
        setState(() {
          _currentlyPlayingId = recording.id;
        });

        if (mounted) {
          _showPlaybackSnackBar('Đang phát giọng âm thật (.m4a): "${recording.title}"');
        }

        await _hybridService.playAudioPath(path);

        if (mounted) {
          setState(() {
            _currentlyPlayingId = null;
          });
        }
      } else {
        if (mounted) {
          _showPlaybackSnackBar('Tệp âm thanh .m4a không còn tồn tại trên thiết bị');
        }
      }
    }
  }

  void _showPlaybackSnackBar(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(left: 16, right: 90, bottom: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordings = _recordingsService.recordings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF020817) : const Color(0xFFFAFAFA);
    final cardBgColor = isDark ? const Color(0x330284C7) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            _stopPlayback();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Ghi âm giọng nói',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: recordings.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mic_none_outlined,
                      size: 64,
                      color: isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có bản ghi âm nào',
                      style: TextStyle(
                        fontSize: 15,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: recordings.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final rec = recordings[index];
                  return _buildRecordingCard(rec, isDark, cardBgColor, textColor, subtitleColor, borderColor);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        backgroundColor: isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
        elevation: 4,
        shape: isDark
            ? const CircleBorder(side: BorderSide(color: Color(0xFF00E5FF), width: 1.5))
            : const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildRecordingCard(
    RecordingModel recording,
    bool isDark,
    Color cardBgColor,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    final isPlaying = _currentlyPlayingId == recording.id;
    final GlobalKey<AnimatedDeleteCardState> deleteKey = GlobalKey();

    return AnimatedDeleteCard(
      key: deleteKey,
      confirmTitle: 'Xoá bản ghi âm',
      confirmMessage: 'Bạn có chắc chắn muốn xoá bản ghi âm "${recording.title}"?',
      onDelete: () async {
        if (_currentlyPlayingId == recording.id) {
          await _stopPlayback();
        }
        await _recordingsService.deleteRecording(recording.id);
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã xoá bản ghi âm thành công!',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(left: 16, right: 90, bottom: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Material(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _togglePlay(recording),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPlaying
                    ? const Color(0xFF00E5FF)
                    : borderColor,
                width: isPlaying ? 2 : (isDark ? 1.5 : 1),
              ),
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
            child: Row(
              children: [
                // Play / Pause Icon Button
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
                        : (isDark ? const Color(0x33000000) : const Color(0xFFFAFAFA)),
                    shape: BoxShape.circle,
                    border: isDark ? Border.all(color: const Color(0xFF00E5FF), width: 1) : null,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow_outlined,
                    color: isPlaying
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? const Color(0xFF00E5FF) : const Color(0xFF1D61E7)),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Title & Subtitle (Duration · Date)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.title.isNotEmpty
                            ? recording.title
                            : 'Ghi âm không tên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPlaying
                              ? (isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB))
                              : textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recording.formattedDuration} · ${recording.formattedDate}',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  tooltip: 'Xoá bản ghi',
                  onPressed: () {
                    deleteKey.currentState?.triggerWithConfirm(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
