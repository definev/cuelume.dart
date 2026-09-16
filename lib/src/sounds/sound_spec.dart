import 'recipes.dart';

/// How to play a [SoundName]: system intensity, or a custom per-play volume.
sealed class SoundSpec {
  const SoundSpec();

  /// The palette sound to play.
  SoundName get name;

  /// Per-play volume, or `null` to use system intensity.
  double? get volume;

  /// Play [name] at the global volume only.
  const factory SoundSpec.system(SoundName name) = SystemSoundSpec;

  /// Play [name] scaled by [volume], then multiplied by the global volume.
  const factory SoundSpec.custom(SoundName name, {required double volume}) =
      CustomSoundSpec;
}

/// A [SoundSpec] with no extra per-play scale.
final class SystemSoundSpec extends SoundSpec {
  /// Play [name] at the global volume only.
  const SystemSoundSpec(this.name);

  @override
  final SoundName name;

  @override
  double? get volume => null;

  @override
  bool operator ==(Object other) =>
      other is SystemSoundSpec && other.name == name;

  @override
  int get hashCode => Object.hash(SystemSoundSpec, name);
}

/// A [SoundSpec] with a per-play volume scale.
final class CustomSoundSpec extends SoundSpec {
  /// Play [name] scaled by [volume], then multiplied by the global volume.
  const CustomSoundSpec(this.name, {required this.volume});

  @override
  final SoundName name;

  @override
  final double volume;

  @override
  bool operator ==(Object other) =>
      other is CustomSoundSpec && other.name == name && other.volume == volume;

  @override
  int get hashCode => Object.hash(CustomSoundSpec, name, volume);
}
