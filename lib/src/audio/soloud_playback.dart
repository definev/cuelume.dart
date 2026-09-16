import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'playback.dart';
import 'renderer.dart';

/// Production adapter. Mixes overlapping cues through a dedicated SoLoud bus.
final class SoloudCuePlayback implements CuePlayback {
  SoloudCuePlayback({SoLoud? soloud}) : _soloud = soloud ?? SoLoud.instance;

  static const String busName = 'cuelume';
  static const int minVoiceCount = 32;
  static const double makeupGainDb = 12; // ~OUTPUT_GAIN 4
  static const double compressorThresholdDb = -8;
  static const double compressorKneeDb = 6;
  static const double compressorRatio = 10; // SoLoud max; upstream is 12
  static const double compressorAttackMs = 2;
  static const double compressorReleaseMs = 80;

  final SoLoud _soloud;
  Bus? _bus;
  bool _ownedEngine = false;
  bool _ready = false;
  bool _compressorArmed = false;

  @override
  bool get isReady => _ready && _soloud.isInitialized;

  @override
  Future<bool> ensureReady() async {
    if (isReady) return true;
    try {
      if (!_soloud.isInitialized) {
        await _soloud.init(
          sampleRate: cuelumeSampleRate,
          channels: Channels.mono,
          automaticCleanup: true,
        );
        _ownedEngine = true;
      }
      if (_ownedEngine) {
        _soloud.setMaxActiveVoiceCount(minVoiceCount);
      }
      _bus = _existingBus() ?? _soloud.createMixingBus(name: busName);
      if (_bus?.soundHandle == null) {
        _bus!.playOnEngine();
      }
      _armCompressor();
      _ready = true;
      return true;
    } catch (_) {
      _ready = false;
      return false;
    }
  }

  @override
  bool playPcm(
    Float32List pcm, {
    required double volume,
    required int sampleRate,
  }) {
    if (!isReady || pcm.isEmpty) return false;
    try {
      final bytes = pcm.buffer.asUint8List(pcm.offsetInBytes, pcm.lengthInBytes);
      final source = _soloud.setBufferStream(
        maxBufferSizeBytes: bytes.length,
        bufferingType: BufferingType.preserved,
        bufferingTimeNeeds: 0,
        sampleRate: sampleRate,
        channels: Channels.mono,
        format: BufferType.f32le,
        autoDispose: true,
      );
      _soloud.addAudioDataStream(source, bytes);
      _soloud.setDataIsEnded(source);
      final bus = _bus;
      if (bus != null) {
        bus.play(source, volume: volume);
      } else {
        _soloud.play(source, volume: volume);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> shutdown() async {
    _ready = false;
    final bus = _bus;
    _bus = null;
    try {
      bus?.dispose();
    } catch (_) {}
    if (_ownedEngine && _soloud.isInitialized) {
      _soloud.deinit();
    }
    _ownedEngine = false;
    _compressorArmed = false;
  }

  Bus? _existingBus() {
    try {
      return Buses().byName(busName);
    } catch (_) {
      return null;
    }
  }

  void _armCompressor() {
    if (_compressorArmed) return;
    final bus = _bus;
    if (bus == null) return;
    try {
      final compressor = bus.filters.compressorFilter;
      if (!compressor.isActive) compressor.activate();
      compressor.wet().value = 1;
      compressor.threshold().value = compressorThresholdDb;
      compressor.makeupGain().value = makeupGainDb;
      compressor.kneeWidth().value = compressorKneeDb;
      compressor.ratio().value = compressorRatio;
      compressor.attackTime().value = compressorAttackMs;
      compressor.releaseTime().value = compressorReleaseMs;
      _compressorArmed = true;
    } catch (_) {
      // Web and some backends cannot attach per-bus filters. Play dry.
      _compressorArmed = false;
    }
  }
}
