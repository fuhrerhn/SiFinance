import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../chat/presentation/chat_widgets.dart';
import '../data/voice_recorder.dart';

class VoiceLoggingPage extends StatefulWidget {
  const VoiceLoggingPage({super.key});

  @override
  State<VoiceLoggingPage> createState() => _VoiceLoggingPageState();
}

class _VoiceLoggingPageState extends State<VoiceLoggingPage> {
  late final VoiceRecorder _audio = VoiceRecorder(onInterrupted: _interrupted);
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<void>? _playbackComplete;
  Future<void>? _operation;
  String? _feedback;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _suspendAudio);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_operation != null) return;
    final operation = _perform(action);
    setState(() {
      _operation = operation;
    });
    await operation;
  }

  Future<void> _perform(Future<void> Function() action) async {
    _feedback = null;
    try {
      await action();
    } catch (error) {
      debugPrint('Voice Logging: $error');
      _feedback = 'Audio belum dapat diproses. Silakan coba lagi.';
    } finally {
      _operation = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleRecording() => _run(() async {
    if (_audio.isRecording) {
      await _audio.stop();
      if (!_audio.hasRecording) _feedback = 'Belum ada audio yang terekam.';
    } else if (!await _audio.start()) {
      _feedback = 'Izinkan akses mikrofon untuk merekam suara.';
    }
  });

  void _interrupted() {
    if (mounted) setState(() => _feedback = 'Perekaman suara terhenti.');
  }

  Future<void> _togglePlayback() => _run(() async {
    if (_playing) {
      await _audio.stopPlayback();
      _playing = false;
      return;
    }

    _playbackComplete ??= _audio.playbackComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    _playing = true;
    try {
      await _audio.play();
    } catch (_) {
      _playing = false;
      rethrow;
    }
  });

  Future<void> _suspendAudio() async {
    await _operation;
    if (!mounted ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }
    if (!_audio.isRecording && !_playing) return;
    await _run(() async {
      if (_audio.isRecording) await _audio.stop();
      if (_playing) {
        await _audio.stopPlayback();
        _playing = false;
      }
    });
  }

  Future<void> _close() async {
    await _operation;
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    await _run(() async {
      try {
        if (_audio.isRecording) await _audio.cancel();
        if (_playing) await _audio.stopPlayback();
      } finally {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  Future<void> _disposeAudio() async {
    await _operation;
    await _playbackComplete?.cancel();
    try {
      await _audio.dispose();
    } catch (error) {
      debugPrint('Voice Logging cleanup: $error');
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_disposeAudio());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _operation != null;
    final recording = _audio.isRecording;
    final hasRecording = _audio.hasRecording;
    final status = recording
        ? 'SiFinance sedang mendengarkan...'
        : hasRecording
        ? 'Rekaman suara siap diputar'
        : 'Ketuk mikrofon untuk mulai';

    return PopScope(
      canPop: !busy && !recording && !_playing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        body: SafeArea(
          top: !kIsWeb,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  if (kIsWeb) const DesignStatusBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 46),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              'AI Voice Logging',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                height: 1.5,
                                fontWeight: FontWeight.w700,
                                color: chatInk,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 48,
                              height: 46,
                              child: IconButton(
                                tooltip: 'Kembali',
                                onPressed: _close,
                                icon: const DesignIcon('arrow-left'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final height = constraints.maxHeight;
                        final circleSize = math.min(
                          292.0,
                          math.min(
                            math.max(0.0, constraints.maxWidth - 48),
                            height * 0.48,
                          ),
                        );
                        final bottom = math.max(
                          math.min(43.0, height * 0.12),
                          MediaQuery.paddingOf(context).bottom + 12,
                        );
                        return Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, bottom),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.only(
                                    top: math.min(86, height * 86 / 749),
                                  ),
                                  child: Column(
                                    children: [
                                      _Waveform(diameter: circleSize),
                                      const SizedBox(height: 24),
                                      Semantics(
                                        liveRegion: true,
                                        child: Text(
                                          status,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.5,
                                            fontWeight: FontWeight.w600,
                                            color: chatInk,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          'Ikuti tips ini agar lebih akurat, '
                                          'sebutkan tanggal transaksi diikuti '
                                          'transaksi apa yang dilakukan dan '
                                          'nominalnya (cth: kemarin saya membeli '
                                          'buah di supermarket seharga Rp10.000)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.5,
                                            color: Color(0xFF9DA0A7),
                                          ),
                                        ),
                                      ),
                                      if (_feedback case final feedback?)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Semantics(
                                            liveRegion: true,
                                            child: Text(
                                              feedback,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      if (hasRecording)
                                        TextButton.icon(
                                          onPressed: busy
                                              ? null
                                              : _togglePlayback,
                                          icon: Icon(
                                            _playing
                                                ? Icons.stop_rounded
                                                : Icons.play_arrow_rounded,
                                          ),
                                          label: Text(
                                            _playing
                                                ? 'Hentikan pemutaran'
                                                : 'Putar rekaman',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 15,
                                children: [
                                  _VoiceButton(
                                    icon: 'voice-chat',
                                    label: 'Buka AI Chat',
                                    onPressed: _close,
                                  ),
                                  _VoiceButton(
                                    icon: 'voice-mic',
                                    label: recording
                                        ? 'Hentikan rekaman'
                                        : 'Mulai rekaman',
                                    prominent: true,
                                    onPressed: busy || _playing
                                        ? null
                                        : _toggleRecording,
                                  ),
                                  _VoiceButton(
                                    icon: 'voice-close',
                                    label: 'Tutup Voice Logging',
                                    onPressed: _close,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diameter,
    child: FittedBox(
      child: SizedBox.square(
        dimension: 292,
        child: Stack(
          children: [
            const DesignIcon('voice-circle'),
            Positioned(
              left: 107,
              top: 101,
              child: Row(
                spacing: 9.875,
                children: [
                  for (final height in [37.525, 59.25, 90.85, 59.25, 37.525])
                    SizedBox(
                      width: 7.9,
                      height: height,
                      child: const ColoredBox(color: Color(0xFFFCFCFC)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final diameter = prominent ? 56.0 : 38.0;
    return SizedBox.square(
      dimension: prominent ? 56 : 48,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: label,
        onPressed: onPressed,
        icon: Ink(
          width: diameter,
          height: diameter,
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color: prominent ? chatBlue : chatGray,
          ),
          child: Center(child: DesignIcon(icon)),
        ),
      ),
    );
  }
}
