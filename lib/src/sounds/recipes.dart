/// The Cuelume palette transcribed 1:1 from upstream recipes.ts.
library;

/// Fade-in / fade-out envelope shared by every layer.
sealed class SoundLayer {
  const SoundLayer({
    this.offset = 0,
    required this.attack,
    required this.decay,
    required this.peak,
  });

  /// Seconds after the trigger that this layer starts.
  final double offset;

  /// Fade-in time, in seconds.
  final double attack;

  /// Fade-out time, in seconds, starting right after the attack.
  final double decay;

  /// Peak amplitude reached at the end of the attack.
  final double peak;
}

/// Oscillator shapes used by tone layers. Names match Web Audio.
enum CuelumeWaveform { sine, triangle, square, sawtooth }

/// Biquad modes used by noise layers. Names match Web Audio.
enum CuelumeFilterType { lowpass, highpass, bandpass, notch }

/// A single note — the building block for chimes, arpeggios, and pads.
final class ToneLayer extends SoundLayer {
  const ToneLayer({
    super.offset,
    required super.attack,
    required super.decay,
    required super.peak,
    required this.waveform,
    required this.frequency,
    this.detune,
    this.glideTo,
    this.glideTime,
  });

  final CuelumeWaveform waveform;
  final double frequency;

  /// Detune in cents, for a gentle chorus/beating effect between layers.
  final double? detune;

  /// If set, the pitch glides smoothly from [frequency] to this value.
  final double? glideTo;

  /// How long the glide takes, in seconds. Defaults to attack + decay.
  final double? glideTime;
}

/// A soft filtered noise bed — used for breathy, textural layers.
final class NoiseLayer extends SoundLayer {
  const NoiseLayer({
    super.offset,
    required super.attack,
    required super.decay,
    required super.peak,
    required this.filterType,
    required this.filterFrequency,
    this.filterQ,
  });

  final CuelumeFilterType filterType;
  final double filterFrequency;
  final double? filterQ;
}

/// A soft, spacious echo tail applied to the whole sound.
final class Shimmer {
  const Shimmer({
    required this.delay,
    required this.feedback,
    required this.wet,
    required this.lowpass,
  });

  final double delay;
  final double feedback;
  final double wet;
  final double lowpass;
}

final class SoundRecipe {
  const SoundRecipe({
    required this.masterGain,
    required this.layers,
    this.shimmer,
  });

  final double masterGain;
  final List<SoundLayer> layers;
  final Shimmer? shimmer;
}

/// The twenty-one curated interaction sounds.
enum SoundName {
  /// Soft two-note ascending bell. Default hover.
  chime,

  /// Quick four-note twinkle.
  sparkle,

  /// Single note gliding down. Dismiss, collapse.
  droplet,

  /// Warm slow swell. Reveal, expand.
  bloom,

  /// Soft hush with a falling tone. Tooltips and quiet previews.
  whisper,

  /// Crisp instant tick. Nav and menu hover.
  tick,

  /// Dull muted knock. Pointer down.
  press,

  /// Brighter springy tick. Pointer up.
  release,

  /// Mechanical click-clack. Switches, tabs.
  toggle,

  /// Warm three-note confirmation.
  success,

  /// Soft knock and descending refusal.
  error,

  /// Papery flick with a glass tick. Pages, galleries, carousels.
  page,

  /// Brief unresolved rising shimmer. User-initiated work starting.
  loading,

  /// Rising lock-on with a clear resolve. Content or system ready.
  ready,

  /// Compact synthetic chirp. Primary buttons and controls.
  pulse,

  /// Fast three-step locator signal. Menus and secondary buttons.
  scan,

  /// Rising harmonic portal. Client-side page arrivals.
  arrival,

  /// Soft two-note ping for keyboard focus and selection changes.
  focus,

  /// Gentle double pulse for moments that need attention without an error tone.
  attention,

  /// Bright two-note bell for incoming notifications and external events.
  notification,

  /// Low descending two-hit cue for cancel, undo, and intentional dismissal.
  cancel,
}

/// All available sound names, in palette order.
const List<SoundName> sounds = SoundName.values;

/// The built-in recipes, keyed by [SoundName].
const Map<SoundName, SoundRecipe> recipes = {
  SoundName.chime: SoundRecipe(
    masterGain: 0.5,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1046.5,
        attack: 0.006,
        decay: 0.22,
        peak: 0.09,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1568,
        offset: 0.09,
        attack: 0.006,
        decay: 0.26,
        peak: 0.08,
      ),
    ],
    shimmer: Shimmer(delay: 0.12, feedback: 0.25, wet: 0.18, lowpass: 4000),
  ),
  SoundName.sparkle: SoundRecipe(
    masterGain: 0.5,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1760,
        attack: 0.003,
        decay: 0.09,
        peak: 0.045,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 2217,
        offset: 0.045,
        attack: 0.003,
        decay: 0.09,
        peak: 0.04,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 2637,
        offset: 0.09,
        attack: 0.003,
        decay: 0.1,
        peak: 0.038,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 3520,
        offset: 0.135,
        attack: 0.003,
        decay: 0.12,
        peak: 0.032,
      ),
    ],
    shimmer: Shimmer(delay: 0.07, feedback: 0.35, wet: 0.22, lowpass: 6000),
  ),
  SoundName.droplet: SoundRecipe(
    masterGain: 0.55,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1200,
        glideTo: 550,
        glideTime: 0.14,
        attack: 0.004,
        decay: 0.2,
        peak: 0.075,
      ),
    ],
    shimmer: Shimmer(delay: 0.09, feedback: 0.2, wet: 0.15, lowpass: 3000),
  ),
  SoundName.bloom: SoundRecipe(
    masterGain: 0.5,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 528,
        attack: 0.06,
        decay: 0.32,
        peak: 0.06,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 528,
        detune: 12,
        attack: 0.06,
        decay: 0.34,
        peak: 0.05,
      ),
    ],
    shimmer: Shimmer(delay: 0.15, feedback: 0.2, wet: 0.12, lowpass: 2500),
  ),
  SoundName.whisper: SoundRecipe(
    masterGain: 0.48,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.lowpass,
        filterFrequency: 1600,
        filterQ: 0.7,
        attack: 0.025,
        decay: 0.13,
        peak: 0.04,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 880,
        glideTo: 660,
        glideTime: 0.14,
        offset: 0.01,
        attack: 0.012,
        decay: 0.14,
        peak: 0.025,
      ),
    ],
  ),
  SoundName.tick: SoundRecipe(
    masterGain: 0.4,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 5400,
        filterQ: 1.8,
        attack: 0.001,
        decay: 0.018,
        peak: 0.14,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 2600,
        attack: 0.001,
        decay: 0.012,
        peak: 0.018,
      ),
    ],
  ),
  SoundName.press: SoundRecipe(
    masterGain: 0.4,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 1700,
        filterQ: 1.4,
        attack: 0.001,
        decay: 0.02,
        peak: 0.13,
      ),
    ],
  ),
  SoundName.release: SoundRecipe(
    masterGain: 0.4,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 4600,
        filterQ: 1.8,
        attack: 0.001,
        decay: 0.016,
        peak: 0.12,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 3200,
        offset: 0.006,
        attack: 0.001,
        decay: 0.05,
        peak: 0.02,
      ),
    ],
  ),
  SoundName.toggle: SoundRecipe(
    masterGain: 0.4,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 2200,
        filterQ: 1.6,
        attack: 0.001,
        decay: 0.016,
        peak: 0.12,
      ),
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 3800,
        filterQ: 1.6,
        offset: 0.024,
        attack: 0.001,
        decay: 0.02,
        peak: 0.1,
      ),
    ],
  ),
  SoundName.success: SoundRecipe(
    masterGain: 0.5,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 880,
        attack: 0.004,
        decay: 0.09,
        peak: 0.06,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1108.73,
        offset: 0.06,
        attack: 0.004,
        decay: 0.1,
        peak: 0.06,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1318.51,
        offset: 0.12,
        attack: 0.004,
        decay: 0.18,
        peak: 0.07,
      ),
    ],
    shimmer: Shimmer(delay: 0.1, feedback: 0.22, wet: 0.16, lowpass: 4500),
  ),
  SoundName.error: SoundRecipe(
    masterGain: 0.42,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 850,
        filterQ: 1.1,
        attack: 0.001,
        decay: 0.035,
        peak: 0.13,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 440,
        offset: 0.025,
        attack: 0.004,
        decay: 0.09,
        peak: 0.045,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 349.23,
        offset: 0.1,
        attack: 0.004,
        decay: 0.14,
        peak: 0.04,
      ),
    ],
  ),
  SoundName.page: SoundRecipe(
    masterGain: 0.38,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.lowpass,
        filterFrequency: 1800,
        filterQ: 0.7,
        attack: 0.006,
        decay: 0.08,
        peak: 0.11,
      ),
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 4200,
        filterQ: 1.2,
        offset: 0.04,
        attack: 0.004,
        decay: 0.065,
        peak: 0.08,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 2400,
        offset: 0.075,
        attack: 0.002,
        decay: 0.045,
        peak: 0.02,
      ),
    ],
  ),
  SoundName.loading: SoundRecipe(
    masterGain: 0.42,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.lowpass,
        filterFrequency: 1400,
        filterQ: 0.6,
        attack: 0.035,
        decay: 0.14,
        peak: 0.035,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 420,
        glideTo: 630,
        glideTime: 0.18,
        attack: 0.025,
        decay: 0.18,
        peak: 0.05,
      ),
    ],
    shimmer: Shimmer(delay: 0.11, feedback: 0.18, wet: 0.12, lowpass: 2800),
  ),
  SoundName.ready: SoundRecipe(
    masterGain: 0.48,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 3600,
        filterQ: 1.8,
        attack: 0.001,
        decay: 0.02,
        peak: 0.11,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 330,
        glideTo: 660,
        glideTime: 0.12,
        offset: 0.012,
        attack: 0.004,
        decay: 0.16,
        peak: 0.055,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 990,
        offset: 0.13,
        attack: 0.004,
        decay: 0.22,
        peak: 0.06,
      ),
    ],
    shimmer: Shimmer(delay: 0.1, feedback: 0.16, wet: 0.1, lowpass: 4200),
  ),
  SoundName.pulse: SoundRecipe(
    masterGain: 0.42,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 2600,
        filterQ: 2.4,
        attack: 0.001,
        decay: 0.022,
        peak: 0.08,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 620,
        glideTo: 1240,
        glideTime: 0.07,
        attack: 0.002,
        decay: 0.085,
        peak: 0.055,
      ),
    ],
  ),
  SoundName.scan: SoundRecipe(
    masterGain: 0.4,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 740,
        attack: 0.002,
        decay: 0.055,
        peak: 0.05,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1110,
        offset: 0.045,
        attack: 0.002,
        decay: 0.055,
        peak: 0.045,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1665,
        offset: 0.09,
        attack: 0.002,
        decay: 0.07,
        peak: 0.04,
      ),
    ],
    shimmer: Shimmer(delay: 0.065, feedback: 0.16, wet: 0.1, lowpass: 4200),
  ),
  SoundName.arrival: SoundRecipe(
    masterGain: 0.44,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.lowpass,
        filterFrequency: 900,
        filterQ: 0.8,
        attack: 0.05,
        decay: 0.24,
        peak: 0.035,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 220,
        glideTo: 440,
        glideTime: 0.32,
        attack: 0.04,
        decay: 0.34,
        peak: 0.055,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 659.25,
        offset: 0.12,
        attack: 0.045,
        decay: 0.32,
        peak: 0.04,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 987.77,
        offset: 0.19,
        attack: 0.045,
        decay: 0.34,
        peak: 0.032,
      ),
    ],
    shimmer: Shimmer(delay: 0.16, feedback: 0.28, wet: 0.18, lowpass: 3200),
  ),
  SoundName.focus: SoundRecipe(
    masterGain: 0.42,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 660,
        attack: 0.006,
        decay: 0.13,
        peak: 0.055,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 880,
        offset: 0.055,
        attack: 0.006,
        decay: 0.16,
        peak: 0.045,
      ),
    ],
  ),
  SoundName.attention: SoundRecipe(
    masterGain: 0.38,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 740,
        attack: 0.004,
        decay: 0.08,
        peak: 0.055,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 740,
        offset: 0.105,
        attack: 0.004,
        decay: 0.11,
        peak: 0.048,
      ),
      NoiseLayer(
        filterType: CuelumeFilterType.lowpass,
        filterFrequency: 1800,
        filterQ: 0.8,
        offset: 0.1,
        attack: 0.008,
        decay: 0.08,
        peak: 0.025,
      ),
    ],
  ),
  SoundName.notification: SoundRecipe(
    masterGain: 0.44,
    layers: [
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 784,
        attack: 0.005,
        decay: 0.14,
        peak: 0.065,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1174.66,
        offset: 0.095,
        attack: 0.005,
        decay: 0.2,
        peak: 0.055,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.sine,
        frequency: 1568,
        offset: 0.095,
        attack: 0.005,
        decay: 0.16,
        peak: 0.018,
      ),
    ],
    shimmer: Shimmer(delay: 0.085, feedback: 0.18, wet: 0.13, lowpass: 4800),
  ),
  SoundName.cancel: SoundRecipe(
    masterGain: 0.4,
    layers: [
      NoiseLayer(
        filterType: CuelumeFilterType.bandpass,
        filterFrequency: 900,
        filterQ: 1.1,
        attack: 0.001,
        decay: 0.025,
        peak: 0.08,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 440,
        attack: 0.004,
        decay: 0.08,
        peak: 0.055,
      ),
      ToneLayer(
        waveform: CuelumeWaveform.triangle,
        frequency: 349.23,
        offset: 0.07,
        attack: 0.004,
        decay: 0.13,
        peak: 0.05,
      ),
    ],
  ),
};
