/// Tap dictation: starting → recording → finalizing → idle/error.
sealed class VoiceInputState {
  const VoiceInputState();
}

/// Mic available and ready; nothing in flight.
final class VoiceIdle extends VoiceInputState {
  const VoiceIdle();

  @override
  bool operator ==(Object other) => other is VoiceIdle;

  @override
  int get hashCode => (VoiceIdle).hashCode;
}

/// Native capture is active; composer remains visible.
/// [elapsed] is the running time; [level] is the `0..1` amplitude envelope.
final class VoiceRecording extends VoiceInputState {
  const VoiceRecording({required this.elapsed, required this.level});

  final Duration elapsed;
  final double level;

  @override
  bool operator ==(Object other) =>
      other is VoiceRecording &&
      other.elapsed == elapsed &&
      other.level == level;

  @override
  int get hashCode => Object.hash(elapsed, level);
}

/// Capture ended; waiting for native final/done or bounded partial fallback.
final class VoiceTranscribing extends VoiceInputState {
  const VoiceTranscribing();

  @override
  bool operator ==(Object other) => other is VoiceTranscribing;

  @override
  int get hashCode => (VoiceTranscribing).hashCode;
}

/// Why voice input can't be used right now.
enum VoiceUnavailableReason {
  /// Mic / speech permission denied (decision #10) — mic stays visible, tap
  /// guides to system Settings.
  permissionDenied,

  /// No on-device recognition for any acceptable locale (decision #9, edge) —
  /// the mic is hidden.
  unsupported,
}

final class VoiceUnavailable extends VoiceInputState {
  const VoiceUnavailable(this.reason);

  final VoiceUnavailableReason reason;

  @override
  bool operator ==(Object other) =>
      other is VoiceUnavailable && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Initialization/permission is pending, not yet listening.
final class VoiceStarting extends VoiceInputState {
  const VoiceStarting();
  @override
  bool operator ==(Object other) => other is VoiceStarting;
  @override
  int get hashCode => (VoiceStarting).hashCode;
}

/// Recognition ended with an error. Already-visible words are retained.
final class VoiceFailed extends VoiceInputState {
  const VoiceFailed();
  @override
  bool operator ==(Object other) => other is VoiceFailed;
  @override
  int get hashCode => (VoiceFailed).hashCode;
}
