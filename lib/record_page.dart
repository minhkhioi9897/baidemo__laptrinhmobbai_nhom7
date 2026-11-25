import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'fx.dart';
import 'fx_delete.dart';

// Bảng màu cho Chế độ Sáng & Chế độ Tối
const _blue1 = Color(0xFF1C9BF0);
const _blue2 = Color(0xFF1E6FE0);
const _red = Color(0xFFE5484D);
const _blueGrad = LinearGradient(colors: [_blue1, _blue2]);

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});
  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final _rec = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _timer;
  Directory? _dir;

  bool _recording = false;
  double _level = 0; // 0..1 theo độ to của giọng
  int _seconds = 0;
  String? _msg;
  String? _playingPath;
  Duration _pos = Duration.zero, _dur = Duration.zero;
  List<File> _files = [];

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) setState(() { _playingPath = null; _pos = Duration.zero; });
      }
    });
    _player.positionStream.listen((p) { if (mounted) setState(() => _pos = p); });
    _player.durationStream.listen((d) { if (d != null && mounted) setState(() => _dur = d); });
    _init();
  }

  Future<void> _init() async {
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/recordings');
    await _dir!.create(recursive: true);
    _reload();
  }

  void _reload() {
    final list = _dir!
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.wav'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (mounted) setState(() => _files = list);
  }

  Future<void> _start() async {
    if (_dir == null) return;
    // Hộp thoại xin quyền micro sẽ tự hiện ở lần đầu
    if (!await _rec.hasPermission()) {
      setState(() => _msg = 'Cần cấp quyền micro (Cài đặt > Ứng dụng > Quyền) để ghi âm.');
      return;
    }
    await _player.stop();
    final path = '${_dir!.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // không nén => giữ nguyên giọng
          sampleRate: 44100,
          numChannels: 1,
          autoGain: false,      // tắt tự chỉnh to nhỏ
          echoCancel: false,    // tắt khử vọng
          noiseSuppress: false, // tắt lọc ồn để không "ăn" mất tiếng
        ),
        path: path,
      );
    } catch (e) {
      setState(() => _msg = 'Không mở được micro: $e');
      return;
    }
    _ampSub = _rec.onAmplitudeChanged(const Duration(milliseconds: 80)).listen((a) {
      // a.current tính bằng dBFS: -60 (im lặng) .. 0 (rất to)
      final l = ((a.current + 60) / 60).clamp(0.0, 1.0);
      if (mounted) setState(() => _level = l);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() { _recording = true; _seconds = 0; _msg = null; _playingPath = null; });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _ampSub?.cancel();
    await _rec.stop();
    setState(() { _recording = false; _level = 0; });
    _reload();
  }

  Future<void> _togglePlay(File f) async {
    if (_playingPath == f.path) {
      await _player.stop();
      setState(() { _playingPath = null; _pos = Duration.zero; });
    } else {
      setState(() { _playingPath = f.path; _pos = Duration.zero; _dur = Duration.zero; });
      await _player.setFilePath(f.path);
      await _player.play();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _rec.dispose();
    _player.dispose();
    super.dispose();
  }

  String _mmss(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF030918), Color(0xFF060E2A), Color(0xFF0A1238)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F3FD), Color(0xFFF7FBFF)],
          );

    final textColor = isDark ? const Color(0xFFF2F6FF) : const Color(0xFF0F1E3A);
    final subTextColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E7FD8);
    final cardBgColor = isDark ? const Color(0x5A2D4FA8) : Colors.white.withAlpha(190);
    final cardBorderColor = isDark
        ? const Color(0xFF38BDF8).withAlpha(150)
        : const Color(0xFF8FCBF6);

    final ringSize = 118.0 + (_recording ? _level * 80.0 : 0.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              Row(children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: textColor),
                ),
                Text('Ghi âm', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: textColor)),
              ]),
              const SizedBox(height: 8),
              // Thẻ micro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: cardBorderColor, width: 2),
                ),
                child: Column(children: [
                  SizedBox(
                    width: 200, height: 200,
                    child: Stack(alignment: Alignment.center, children: [
                      FxPulseRings(active: _recording, color: _red, size: 112),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 90),
                        width: ringSize, height: ringSize,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _blue1.withAlpha(46)),
                      ),
                      FxPress(
                        onTap: _recording ? _stop : _start,
                        scale: .9,
                        burstColor: Colors.white,
                        radius: BorderRadius.circular(56),
                        child: Container(
                          width: 112, height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _recording
                                ? const LinearGradient(colors: [_red, Color(0xFFB02A3A)])
                                : _blueGrad,
                            border: Border.all(color: Colors.white.withAlpha(204), width: 3),
                          ),
                          child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded,
                              color: Colors.white, size: 52),
                        ),
                      ),
                    ]),
                  ),
                  Text(
                    _recording ? _mmss(_seconds) : 'Nhấn để ghi âm',
                    style: TextStyle(
                      fontSize: _recording ? 34 : 18,
                      fontWeight: FontWeight.w800,
                      color: _recording ? _red : textColor,
                    ),
                  ),
                  Text('Chất lượng cao 44.1 kHz · lưu không nén',
                      style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w500)),
                  if (_msg != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(_msg!, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: _red)),
                    ),
                ]),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 10),
                  child: Text('Bản ghi (${_files.length})',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                ),
              ),
              Expanded(
                child: _files.isEmpty
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text('Chưa có bản ghi nào', style: TextStyle(color: subTextColor)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _files.length,
                        itemBuilder: (_, i) {
                          final f = _files[i];
                          final playing = _playingPath == f.path;
                          return _RecTile(
                            key: ValueKey(f.path),
                            file: f,
                            playing: playing,
                            progress: playing && _dur.inMilliseconds > 0
                                ? (_pos.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0)
                                : 0,
                            enabled: !_recording,
                            isDark: isDark,
                            onPlay: () => _togglePlay(f),
                            onDeleteStart: () {
                              if (playing) {
                                _player.stop();
                                setState(() => _playingPath = null);
                              }
                            },
                            onRemoved: () {
                              f.deleteSync();
                              _reload();
                            },
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RecTile extends StatelessWidget {
  final File file;
  final bool playing, enabled, isDark;
  final double progress;
  final VoidCallback onPlay, onDeleteStart, onRemoved;
  const _RecTile({
    super.key,
    required this.file,
    required this.playing,
    required this.enabled,
    required this.isDark,
    required this.progress,
    required this.onPlay,
    required this.onDeleteStart,
    required this.onRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final f = file;
    final secs = ((f.lengthSync() - 44).clamp(0, 1 << 40)) ~/ (44100 * 2);
    final d = f.lastModifiedSync();
    final title = 'Bản ghi ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final info = '${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}'
        ' · ${(f.lengthSync() / 1048576).toStringAsFixed(1)} MB';

    final tileBgColor = isDark ? const Color(0x5A2D4FA8) : Colors.white.withAlpha(204);
    final tileBorderColor = isDark ? const Color(0xFF38BDF8).withAlpha(150) : const Color(0xFF8FCBF6);
    final titleColor = isDark ? const Color(0xFFF2F6FF) : const Color(0xFF0F1E3A);
    final subColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E7FD8);

    // Giữ nút thùng rác -> thẻ vỡ thành bụi -> xoá file (onRemoved chạy sau khi hiệu ứng xong)
    return FxDeletable(
      onStart: onDeleteStart,
      onDeleted: onRemoved,
      color: _red,
      builder: (context, del) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tileBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tileBorderColor, width: 1.5),
          ),
          child: Column(children: [
            Row(children: [
              FxPress(
                onTap: enabled ? onPlay : null,
                scale: .88,
                burstColor: Colors.white,
                radius: BorderRadius.circular(24),
                child: Opacity(
                  opacity: enabled ? 1 : .4,
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _blueGrad),
                    child: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: titleColor)),
                  Text(info, style: TextStyle(fontSize: 13, color: subColor)),
                ]),
              ),
              del,
            ]),
            if (playing)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 6, color: _blue1, backgroundColor: tileBorderColor.withAlpha(77),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
