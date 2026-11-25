import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/pcm_wav_engine.dart';

class WavRecordScreen extends StatefulWidget {
  final VoidCallback onBack;
  const WavRecordScreen({super.key, required this.onBack});

  @override
  State<WavRecordScreen> createState() => _WavRecordScreenState();
}

class _WavRecordScreenState extends State<WavRecordScreen>
    with SingleTickerProviderStateMixin {
  late Directory _recordingsDir;
  List<File> _files = [];
  PcmWavRecorder? _recorder;
  final PcmWavPlayer _player = PcmWavPlayer();

  String? _currentlyPlayingPath;
  String? _errorMessage;

  double _currentLevel = 0.0;
  int _currentMillis = 0;

  StreamSubscription<double>? _levelSub;
  StreamSubscription<int>? _millisSub;

  final List<String> _removingPaths = [];

  // Theme colors matching Kotlin RecordScreen Compose UI
  static const Color bg1 = Color(0xFFE3F3FD);
  static const Color bg2 = Color(0xFFF7FBFF);
  static const Color line = Color(0xFF8FCBF6);
  static const Color blue1 = Color(0xFF1C9BF0);
  static const Color blue2 = Color(0xFF1E6FE0);
  static const Color ink = Color(0xFF0F1E3A);
  static const Color sub = Color(0xFF1E7FD8);
  static const Color red = Color(0xFFE5484D);
  static const Color redBg = Color(0xFFFDE4E6);

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    _recordingsDir = Directory('${docDir.path}/recordings');
    if (!await _recordingsDir.exists()) {
      await _recordingsDir.create(recursive: true);
    }
    _loadFiles();
  }

  void _loadFiles() {
    if (!_recordingsDir.existsSync()) return;
    final list = _recordingsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.wav'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    setState(() {
      _files = list;
    });
  }

  Future<void> _startRecording() async {
    await _player.stop();
    setState(() {
      _currentlyPlayingPath = null;
      _errorMessage = null;
    });

    final now = DateTime.now();
    final timestamp =
        '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
    final file = File('${_recordingsDir.path}/rec_$timestamp.wav');

    final r = PcmWavRecorder(file);
    final success = await r.start();

    if (success) {
      _recorder = r;
      _levelSub = r.levelStream.listen((lvl) {
        if (mounted) setState(() => _currentLevel = lvl);
      });
      _millisSub = r.millisStream.listen((ms) {
        if (mounted) setState(() => _currentMillis = ms);
      });
      setState(() {});
    } else {
      setState(() {
        _errorMessage = 'Không mở được micro. Có thể app khác đang dùng micro.';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null) return;
    final r = _recorder!;
    _recorder = null;

    await _levelSub?.cancel();
    await _millisSub?.cancel();

    await r.stop();
    _loadFiles();

    setState(() {
      _currentLevel = 0.0;
      _currentMillis = 0;
    });
  }

  void _onMicTap() {
    if (_recorder != null) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _togglePlay(File file) async {
    if (_currentlyPlayingPath == file.path) {
      await _player.stop();
      setState(() {
        _currentlyPlayingPath = null;
      });
    } else {
      await _player.stop();
      setState(() {
        _currentlyPlayingPath = file.path;
      });

      await _player.play(
        file,
        onDone: () {
          if (mounted) {
            setState(() {
              _currentlyPlayingPath = null;
            });
          }
        },
      );
    }
  }

  Future<void> _deleteFile(File file) async {
    if (_currentlyPlayingPath == file.path) {
      await _player.stop();
      _currentlyPlayingPath = null;
    }

    setState(() {
      _removingPaths.add(file.path);
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (file.existsSync()) {
      file.deleteSync();
    }
    _removingPaths.remove(file.path);
    _loadFiles();
  }

  String _formatTimer(int ms) {
    final s = ms ~/ 1000;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  int _fileDurationMs(File f) {
    final len = f.lengthSync();
    final dataLen = max(0, len - wavHeaderSize);
    return (dataLen * 1000) ~/ (sampleRate * 2);
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  void dispose() {
    _levelSub?.cancel();
    _millisSub?.cancel();
    _recorder?.cancelNow();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _recorder != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: ink, size: 28),
                      onPressed: () {
                        _player.stop();
                        _recorder?.cancelNow();
                        widget.onBack();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ghi âm',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),

              // Mic Container Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: line, width: 2),
                  ),
                  child: Column(
                    children: [
                      // Animated Pulsing Mic Box
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Wave Ring based on Peak Volume Level
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              width: 118 + (isRecording ? sqrt(_currentLevel) * 80 : 0),
                              height: 118 + (isRecording ? sqrt(_currentLevel) * 80 : 0),
                              decoration: BoxDecoration(
                                color: blue1.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Main Record Button
                            GestureDetector(
                              onTap: _onMicTap,
                              child: Container(
                                width: 112,
                                height: 112,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isRecording
                                      ? const LinearGradient(
                                          colors: [red, Color(0xFFB02A3A)],
                                        )
                                      : const LinearGradient(
                                          colors: [blue1, blue2],
                                        ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        isRecording ? _formatTimer(_currentMillis) : 'Nhấn để ghi âm',
                        style: TextStyle(
                          fontSize: isRecording ? 34 : 18,
                          fontWeight: FontWeight.w900,
                          color: isRecording ? red : ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chất lượng cao 44.1 kHz · lưu không nén',
                        style: TextStyle(fontSize: 13, color: sub, fontWeight: FontWeight.w500),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Recordings Title
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 20, bottom: 10),
                child: Text(
                  'Bản ghi (${_files.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ink,
                  ),
                ),
              ),

              // Files List
              Expanded(
                child: _files.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có bản ghi nào',
                          style: TextStyle(color: sub, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        itemCount: _files.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          final isRemoving = _removingPaths.contains(file.path);
                          if (isRemoving) return const SizedBox.shrink();

                          return _buildRecordingRow(file, isRecording);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingRow(File file, bool isRecording) {
    final isPlaying = _currentlyPlayingPath == file.path;
    final modified = file.lastModifiedSync();
    final dateStr =
        '${_twoDigits(modified.day)}/${_twoDigits(modified.month)} ${_twoDigits(modified.hour)}:${_twoDigits(modified.minute)}';
    final durationStr = _formatTimer(_fileDurationMs(file));
    final sizeMb = (file.lengthSync() / 1048576.0).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: isRecording ? null : () => _togglePlay(file),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [blue1, blue2]),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bản ghi $dateStr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$durationStr · $sizeMb MB',
                      style: const TextStyle(fontSize: 13, color: sub, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _deleteFile(file),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: redBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded, color: red, size: 22),
                ),
              ),
            ],
          ),
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final totalMs = _fileDurationMs(file);
                  final progress = totalMs > 0 ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0) : 0.0;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: blue1,
                      backgroundColor: line.withValues(alpha: 0.3),
                      minHeight: 6,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
