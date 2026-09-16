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

  testWidgets('press, release, and toggle fire on pointer events', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CuelumeListener(
              press: SoundName.press,
              release: SoundName.release,
              toggle: SoundName.toggle,
              child: SizedBox(width: 80, height: 80),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SizedBox));
    await tester.pump();

    expect(playback.plays, hasLength(3));
  });

  testWidgets('hover ignores touch and throttles mouse enters', (tester) async {
    var now = DateTime(2026, 1, 1, 12);
    resetHoverThrottle(now: () => now);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CuelumeListener(
              hover: SoundName.whisper,
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
