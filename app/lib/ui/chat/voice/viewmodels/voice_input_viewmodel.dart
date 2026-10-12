import 'dart:async';

import 'package:app/data/voice/speech_service.dart';
import 'package:app/ui/chat/voice/states/voice_input_state.dart';
import 'package:app/ui/core/viewmodel/viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Tap-toggle local dictation. Every hypothesis is cumulative, never a send.
class VoiceInputViewModel extends ViewModel<VoiceInputState> {
  VoiceInputViewModel(
    this._service, {
    this.maxDuration = const Duration(seconds: 60),
    Duration tickInterval = const Duration(milliseconds: 200),
  }) : _tickInterval = tickInterval,
       super(const VoiceIdle());

  final SpeechService _service;
  final Duration maxDuration;
  final Duration _tickInterval;
  SpeechAvailability? _availability;
  StreamSubscription<double>? _levelSub;
  Timer? _ticker;
  int _generation = 0;
  bool _disposed = false;
  bool _nativeStarted = false;
  bool _captureFailed = false;
  bool _cancelling = false;
  Future<void>? _start;
  Duration _elapsed = Duration.zero;
  double _level = 0;

  final StreamController<String> _transcripts =
      StreamController<String>.broadcast(sync: true);
  Stream<String> get transcripts => _transcripts.stream;
  bool get active =>
      state is VoiceStarting ||
      state is VoiceRecording ||
      state is VoiceTranscribing;

  Future<SpeechAvailability> ensureInit() async {
    final cached = _availability;
    if (cached is SpeechReady) return cached;
    final generation = _generation;
    final result = await _service.init();
    if (_disposed || generation != _generation) return result;
    _availability = result;
    switch (result) {
      case SpeechReady():
        if (state is VoiceUnavailable) emit(const VoiceIdle());
      case SpeechPermissionDenied():
        emit(const VoiceUnavailable(VoiceUnavailableReason.permissionDenied));
      case SpeechUnsupported():
        emit(const VoiceUnavailable(VoiceUnavailableReason.unsupported));
    }
    return result;
  }

  Future<void> startRecording() {
    if (_disposed || active) return Future<void>.value();
    final generation = ++_generation;
    _captureFailed = false;
    emit(const VoiceStarting());
    return _start = _begin(generation);
  }

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<void> _begin(int generation) async {
    try {
      final availability = await ensureInit();
      if (!_current(generation) || availability is! SpeechReady) return;
      _elapsed = Duration.zero;
      _level = 0;
      _levelSub = _service.soundLevel.listen((level) {
        if (!_current(generation)) return;
        _level = level;
        if (state is VoiceRecording) {
          emit(VoiceRecording(elapsed: _elapsed, level: _level));
        }
      });
      _nativeStarted = true;
      var captureEnded = false;
      await _service.start(
        localeId: availability.localeId,
        maxDuration: maxDuration,
        onTranscript: (text) {
          if (_current(generation)) _transcripts.add(text);
        },
        onEnded: () {
          captureEnded = true;
          if (_current(generation)) unawaited(_finish(generation));
        },
        onError: () {
          if (_current(generation)) _captureFailed = true;
        },
      );
      if (!_current(generation) || captureEnded || state is VoiceTranscribing) {
        return;
      }
      emit(VoiceRecording(elapsed: _elapsed, level: _level));
      _ticker = Timer.periodic(_tickInterval, (_) {
        _elapsed += _tickInterval;
        if (_elapsed >= maxDuration) {
          unawaited(stopAndTranscribe());
        } else if (_current(generation) && state is VoiceRecording) {
          emit(VoiceRecording(elapsed: _elapsed, level: _level));
        }
      });
    } on stt.ListenFailedException {
      await _fail(generation);
    } on stt.ListenNotStartedException {
      await _fail(generation);
    } on PlatformException {
      await _fail(generation);
    }
  }

  Future<void> _fail(int generation) async {
    if (!_current(generation)) return;
    _captureFailed = true;
    await _finish(generation);
  }

  Future<String> stopAndTranscribe() async {
    if (_disposed || _cancelling || !active || state is VoiceTranscribing) {
      return '';
    }
    if (state is VoiceStarting) {
      // Second tap during permission/init cancels intent. No capture starts
      // behind the prompt; don't race a new start against the pending one.
      await cancel();
      return '';
    }
    return _finish(_generation);
  }

  Future<String> _finish(int generation) async {
    if (!_current(generation) || state is VoiceTranscribing) return '';
    _stopTimers();
    emit(const VoiceTranscribing());
    final text = _nativeStarted ? await _service.stop() : '';
    if (!_current(generation)) return '';
    _nativeStarted = false;
    if (text.isNotEmpty) _transcripts.add(text);
    emit(_captureFailed ? const VoiceFailed() : const VoiceIdle());
    return text;
  }

  /// Keeps already-visible words. Cancel invalidates all pending callbacks.
  Future<void> cancel() async {
    if (_disposed || _cancelling || !active) return;
    _cancelling = true;
    final generation = ++_generation;
    _stopTimers();
    // Invalidate synchronously, but don't notify while a composer is unmounting.
    await Future<void>.value();
    if (_current(generation)) emit(const VoiceTranscribing());
    if (_nativeStarted) {
      _nativeStarted = false;
      await _service.cancel();
    }
    await _start;
    _cancelling = false;
    if (_current(generation)) emit(const VoiceIdle());
  }

  void _stopTimers() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_levelSub?.cancel());
    _levelSub = null;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _stopTimers();
    if (_nativeStarted) {
      _nativeStarted = false;
      unawaited(_service.cancel());
    }
    _transcripts.close();
    super.dispose();
  }
}
