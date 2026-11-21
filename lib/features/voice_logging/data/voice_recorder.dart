import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'recording_file.dart'
    if (dart.library.js_interop) 'recording_file_web.dart';

class VoiceRecorder {
  VoiceRecorder({required this.onInterrupted});

  final VoidCallback onInterrupted;
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  StreamSubscription<RecordStop>? _recordingEnd;
  String? _capturePath;
  String? _recordingPath;
  bool _recording = false;

  bool get isRecording => _recording;
  bool get hasRecording => _recordingPath != null;

  AudioPlayer get _audioPlayer => _player ??= AudioPlayer();
  Stream<void> get playbackComplete => _audioPlayer.onPlayerComplete;

  Future<bool> start() async {
    final recorder = _recorder ??= AudioRecorder();
    if (!await recorder.hasPermission()) return false;

    _recordingEnd ??= recorder.onStopped().listen((take) {
      if (take.reason == RecordStopReason.stop) return;
      _recording = false;
      _recordingPath = take.path;
      onInterrupted();
    });

    await _player?.release();
    await _clearRecording();
    final path = await createRecordingPath();
    _capturePath = path;
    _recording = true;
    try {
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
        path: path,
      );
    } catch (_) {
      await cancel();
      rethrow;
    }
    return true;
  }

  Future<void> stop() async {
    final path = await _recorder!.stop();
    _recordingPath = path ?? _recordingPath;
    _recording = false;
  }

  Future<void> cancel() async {
    if (!_recording) return;
    await _recorder!.cancel();
    _recording = false;
  }

  Future<void> play() async {
    final path = _recordingPath!;
    await _audioPlayer.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path));
  }

  Future<void> stopPlayback() async => _player?.stop();

  Future<void> _clearRecording() async {
    final path = _recordingPath ?? _capturePath;
    if (path != null && path.isNotEmpty) await deleteRecording(path);
    _recordingPath = null;
    _capturePath = null;
  }

  Future<void> dispose() async {
    await _recordingEnd?.cancel();
    try {
      await cancel();
    } finally {
      try {
        await _recorder?.dispose();
      } finally {
        try {
          await _player?.dispose();
        } finally {
          await _clearRecording();
        }
      }
    }
  }
}
