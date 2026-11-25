import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

const int sampleRate = 44100;
const int wavHeaderSize = 44;

/// Viết 44 byte đầu chuẩn WAV header PCM 16-bit Mono 44.1 kHz
void writeWavHeader(RandomAccessFile raf, int dataLen) {
  final builder = BytesBuilder();

  void writeString(String s) => builder.add(s.codeUnits);
  void writeInt32(int val) {
    final b = ByteData(4)..setInt32(0, val, Endian.little);
    builder.add(b.buffer.asUint8List());
  }
  void writeInt16(int val) {
    final b = ByteData(2)..setInt16(0, val, Endian.little);
    builder.add(b.buffer.asUint8List());
  }

  writeString('RIFF');
  writeInt32(36 + dataLen);
  writeString('WAVE');
  writeString('fmt ');
  writeInt32(16); // Chunk size
  writeInt16(1);  // PCM format
  writeInt16(1);  // Mono channel
  writeInt32(sampleRate);
  writeInt32(sampleRate * 2); // Byte rate (44100 * 1 * 16/8)
  writeInt16(2);  // Block align
  writeInt16(16); // Bits per sample
  writeString('data');
  writeInt32(dataLen);

  raf.setPositionSync(0);
  raf.writeFromSync(builder.toBytes());
}

class PcmWavRecorder {
  final File file;
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription<Uint8List>? _streamSub;
  RandomAccessFile? _raf;
  int _totalBytes = 0;

  final StreamController<double> _levelController = StreamController<double>.broadcast();
  final StreamController<int> _millisController = StreamController<int>.broadcast();

  Stream<double> get levelStream => _levelController.stream;
  Stream<int> get millisStream => _millisController.stream;

  PcmWavRecorder(this.file);

  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) {
        return false;
      }

      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync(recursive: true);

      _raf = file.openSync(mode: FileMode.write);
      _raf!.writeFromSync(Uint8List(wavHeaderSize)); // Dành 44 byte đầu cho WAV header
      _totalBytes = 0;

      // Thu âm luồng PCM 16-bit thô 44.1kHz mono không lọc/nén
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );

      _streamSub = stream.listen((data) {
        if (_raf == null) return;
        _raf!.writeFromSync(data);
        _totalBytes += data.length;

        // Tính toán đỉnh sóng âm thanh (Peak level 0.0 -> 1.0)
        int maxPeak = 0;
        final byteData = ByteData.sublistView(data);
        for (int i = 0; i < data.length - 1; i += 2) {
          final sample = byteData.getInt16(i, Endian.little);
          maxPeak = max(maxPeak, sample.abs());
        }

        final double currentLevel = maxPeak / 32768.0;
        final int currentMillis = (_totalBytes * 1000) ~/ (sampleRate * 2);

        _levelController.add(currentLevel);
        _millisController.add(currentMillis);
      });

      return true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo thu âm PCM: $e');
      return false;
    }
  }

  Future<void> stop() async {
    await _streamSub?.cancel();
    _streamSub = null;

    try {
      await _recorder.stop();
    } catch (_) {}

    if (_raf != null) {
      writeWavHeader(_raf!, _totalBytes);
      _raf!.closeSync();
      _raf = null;
    }

    _levelController.add(0.0);
  }

  void cancelNow() {
    _streamSub?.cancel();
    _streamSub = null;
    try {
      _recorder.stop();
    } catch (_) {}
    if (_raf != null) {
      try {
        _raf!.closeSync();
      } catch (_) {}
      _raf = null;
    }
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }
}

class PcmWavPlayer {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> play(File file, {required Function() onDone}) async {
    try {
      await _player.stop();
      await _player.setFilePath(file.path);

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          onDone();
        }
      });

      await _player.play();
    } catch (e) {
      debugPrint('Lỗi phát file PCM WAV: $e');
      onDone();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
