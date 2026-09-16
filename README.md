# Cuelume

Twenty-one carefully designed interaction sounds for Flutter. Synthesized live,
with no audio files.

Cuelume is a curated sound palette, not an audio engine. It gives buttons,
toggles, and completed actions clear feedback without asking you to design
sounds. Call `play()`, wrap a listener, done.

This is a Flutter port of [Danilaa1/cuelume](https://github.com/Danilaa1/cuelume).

## Install

```yaml
dependencies:
  cuelume: ^1.0.0
```

```dart
import 'package:cuelume/cuelume.dart';
```

## Quick start

Play sounds imperatively:

```dart
Cuelume.play(SoundName.success);
Cuelume.play(SoundName.success, volume: 0.4); // quieter for this play only
```

Or bind them to a widget:

```dart
CuelumeListener(
  press: SoundSpec.custom(SoundName.press, volume: 0.5),
  release: SoundSpec.system(SoundName.release),
  child: const Text('Save'),
)
```

| Intent | Fires on | Default sound |
| --- | --- | --- |
| `hover` | mouse enter (fine pointer, throttled) | `chime` |
| `press` | pointer down | `press` |
| `release` | pointer up | `release` |
| `toggle` | tap | `toggle` |

Each intent takes a `SoundSpec`: `SoundSpec.system(name)` for global volume only, or `SoundSpec.custom(name, volume: x)` for a per-play scale.

Need sound preferences? Your app owns the settings; Cuelume only applies them:

```dart
Cuelume.setVolume(0.7);    // global multiplier, clamped to 0–1
Cuelume.setEnabled(false); // future play attempts become no-ops
Cuelume.setEnabled(true);
```

Cuelume starts enabled at full volume and does not read or write storage.

Optional eager init, if you want the first cue to skip backend startup:

```dart
await Cuelume.warmup();
```

## Sounds

| Name | Character | Suggested use |
| --- | --- | --- |
| `chime` | Soft two-note ascending bell | Default hover |
| `sparkle` | Quick four-note twinkle | Playful accents |
| `droplet` | Single note gliding down | Dismiss, collapse |
| `bloom` | Warm slow swell | Reveal, expand |
| `whisper` | Soft hush with a falling tone | Tooltips and quiet previews |
| `tick` | Crisp instant tick | Nav and menu hover |
| `press` | Dull muted knock | Pointer down |
| `release` | Brighter springy tick | Pointer up |
| `toggle` | Mechanical click-clack | Switches, tabs |
| `success` | Warm three-note confirmation | After an action succeeds |
| `error` | Soft knock and descending refusal | Recoverable errors |
| `page` | Papery flick with a glass tick | Pages, galleries, carousels |
| `loading` | Brief unresolved rising shimmer | User-initiated work starting |
| `ready` | Rising lock-on with a clear resolve | Content or system ready |
| `pulse` | Compact synthetic chirp | Primary buttons and controls |
| `scan` | Fast three-step locator signal | Menus and secondary buttons |
| `arrival` | Rising harmonic portal | Route arrivals |
| `focus` | Soft two-note selection ping | Keyboard focus and selection |
| `attention` | Gentle double pulse | Non-error attention states |
| `notification` | Bright two-note incoming bell | Notifications and external events |
| `cancel` | Low descending two-hit cue | Cancel, undo, intentional dismissal |

## Example

An interactive Flutter web example is included in [`example/`](example/). It
uses a custom neon/terminal UI (no stock Material controls), a lightweight
signal visualizer, a four-step sound arc, and covers imperative playback,
`CuelumeListener`, `Cuelume.wrap`, volume and enabled preferences, and all
twenty-one sounds in the palette.

```sh
cd example
flutter pub get
flutter run -d chrome
```

## API

```dart
Cuelume.play(sound, {volume});
Cuelume.setEnabled(enabled);
Cuelume.setVolume(volume);
Cuelume.warmup();
Cuelume.wrap(callback, [sound]);
Cuelume.sounds; // List<SoundName>
```

- **`play`** — play a sound immediately.
- **`setEnabled`** — enable or disable future playback. Does not persist or stop sounds already playing.
- **`setVolume`** — global volume for future playback, clamped to `0–1`. Non-finite values are ignored.
- **`CuelumeListener`** — hover / press / release / toggle binding. Each intent is a `SoundSpec`.
- **`wrap`** — play on an existing `VoidCallback`, then call it.

## Defaults that behave

- **Pointer-aware.** Hover is mouse/trackpad on desktop. Press and release support mouse, touch, and pen. Toggle follows tap, including keyboard activation of buttons.
- **Hover repeat guard.** Hover sounds are globally throttled to one every 150ms.
- **Audible without clipping.** One shared boosted compressor on a dedicated SoLoud bus.
- **Lazy backend.** SoLoud is created on first use, or reused if the host already initialized it.
- **Safe fallback.** Missing audio backends make `play()` a silent no-op.

## License

MIT. Palette and recipes by Daniel Belyi; Flutter port by definev.
