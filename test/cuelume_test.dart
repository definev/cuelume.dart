import 'dart:async';

import 'package:cuelume/cuelume.dart';
import 'package:cuelume/src/audio/engine.dart';
import 'package:cuelume/src/audio/playback.dart';
import 'package:cuelume/src/audio/renderer.dart';
import 'package:cuelume/src/sounds/recipes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecordingCuePlayback playback;

  setUp(() {
    playback = RecordingCuePlayback();
    Cuelume.debugReset(playback: playback);
  });

  test('expanded palette exposes sci-fi interaction and arrival cues', () {
    expect(Cuelume.sounds, hasLength(21));
    expect(Cuelume.sounds.sublist(14), [
      SoundName.pulse,
      SoundName.scan,
      SoundName.arrival,
      SoundName.focus,
      SoundName.attention,
      SoundName.notification,
      SoundName.cancel,
    ]);
    expect(sounds, Cuelume.sounds);
  });

  test('SoundSpec.system has no volume; custom carries one', () {
    const system = SoundSpec.system(SoundName.press);
    const custom = SoundSpec.custom(SoundName.press, volume: 0.4);

    expect(system, const SoundSpec.system(SoundName.press));
    expect(system, isNot(custom));
    expect(system.name, SoundName.press);
    expect(custom.name, SoundName.press);

    switch (system) {
      case SystemSoundSpec(:final name):
        expect(name, SoundName.press);
        expect(system.volume, isNull);
      case CustomSoundSpec():
        fail('system spec must not match custom');
    }

    switch (custom) {
      case CustomSoundSpec(:final name, :final volume):
        expect(name, SoundName.press);
        expect(volume, 0.4);
      case SystemSoundSpec():
        fail('custom spec must not match system');
    }
  });

  test('invalid volume and disabled playback are silent', () {
    Cuelume.setEnabled(false);
    Cuelume.play(SoundName.chime);
    expect(playback.plays, isEmpty);

    Cuelume.setEnabled(true);
    Cuelume.setVolume(0);
    Cuelume.play(SoundName.chime);
    expect(playback.plays, isEmpty);

    Cuelume.setVolume(1);
    Cuelume.play(SoundName.press, volume: 0);
    expect(playback.plays, isEmpty);
  });

  test('volume is clamped and captured at play time', () {
    Cuelume.setVolume(2);
    Cuelume.play(SoundName.press, volume: 0.5);
    Cuelume.setVolume(0.5);
    Cuelume.play(SoundName.press, volume: 0.5);
    Cuelume.play(SoundName.press, volume: 2);
    Cuelume.play(SoundName.press, volume: double.nan);
    Cuelume.setVolume(-1);
    Cuelume.setVolume(double.nan);
    Cuelume.setVolume(double.infinity);
    Cuelume.play(SoundName.press);

    expect(playback.plays.map((play) => play.volume).toList(), [
      0.5,
      0.25,
      0.5,
      0.5,
    ]);
  });

  test('play waits for a deferred backend then re-checks enabled', () async {
    final gate = Completer<bool>();
    playback.ready = false;
    playback.onEnsureReady = () => gate.future;
    Cuelume.debugReset(playback: playback);

    Cuelume.play(SoundName.chime);
    expect(playback.plays, isEmpty);

    Cuelume.setEnabled(false);
    gate.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(playback.plays, isEmpty);
  });

  test('deferred backend plays after it becomes ready', () async {
    final gate = Completer<bool>();
    playback.ready = false;
    playback.onEnsureReady = () => gate.future;
    Cuelume.debugReset(playback: playback);

    Cuelume.play(SoundName.chime);
    expect(playback.plays, isEmpty);
    playback.ready = true;
    gate.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(playback.plays, hasLength(1));
  });

  test('hover is globally throttled to 150ms', () {
    var now = DateTime(2026, 1, 1, 12);
    resetHoverThrottle(now: () => now);

    expect(allowHoverPlay(), isTrue);
    now = now.add(const Duration(milliseconds: 100));
    expect(allowHoverPlay(), isFalse);
    now = now.add(const Duration(milliseconds: 51));
    expect(allowHoverPlay(), isTrue);
  });

  test('chime cleanup duration matches upstream', () {
    final ms = (recipeDuration(recipes[SoundName.chime]!) * 1000).round();
    expect(ms, 1176);
  });

  test('every recipe renders a non-empty buffer', () {
    for (final name in SoundName.values) {
      final pcm = renderRecipe(recipes[name]!);
      expect(pcm, isNotEmpty, reason: name.name);
      expect(pcm.any((sample) => sample != 0), isTrue, reason: name.name);
    }
  });
}
