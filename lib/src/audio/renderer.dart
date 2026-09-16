import 'dart:math';
import 'dart:typed_data';

import '../sounds/recipes.dart';

/// Matches upstream `SOURCE_STOP_PADDING`.
const double sourceStopPadding = 0.05;

/// Matches upstream `CLEANUP_MARGIN`.
const double cleanupMargin = 0.05;

/// Matches upstream `INAUDIBLE_GAIN`.
const double inaudibleGain = 0.001;

/// Envelope floor used by Web Audio exponential ramps (they cannot start at 0).
const double envelopeFloor = 0.0001;

/// Default sample rate for offline rendering and SoLoud init.
const int cuelumeSampleRate = 44100;

/// Seconds until the last oscillator/noise source stops.
double sourceEnd(SoundRecipe recipe) {
  var end = 0.0;
  for (final layer in recipe.layers) {
    final layerEnd =
        layer.offset + layer.attack + layer.decay + sourceStopPadding;
    if (layerEnd > end) end = layerEnd;
  }
  return end;
}

/// Seconds of delay-line tail after the dry sources stop.
double shimmerTail(Shimmer? shimmer) {
  if (shimmer == null || shimmer.feedback <= 0) return 0;
  if (shimmer.feedback >= 1) return shimmer.delay;
  return shimmer.delay *
      (1 + (log(inaudibleGain) / log(shimmer.feedback)).ceil());
}

/// Full PCM length, including the 50 ms cleanup margin from upstream.
double recipeDuration(SoundRecipe recipe) {
  return sourceEnd(recipe) + shimmerTail(recipe.shimmer) + cleanupMargin;
}

/// Renders [recipe] to mono float32 PCM at [sampleRate].
///
/// [volume] is the captured play volume (global * per-play), already clamped.
Float32List renderRecipe(
  SoundRecipe recipe, {
  double volume = 1,
  int sampleRate = cuelumeSampleRate,
  Random? random,
}) {
  final duration = recipeDuration(recipe);
  final length = max(1, (duration * sampleRate).round());
  final mix = Float64List(length);
  final rng = random ?? Random();

  for (final layer in recipe.layers) {
    if (layer is ToneLayer) {
      _renderTone(mix, layer, sampleRate);
    } else if (layer is NoiseLayer) {
      _renderNoise(mix, layer, sampleRate, rng);
    }
  }

  final master = recipe.masterGain * volume;
  if (recipe.shimmer != null) {
    _applyShimmer(mix, recipe.shimmer!, sampleRate);
  }

  final out = Float32List(length);
  for (var i = 0; i < length; i++) {
    out[i] = (mix[i] * master).toDouble();
  }
  return out;
}

void _renderTone(
  Float64List mix,
  ToneLayer layer,
  int sampleRate,
) {
  final start = (layer.offset * sampleRate).round();
  final active =
      ((layer.attack + layer.decay + sourceStopPadding) * sampleRate).round();
  if (active <= 0) return;

  var phase = 0.0;
  final twoPi = 2 * pi;
  final end = min(mix.length, start + active);
  for (var i = max(0, start); i < end; i++) {
    final localTime = (i - start) / sampleRate;
    final freq = _toneFrequency(layer, localTime);
    phase += twoPi * freq / sampleRate;
    mix[i] += _oscillator(layer.waveform, phase) * _envelope(layer, localTime);
  }
}

void _renderNoise(
  Float64List mix,
  NoiseLayer layer,
  int sampleRate,
  Random random,
) {
  final start = (layer.offset * sampleRate).round();
  final active =
      ((layer.attack + layer.decay + sourceStopPadding) * sampleRate).round();
  if (active <= 0) return;

  final filter = Biquad.from(
    type: layer.filterType,
    frequency: layer.filterFrequency,
    q: layer.filterQ ?? 1,
    sampleRate: sampleRate,
  );

  final end = min(mix.length, start + active);
  for (var i = max(0, start); i < end; i++) {
    final localTime = (i - start) / sampleRate;
    final noise = 2 * random.nextDouble() - 1;
    mix[i] += filter.process(noise) * _envelope(layer, localTime);
  }
}

void _applyShimmer(Float64List mix, Shimmer shimmer, int sampleRate) {
  final delaySamples = shimmer.delay * sampleRate;
  if (delaySamples <= 0) return;

  final lp = Biquad.from(
    type: CuelumeFilterType.lowpass,
    frequency: shimmer.lowpass,
    q: 1,
    sampleRate: sampleRate,
  );

  final delayLength = max(2, delaySamples.ceil() + 2);
  final delayLine = Float64List(delayLength);
  var write = 0;

  for (var i = 0; i < mix.length; i++) {
    final dry = mix[i];
    final delayed = _readDelay(delayLine, write, delaySamples);
    final filtered = lp.process(delayed);
    delayLine[write] = dry + filtered * shimmer.feedback;
    write++;
    if (write == delayLength) write = 0;
    mix[i] = dry + filtered * shimmer.wet;
  }
}

double _readDelay(Float64List line, int write, double delaySamples) {
  final len = line.length;
  final pos = write - delaySamples;
  var index = pos % len;
  if (index < 0) index += len;
  final i0 = index.floor();
  final frac = index - i0;
  final s0 = line[i0 % len];
  final s1 = line[(i0 + 1) % len];
  return s0 + (s1 - s0) * frac;
}

double _toneFrequency(ToneLayer layer, double localTime) {
  var freq = layer.frequency;
  final glideTo = layer.glideTo;
  if (glideTo != null) {
    final glideTime = layer.glideTime ?? (layer.attack + layer.decay);
    if (localTime <= 0 || glideTime <= 0) {
      freq = layer.frequency;
    } else if (localTime >= glideTime) {
      freq = glideTo;
    } else {
      freq = layer.frequency *
          pow(glideTo / layer.frequency, localTime / glideTime);
    }
  }
  final detune = layer.detune;
  if (detune != null) {
    freq *= pow(2, detune / 1200);
  }
  return freq;
}

double _envelope(SoundLayer layer, double localTime) {
  if (localTime < 0) return 0;
  final attack = layer.attack;
  final decay = layer.decay;
  if (localTime <= attack) {
    if (attack <= 0) return layer.peak;
    return envelopeFloor * pow(layer.peak / envelopeFloor, localTime / attack);
  }
  final afterAttack = localTime - attack;
  if (afterAttack <= decay) {
    if (decay <= 0) return envelopeFloor;
    return layer.peak * pow(envelopeFloor / layer.peak, afterAttack / decay);
  }
  if (localTime <= attack + decay + sourceStopPadding) return envelopeFloor;
  return 0;
}

double _oscillator(CuelumeWaveform waveform, double phase) {
  switch (waveform) {
    case CuelumeWaveform.sine:
      return sin(phase);
    case CuelumeWaveform.triangle:
      final t = phase / (2 * pi);
      final f = t - t.floor();
      if (f < 0.25) return 4 * f;
      if (f < 0.75) return 2 - 4 * f;
      return 4 * f - 4;
    case CuelumeWaveform.square:
      return sin(phase) >= 0 ? 1.0 : -1.0;
    case CuelumeWaveform.sawtooth:
      final t = phase / (2 * pi);
      final f = t - t.floor();
      return 2 * f - 1;
  }
}

/// RBJ biquad matching the Web Audio filter cookbook.
final class Biquad {
  Biquad._(this._b0, this._b1, this._b2, this._a1, this._a2);

  factory Biquad.from({
    required CuelumeFilterType type,
    required double frequency,
    required double q,
    required int sampleRate,
  }) {
    final nyquist = sampleRate * 0.5;
    final f0 = frequency.clamp(1.0, nyquist * 0.99);
    final w0 = 2 * pi * f0 / sampleRate;
    final cosW0 = cos(w0);
    final sinW0 = sin(w0);
    final alpha = sinW0 / (2 * max(q, 0.0001));

    late double b0, b1, b2, a0, a1, a2;
    switch (type) {
      case CuelumeFilterType.lowpass:
        b0 = (1 - cosW0) / 2;
        b1 = 1 - cosW0;
        b2 = (1 - cosW0) / 2;
        a0 = 1 + alpha;
        a1 = -2 * cosW0;
        a2 = 1 - alpha;
      case CuelumeFilterType.highpass:
        b0 = (1 + cosW0) / 2;
        b1 = -(1 + cosW0);
        b2 = (1 + cosW0) / 2;
        a0 = 1 + alpha;
        a1 = -2 * cosW0;
        a2 = 1 - alpha;
      case CuelumeFilterType.bandpass:
        b0 = alpha;
        b1 = 0;
        b2 = -alpha;
        a0 = 1 + alpha;
        a1 = -2 * cosW0;
        a2 = 1 - alpha;
      case CuelumeFilterType.notch:
        b0 = 1;
        b1 = -2 * cosW0;
        b2 = 1;
        a0 = 1 + alpha;
        a1 = -2 * cosW0;
        a2 = 1 - alpha;
    }

    return Biquad._(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
  }

  final double _b0;
  final double _b1;
  final double _b2;
  final double _a1;
  final double _a2;
  double _x1 = 0;
  double _x2 = 0;
  double _y1 = 0;
  double _y2 = 0;

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
