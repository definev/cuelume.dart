# ADR-0001: Port Cuelume as a deep Flutter module over a SoLoud playback adapter

- Status: Accepted
- Date: 2026-09-14
- Decision owners: definev/cuelume
- Upstream palette: [Danilaa1/cuelume 0.2.2](https://github.com/Danilaa1/cuelume)

## Context

Upstream Cuelume is a curated UI-sound **module**, not a general audio engine. Its
value is a 17-recipe palette plus the defaults around it: live synthesis, no
audio files, one shared output stage, silent failure, and pointer-aware
hover/press/release/toggle binding.

The upstream implementation is inseparable from the Web Audio graph:

- tone layers via `OscillatorNode` (sine/triangle, detune, exponential glide)
- noise layers via a white-noise buffer and `BiquadFilterNode`
- exponential attack/decay envelopes
- a per-recipe delay/feedback/lowpass shimmer send
- one boosted output (`gain = 4`) into a shared `DynamicsCompressorNode`

Flutter has no Web Audio. A naive port would either ship `.wav` assets or
call a generic file player. Both flatten Cuelume into a shallow pass-through:
callers would have to own synthesis, mixing, throttling, and output protection,
and the palette would drift from upstream.

This package must therefore decide:

1. What sits behind the public **interface**.
2. Where the **seam** with platform audio lives.
3. Which **adapter** plays samples without becoming the product.

## Decision drivers

1. Keep the public interface as small as upstream: play, enable, volume, the
   sound list, and interaction binding.
2. Preserve recipe identity. `chime` must remain a two-note bell with a shimmer
   tail, not a different click from a third-party pack.
3. Make the palette and renderer testable without a device, plugin, or audio
   session.
4. Overlapping cues (press + release, menu sweep) must mix instead of cutting
   each other off.
5. Host apps that already use SoLoud must not have their global filters or
   engine lifecycle stolen.
6. Invalid names, disabled playback, and missing audio backends stay silent
   no-ops.
7. Zero shipped audio files. The package remains a synthesizer.

## Decision

Cuelume on Flutter is a **deep module** with a small interface and a large
hidden implementation. Platform audio is an internal **adapter** behind a
playback **seam**, not part of the interface.

### Public interface

Callers learn four imperative operations and one widget:

- `Cuelume.play(sound, {volume})` — play a recipe now. Defaults to `chime`.
- `Cuelume.setEnabled(enabled)` — future plays become no-ops when false.
- `Cuelume.setVolume(volume)` — global multiplier, clamped to `0–1`. Non-finite
  values are ignored. Preferences are not persisted.
- `Cuelume.sounds` / `SoundName` — the seventeen recipe names.
- `CuelumeListener` — hover / press / release / toggle binding, with the same
  defaults as `data-cuelume-*`.
- `Cuelume.wrap(callback, sound)` — play on an existing `VoidCallback`.
- `Cuelume.warmup()` — optional eager backend init.

That is the whole interface. Recipes, envelopes, biquads, delay lines, sample
rate, mixing buses, and SoLoud types are implementation.

### Implementation depth

Behind the interface the module owns:

1. **Recipes** — a 1:1 Dart transcription of upstream `RECIPES`. Adding a sound
   means adding a recipe, not touching playback.
2. **Offline renderer** — a Web Audio-equivalent graph rendered to mono PCM at
   44100 Hz: oscillators, filtered noise, exponential ramps, and shimmer. This
   is in-process and deterministic aside from noise seeds.
3. **Engine policy** — enable/volume clamping, captured play volume, re-check
   enabled after async backend start, silent catch of backend failures.
4. **Interaction policy** — fine-pointer hover, 150 ms global hover throttle,
   press/release for mouse/touch/pen, toggle on tap.

Deleting this module would re-scatter synthesis, mixing, and pointer policy
across every button in the host app. It passes the deletion test.

### Playback seam

Rendering PCM is not the same problem as getting it out of a speaker. Those
vary independently, so they meet at an internal seam:

```text
Cuelume.play
    → recipes + renderer + engine policy
        → CuePlayback.ensureReady / playPcm / shutdown
```

Two **adapters** justify the seam:

| Adapter | Role |
| --- | --- |
| `SoloudCuePlayback` | Production. Mixes overlapping cues, applies the shared boosted compressor, plays on Android/iOS/desktop/web. |
| `RecordingCuePlayback` | Tests. Records PCM and volume so engine tests never touch a device. |

A third silent adapter is allowed for hosts that want the API compiled in but
audio compiled out. One adapter would have been hypothetical indirection; two
make the seam real.

The seam is **internal**. Tests of engine policy may inject an adapter. App
code may not.

### Why flutter_soloud

SoLoud is chosen as the production adapter because it supplies the behaviour
the renderer should not have to reimplement:

- many overlapping one-shot voices with low latency
- a dedicated mixing bus so Cuelume can own a compressor without becoming the
  host's master bus
- PCM buffer streams (`f32le`) so live-rendered recipes never become assets
- Android, iOS, macOS, Linux, Windows, and web

Cuelume initializes SoLoud only when the host has not already done so. It
plays through a bus named `cuelume`. Shared-output protection lives on that
bus (makeup ≈ +12 dB for upstream's `OUTPUT_GAIN = 4`, compressor close to
threshold `-8`, knee `6`, ratio `12` clamped to SoLoud's max `10`, attack
`2 ms`, release `80 ms`). If the host already owns the engine, Cuelume does
not deinit it, does not retune global filters, and does not lower the voice
limit.

Live SoLoud oscillators are **not** used as the synthesizer. They cannot
express the noise + biquad + shimmer graph. Using them would make SoLoud the
product and the palette an approximation.

### Live render, not baked files

Each `play` renders PCM on the fly, matching upstream's "no audio files"
contract and preserving per-play noise. Volume is captured at the call, as in
upstream's `renderRecipe(context, recipe, playVolume)`. Enabled is re-checked
after the backend becomes ready, matching upstream's resume path.

### Flutter binding replaces DOM binding

`bind()` is a browser module. Flutter's equivalent is a widget at the same
abstraction level, not a new sound engine:

| Upstream | Flutter |
| --- | --- |
| `data-cuelume-hover` on `pointerenter` | `CuelumeListener.hover` via `MouseRegion`, mouse/fine pointer only |
| `data-cuelume-press` on `pointerdown` | `CuelumeListener.press` via `Listener.onPointerDown` |
| `data-cuelume-release` on `pointerup` | `CuelumeListener.release` via `Listener.onPointerUp` |
| `data-cuelume-toggle` on `click` | `CuelumeListener.toggle` via `GestureDetector.onTap`, or `Cuelume.wrap` on a button callback |

Hover remains globally throttled to one play / 150 ms.

## Consequences

### Positive

- Callers get the whole palette from one enum and one `play` call.
- Recipe changes stay local. Playback changes stay in one adapter.
- Renderer tests run in `flutter test` without plugins or devices.
- Host SoLoud users can coexist via the dedicated bus and lazy init.
- The package can follow upstream recipe edits without rewriting audio code.

### Negative

- `flutter_soloud` is a native plugin. This cannot be a pure Dart package.
- Offline PCM is a discrete-time translation of Web Audio. It will be very
  close, not bit-identical to Chromium's oscillators and biquads.
- SoLoud's compressor ratio tops out at 10:1 versus upstream's 12:1.
- Bus filters on web may be unavailable. The adapter then falls back to linear
  makeup gain without a shared compressor.
- Live rendering pays a small CPU cost per play (short UI cues, typically
  < 2 s at 44100 Hz).

### Neutral

- Sample rate is fixed at 44100 Hz to match SoLoud's default init. A later ADR
  is required before exposing it.
- `SoundName` is a Dart enum rather than a string union. Invalid names become
  a compile error instead of a runtime no-op.

## Alternatives considered

### 1. just_audio / audioplayers / soundpool plus shipped wavs

Rejected. That adapter plays files. Cuelume's depth is the recipes and the
graph. File playback would make this package a shallow asset bundle and would
freeze noise layers.

### 2. wajuce (Web Audio-shaped graph)

Rejected for the first port. The interface looks like upstream `engine.ts`,
but the implementation is a second audio runtime with weaker native/web
parity. We would still need recipes, policy, and widgets. SoLoud is the
smaller adapter behind the same renderer.

### 3. Live SoLoud waveforms instead of an offline renderer

Rejected. `loadWaveform` has no filtered-noise layers, no per-layer
exponential envelopes, and no recipe shimmer send. The palette would become
"SoLoud-ish clicks" rather than Cuelume.

### 4. minisound / flutter_pcm_sound / raw dart:ffi to miniaudio

Deferred. These can play PCM, so they could sit at the same seam later. They
do not currently give us a mixing bus, a shared compressor, and overlapping
voices as a single adapter. Replacing `SoloudCuePlayback` does not require a
new public interface.

### 5. Make CuePlayback public so apps inject audio

Rejected. One production adapter is enough for apps. Publishing the seam would
shallow the module: every caller would have to learn PCM format, sample rate,
and engine lifecycle. The test adapter stays behind `@visibleForTesting`.

### 6. Port only `play()` and skip interaction binding

Rejected. Upstream's product includes the defaults (hover throttle, pointer
filters, press/release pairing). A Flutter port that omits them pushes that
policy into every app.

## Validation requirements

This decision holds only if all of the following remain true:

- `Cuelume.sounds` has 17 names and ends with `pulse`, `scan`, `arrival`.
- Renderer durations match upstream's source-end + shimmer-tail + 50 ms cleanup
  (chime cleanup ≈ 1176 ms).
- Volume is clamped the same way as upstream; non-finite `setVolume` is ignored.
- `setEnabled(false)` makes later plays no-ops, including plays whose backend
  init is still in flight.
- Engine tests never initialize SoLoud; they use the recording adapter.
- `CuelumeListener` hover is globally throttled to 150 ms and ignores touch.
- A host that already called `SoLoud.instance.init()` can still `play()`
  without Cuelume deiniting the engine.

## Revisit triggers

Write a new ADR before any of the following:

- Exposing recipes, PCM, sample rate, or `CuePlayback` on the public interface.
- Replacing SoLoud with another production adapter.
- Baking assets at build time.
- Adding a custom recipe API.
- Changing the shared output compressor into a per-sound limiter.
- Persisting enable/volume inside Cuelume.
