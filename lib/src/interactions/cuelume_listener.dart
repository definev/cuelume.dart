import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../audio/engine.dart';
import '../sounds/recipes.dart';

/// Pointer-aware interaction binding, the Flutter equivalent of `bind()`.
///
/// | Intent   | Default sound | Fires on |
/// | -------- | ------------- | -------- |
/// | hover    | [SoundName.chime] | mouse/trackpad enter, 150 ms global throttle |
/// | press    | [SoundName.press] | pointer down |
/// | release  | [SoundName.release] | pointer up |
/// | toggle   | [SoundName.toggle] | tap |
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
  /// Pass [SoundName.chime] (or any name) to enable; defaults are applied
  /// when the named intent is non-null.
  final SoundName? hover;

  /// Sound to play on pointer down.
  final SoundName? press;

  /// Sound to play on pointer up.
  final SoundName? release;

  /// Sound to play on tap, including keyboard activation of buttons.
  final SoundName? toggle;

  final HitTestBehavior behavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget built = child;

    if (press != null || release != null) {
      built = Listener(
        behavior: behavior,
        onPointerDown: press == null
            ? null
            : (_) => Cuelume.play(press!),
        onPointerUp: release == null
            ? null
            : (_) => Cuelume.play(release!),
        child: built,
      );
    }

    if (toggle != null) {
      built = GestureDetector(
        behavior: behavior,
        onTap: () => Cuelume.play(toggle!),
        child: built,
      );
    }

    if (hover != null) {
      built = MouseRegion(
        onEnter: (event) {
          if (!_isFineMouse(event)) return;
          if (!allowHoverPlay()) return;
          Cuelume.play(hover!);
        },
        child: built,
      );
    }

    return built;
  }
}

bool _isFineMouse(PointerEnterEvent event) {
  return event.kind == PointerDeviceKind.mouse;
}
