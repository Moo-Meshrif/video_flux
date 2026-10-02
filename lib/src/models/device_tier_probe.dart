import 'dart:ui' show PlatformDispatcher;

import '../enums/device_tier.dart';
import 'processor_count_stub.dart'
    if (dart.library.io) 'processor_count_io.dart';

/// Decides which [DeviceTier] the current device belongs to.
///
/// Implement this to classify devices with better information than the
/// built-in heuristic, such as a device-model allow-list.
abstract interface class DeviceTierProbe {
  /// Returns the tier of the current device.
  DeviceTier detect();
}

/// Always reports [tier]; useful for tests and for apps that classify devices
/// themselves.
class FixedDeviceTierProbe implements DeviceTierProbe {
  /// Creates a probe that always returns [tier].
  const FixedDeviceTierProbe(this.tier);

  /// The tier reported for every device.
  final DeviceTier tier;

  @override
  DeviceTier detect() => tier;
}

/// Classifies the device from processor count, refresh rate and pixel ratio.
///
/// Needs no plugin. Falls back to [DeviceTier.mid] when a signal is
/// unavailable.
class PlatformDeviceTierProbe implements DeviceTierProbe {
  /// Creates the default heuristic probe.
  const PlatformDeviceTierProbe();

  @override
  DeviceTier detect() {
    try {
      final view = PlatformDispatcher.instance.implicitView;
      if (view == null) {
        return DeviceTier.mid;
      }
      return DeviceTier.classify(
        processorCount: readProcessorCount(),
        refreshRate: view.display.refreshRate,
        pixelRatio: view.devicePixelRatio,
      );
    } catch (_) {
      return DeviceTier.mid;
    }
  }
}
