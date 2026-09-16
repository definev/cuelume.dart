import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../audio/engine.dart';
import '../sounds/sound_spec.dart';

/// Pointer-aware interaction binding, the Flutter equivalent of `bind()`.
///
/// | Intent   | Default sound | Fires on |
/// | -------- | ------------- | -------- |
/// | hover    | [SoundName.chime] | mouse/trackpad enter, 150 ms global throttle |
/// | press    | [SoundName.press] | pointer down |
/// | release  | [SoundName.release] | pointer up |
/// | toggle   | [SoundName.toggle] | tap |
///
/// Each intent takes a [SoundSpec]: [SoundSpec.system] for global volume only,
/// or [SoundSpec.custom] for a per-play scale.
class CuelumeListener extends StatelessWidget {
  const CuelumeListener({
    super.key,
    this.hover,
    this.press,
    this.release,
    this.toggle,
    this.behavior = HitTestBehavior.deferToChild,
    required this.child,
  });

  /// Sound to play on fine-pointer enter. `null` disables hover.
  final SoundSpec? hover;

  /// Sound to play on pointer down.
  final SoundSpec? press;

  /// Sound to play on pointer up.
  final SoundSpec? release;

  /// Sound to play on tap, including keyboard activation of buttons.
  final SoundSpec? toggle;

  /// How this listener participates in hit testing. Passed to the inner
  /// [Listener] and [GestureDetector] when those intents are bound.
  final HitTestBehavior behavior;

  /// The widget that receives pointer and hover events.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget built = child;

    if (press != null || release != null) {
      built = Listener(
        behavior: behavior,
        onPointerDown: press == null ? null : (_) => _play(press!),
        onPointerUp: release == null ? null : (_) => _play(release!),
        child: built,
      );
    }

    if (toggle != null) {
      built = GestureDetector(
        behavior: behavior,
        onTap: () => _play(toggle!),
        child: built,
      );
    }

    if (hover != null) {
      built = MouseRegion(
        onEnter: (event) {
          if (!_isFineMouse(event)) return;
          if (!allowHoverPlay()) return;
          _play(hover!);
        },
        child: built,
      );
    }

    return built;
  }

  static void _play(SoundSpec spec) {
    switch (spec) {
      case SystemSoundSpec(:final name):
        Cuelume.play(name);
      case CustomSoundSpec(:final name, :final volume):
        Cuelume.play(name, volume: volume);
    }
  }
}

bool _isFineMouse(PointerEnterEvent event) {
  return event.kind == PointerDeviceKind.mouse;
}
