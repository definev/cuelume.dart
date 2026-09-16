import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../sounds/recipes.dart';
import 'playback.dart';
import 'renderer.dart';
import 'soloud_playback.dart';

/// Curated interaction sounds. The public module is this type's statics.
final class Cuelume {
  Cuelume._();

  static bool _enabled = true;
  static double _volume = 1;
  static CuePlayback _playback = SoloudCuePlayback();
  static Random? _random;
  static Future<bool>? _ready;

  /// The twenty-one recipe names, in palette order.
  static List<SoundName> get sounds => SoundName.values;

  /// Enables or disables future playback. Preference storage stays with the app.
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Sets the volume multiplier for future playback, clamped to `0–1`.
  /// Non-finite values are ignored. Preferences are not persisted.
  static void setVolume(double volume) {
    if (volume.isFinite) {
      _volume = volume.clamp(0.0, 1.0);
    }
  }

  /// Optional eager backend init. [play] also warms up on first use.
  static Future<void> warmup() async {
    await _ensureReady();
  }

  /// Plays a sound immediately. Defaults to [SoundName.chime].
  ///
  /// [volume] scales this play only, then multiplies the global volume.
  /// Missing backends, disabled playback, and zero volume are silent no-ops.
  static void play(SoundName sound, {double? volume}) {
    if (!_enabled) return;
    final playVolume = _volume * _normalizeVolume(volume, 1);
    if (playVolume == 0) return;

    final recipe = recipes[sound]!;
    final pcm = renderRecipe(recipe, random: _random);
    _dispatch(pcm, playVolume);
  }

  /// Returns a callback that plays [sound] then invokes [callback].
  static VoidCallback wrap(
    VoidCallback callback, [
    SoundName sound = SoundName.toggle,
  ]) {
    return () {
      play(sound);
      callback();
    };
  }

  static void _dispatch(Float32List pcm, double playVolume) {
    if (_playback.isReady) {
      _tryPlay(pcm, playVolume);
      return;
    }
    unawaited(
      _ensureReady().then((ok) {
        if (!ok || !_enabled) return;
        _tryPlay(pcm, playVolume);
      }, onError: (_) {}),
    );
  }

  static void _tryPlay(Float32List pcm, double playVolume) {
    try {
      _playback.playPcm(pcm, volume: playVolume, sampleRate: cuelumeSampleRate);
    } catch (_) {}
  }

  static Future<bool> _ensureReady() {
    return _ready ??= Future(() async {
      try {
        final ok = await _playback.ensureReady();
        if (!ok) _ready = null;
        return ok;
      } catch (_) {
        _ready = null;
        return false;
      }
    });
  }

  static double _normalizeVolume(double? value, double fallback) {
    if (value == null || !value.isFinite) return fallback;
    return value.clamp(0.0, 1.0);
  }

  /// Test-only: swap the playback adapter and reset engine state.
  @visibleForTesting
  static void debugReset({
    CuePlayback? playback,
    Random? random,
    bool enabled = true,
    double volume = 1,
  }) {
    _playback = playback ?? SoloudCuePlayback();
    _random = random;
    _enabled = enabled;
    _volume = volume;
    _ready = null;
    resetHoverThrottle();
  }

  @visibleForTesting
  static CuePlayback get debugPlayback => _playback;

  @visibleForTesting
  static bool get debugEnabled => _enabled;

  @visibleForTesting
  static double get debugVolume => _volume;
}

/// Matches upstream hover throttling.
const Duration hoverGap = Duration(milliseconds: 150);

DateTime? _lastHoverAt;
DateTime Function() _hoverNow = DateTime.now;

/// Returns whether a hover cue should play, then records the attempt.
bool allowHoverPlay() {
  final now = _hoverNow();
  final last = _lastHoverAt;
  if (last != null && now.difference(last) < hoverGap) return false;
  _lastHoverAt = now;
  return true;
}

@visibleForTesting
void resetHoverThrottle({DateTime Function()? now}) {
  _lastHoverAt = null;
  _hoverNow = now ?? DateTime.now;
}
