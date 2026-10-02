/// How constrained the device's memory currently is.
///
/// Levels are ordered by severity, so `index` comparisons are meaningful:
/// a higher index is more severe.
enum MemoryPressureLevel {
  /// No pressure; the configured limits apply.
  none(
    preloadFactor: 1,
    windowFactor: 1,
    minWindowSize: 1,
    minPreloadForward: 0,
    maxConcurrentInitializations: null,
  ),

  /// Memory is tight; retain noticeably less.
  moderate(
    preloadFactor: 0.5,
    windowFactor: 0.6,
    minWindowSize: 2,
    minPreloadForward: 1,
    maxConcurrentInitializations: 1,
  ),

  /// The platform reported a low-memory warning; keep only the active video.
  critical(
    preloadFactor: 0,
    windowFactor: 0,
    minWindowSize: 1,
    minPreloadForward: 0,
    maxConcurrentInitializations: 1,
  );

  const MemoryPressureLevel({
    required this.preloadFactor,
    required this.windowFactor,
    required this.minWindowSize,
    required this.minPreloadForward,
    required this.maxConcurrentInitializations,
  });

  /// Multiplier for the items kept behind and ahead of the active one.
  final double preloadFactor;

  /// Multiplier for the number of retained controllers.
  final double windowFactor;

  /// Smallest window this level may shrink to.
  final int minWindowSize;

  /// Smallest forward preload this level may shrink to.
  final int minPreloadForward;

  /// Ceiling for simultaneous initializations, or null for no ceiling.
  final int? maxConcurrentInitializations;
}
