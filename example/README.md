# Cuelume example

This app is a small, interactive sound palette for the Cuelume Flutter
package. The screen uses a custom neon/terminal-style UI built from Flutter's
basic widgets and `CustomPainter` rather than stock Material controls. It
demonstrates:

- imperative playback with `Cuelume.play`;
- pointer-aware bindings with `CuelumeListener`;
- composing feedback with `Cuelume.wrap`;
- the global enabled and volume preferences; and
- every sound exposed by `Cuelume.sounds`, including focus, attention,
  notification, and cancel cues.

The demo also includes a four-step sound arc (`loading → ready → pulse →
success`) so the cues can be heard as a small interaction sequence, not only as
isolated buttons.

The live waveform, cue deck, and signal visualizer are deliberately
lightweight: they
provide feedback while you explore the palette, pause automatically when the
platform requests reduced motion, and never affect audio playback.

Run it from this directory with:

```sh
flutter pub get
flutter run -d chrome
```

On the web, start playback from a button after the page has loaded. Browsers
require a user gesture before allowing audio.
