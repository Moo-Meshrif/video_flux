import 'package:video_flux/video_flux.dart';

/// How the device tier is decided.
enum TierChoice {
  /// Detect it from the device.
  auto(PlatformDeviceTierProbe()),

  /// Pretend to be a constrained device.
  low(FixedDeviceTierProbe(DeviceTier.low)),

  /// Pretend to be a mid-range device.
  mid(FixedDeviceTierProbe(DeviceTier.mid)),

  /// Pretend to be a capable device.
  high(FixedDeviceTierProbe(DeviceTier.high));

  const TierChoice(this.probe);

  /// The probe this choice installs.
  final DeviceTierProbe probe;

  /// The choice that describes [probe].
  static TierChoice fromProbe(DeviceTierProbe probe) => switch (probe) {
        FixedDeviceTierProbe(:final tier) => switch (tier) {
            DeviceTier.low => low,
            DeviceTier.mid => mid,
            DeviceTier.high => high,
          },
        _ => auto,
      };
}
