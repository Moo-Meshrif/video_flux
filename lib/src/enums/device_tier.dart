/// A coarse classification of how much video the device can hold at once.
///
/// A tier only ever narrows a configuration: it is a ceiling, resolved once
/// when the preloader is created.
enum DeviceTier {
  /// Constrained hardware where a second decoder risks an out-of-memory kill.
  low(
    maxPreloadBackward: 0,
    maxPreloadForward: 1,
    maxWindowSize: 2,
  ),

  /// Typical mid-range hardware.
  mid(
    maxPreloadBackward: 1,
    maxPreloadForward: 2,
    maxWindowSize: 4,
  ),

  /// Capable hardware; the configuration is used as written.
  high(
    maxPreloadBackward: null,
    maxPreloadForward: null,
    maxWindowSize: null,
  );

  const DeviceTier({
    required this.maxPreloadBackward,
    required this.maxPreloadForward,
    required this.maxWindowSize,
  });

  /// Ceiling for items kept behind the active one, or null for no ceiling.
  final int? maxPreloadBackward;

  /// Ceiling for items kept ahead of the active one, or null for no ceiling.
  final int? maxPreloadForward;

  /// Ceiling for retained controllers, or null for no ceiling.
  final int? maxWindowSize;

  /// Classifies a device from cheap, plugin-free signals.
  ///
  /// This is a heuristic, not a measurement. [processorCount] is null where the
  /// platform cannot report it (such as the web), in which case only the
  /// display signals can promote a device above [mid].
  static DeviceTier classify({
    required int? processorCount,
    required double refreshRate,
    required double pixelRatio,
  }) {
    if (processorCount != null && processorCount <= 4) {
      return DeviceTier.low;
    }
    final bool hasCapableDisplay = refreshRate >= 90 || pixelRatio >= 3;
    if (processorCount != null && processorCount >= 8 && hasCapableDisplay) {
      return DeviceTier.high;
    }
    return DeviceTier.mid;
  }
}
