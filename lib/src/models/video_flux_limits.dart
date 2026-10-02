import 'dart:math' as math;

import '../enums/device_tier.dart';
import '../enums/memory_pressure_level.dart';
import 'video_flux_config.dart';

/// The limits a preloader is actually enforcing right now.
///
/// These are the configured values narrowed by the device tier, the current
/// and the current memory pressure. Limits never widen a configuration.
class VideoFluxLimits {
  /// Creates a set of resolved limits.
  const VideoFluxLimits({
    required this.preloadBackward,
    required this.preloadForward,
    required this.windowSize,
    required this.maxConcurrentInitializations,
  });

  /// Resolves the limits for [config] under [tier] and [pressure].
  factory VideoFluxLimits.resolve({
    required VideoFluxConfig config,
    required DeviceTier tier,
    required MemoryPressureLevel pressure,
  }) {
    int backward = config.preloadBackward;
    int forward = config.preloadForward;
    int window = config.windowSize;
    int? concurrency = config.maxConcurrentInitializations;

    if (config.adaptive) {
      backward = math.min(backward, tier.maxPreloadBackward ?? backward);
      forward = math.min(forward, tier.maxPreloadForward ?? forward);
      window = math.min(window, tier.maxWindowSize ?? window);
      backward = _scale(backward, pressure.preloadFactor, 0);
      forward = _scale(
        forward,
        pressure.preloadFactor,
        pressure.minPreloadForward,
      );
      window = _scale(window, pressure.windowFactor, pressure.minWindowSize);
      concurrency = _narrow(concurrency, pressure.maxConcurrentInitializations);
    }

    // The window must hold the active item plus everything around it.
    forward = math.min(forward, window - 1);
    backward = math.min(backward, window - 1 - forward);

    return VideoFluxLimits(
      preloadBackward: backward,
      preloadForward: forward,
      windowSize: window,
      maxConcurrentInitializations: concurrency,
    );
  }

  /// Items kept ready behind the active one.
  final int preloadBackward;

  /// Items kept ready ahead of the active one.
  final int preloadForward;

  /// Maximum number of retained controllers.
  final int windowSize;

  /// Maximum simultaneous initializations, or null for no limit.
  final int? maxConcurrentInitializations;

  static int _scale(int value, double factor, int floor) =>
      math.min(value, math.max(floor, (value * factor).floor()));

  static int? _narrow(int? configured, int? ceiling) {
    if (ceiling == null) {
      return configured;
    }
    return configured == null ? ceiling : math.min(configured, ceiling);
  }

  @override
  bool operator ==(Object other) =>
      other is VideoFluxLimits &&
      preloadBackward == other.preloadBackward &&
      preloadForward == other.preloadForward &&
      windowSize == other.windowSize &&
      maxConcurrentInitializations == other.maxConcurrentInitializations;

  @override
  int get hashCode => Object.hash(
        preloadBackward,
        preloadForward,
        windowSize,
        maxConcurrentInitializations,
      );

  @override
  String toString() => 'VideoFluxLimits(window: -$preloadBackward/'
      '+$preloadForward of $windowSize, '
      'concurrency: $maxConcurrentInitializations)';
}
