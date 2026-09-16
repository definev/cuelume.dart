import 'dart:typed_data';

/// Internal seam between the Cuelume engine and a speaker.
///
/// Production uses SoLoud. Tests use [RecordingCuePlayback]. App code never
/// sees this type.
abstract interface class CuePlayback {
  /// Whether the backend can play immediately without awaiting [ensureReady].
  bool get isReady;

  /// Prepare the backend. Safe to call repeatedly.
  Future<bool> ensureReady();

  /// Mix [pcm] (mono float32). [volume] is the captured play multiplier.
  bool playPcm(
    Float32List pcm, {
    required double volume,
    required int sampleRate,
  });

  /// Tear down resources Cuelume owns. Does not deinit a host-owned engine.
  Future<void> shutdown();
}

/// In-memory adapter for tests. Never opens a device.
final class RecordingCuePlayback implements CuePlayback {
  RecordingCuePlayback({this.ready = true});

  /// When false, [ensureReady] fails and plays are dropped.
  bool ready;

  /// Completer-style latch so tests can delay [ensureReady].
  Future<bool> Function()? onEnsureReady;

  final List<RecordedCue> plays = [];
  int ensureReadyCalls = 0;
  bool shutdownCalled = false;

  @override
  bool get isReady => ready && onEnsureReady == null;

  @override
  Future<bool> ensureReady() async {
    ensureReadyCalls++;
    if (onEnsureReady != null) return onEnsureReady!();
    return ready;
  }

  @override
  bool playPcm(
    Float32List pcm, {
    required double volume,
    required int sampleRate,
  }) {
    plays.add(RecordedCue(pcm: pcm, volume: volume, sampleRate: sampleRate));
    return true;
  }

  @override
  Future<void> shutdown() async {
    shutdownCalled = true;
  }
}

final class RecordedCue {
  const RecordedCue({
    required this.pcm,
    required this.volume,
    required this.sampleRate,
  });

  final Float32List pcm;
  final double volume;
  final int sampleRate;
}
