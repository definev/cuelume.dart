import 'package:cuelume/cuelume.dart';
import 'package:cuelume/src/audio/engine.dart';
import 'package:cuelume/src/audio/playback.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RecordingCuePlayback playback;

  setUp(() {
    playback = RecordingCuePlayback();
    Cuelume.debugReset(playback: playback);
  });

  testWidgets('press, release, and toggle fire on pointer events', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CuelumeListener(
              press: .system(SoundName.press),
              release: .system(SoundName.release),
              toggle: .system(SoundName.toggle),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SizedBox), warnIfMissed: false);
    await tester.pump();

    expect(playback.plays, hasLength(3));
  });

  testWidgets('per-intent volume scales each bound cue', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CuelumeListener(
              press: SoundSpec.custom(SoundName.press, volume: 0.25),
              release: SoundSpec.custom(SoundName.release, volume: 0.5),
              toggle: SoundSpec.custom(SoundName.toggle, volume: 0.75),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SizedBox), warnIfMissed: false);
    await tester.pump();

    expect(playback.plays.map((play) => play.volume).toList(), [
      0.25,
      0.5,
      0.75,
    ]);
  });

  testWidgets('hover ignores touch and throttles mouse enters', (tester) async {
    var now = DateTime(2026, 1, 1, 12);
    resetHoverThrottle(now: () => now);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CuelumeListener(
              hover: SoundSpec.custom(SoundName.whisper, volume: 0.4),
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(SizedBox));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(center);
    await tester.pump();
    expect(playback.plays, hasLength(1));
    expect(playback.plays.single.volume, 0.4);

    await gesture.moveTo(Offset.zero);
    await tester.pump();
    now = now.add(const Duration(milliseconds: 100));
    await gesture.moveTo(center);
    await tester.pump();
    expect(playback.plays, hasLength(1));

    now = now.add(const Duration(milliseconds: 51));
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(center);
    await tester.pump();
    expect(playback.plays, hasLength(2));
  });
}
