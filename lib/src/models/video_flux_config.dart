import 'device_tier_probe.dart';
import 'retry_policy.dart';

/// Every tunable of a `VideoFlux` preloader.
///
/// The defaults suit a general feed. Use a preset such as
/// [VideoFluxConfig.tikTok] when one matches your feed's shape, and
/// [copyWith] to adjust it.
class VideoFluxConfig {
  /// Creates a configuration.
  ///
  /// [windowSize] is the maximum number of retained controllers and must be
  /// greater than `preloadBackward + preloadForward`: two videos each side
  /// needs `windowSize: 5`.
  const VideoFluxConfig({
    this.preloadBackward = 3,
    this.preloadForward = 3,
    this.windowSize = 8,
    this.directionalPreloadBias = 0,
    this.maxVelocityPreload = 0,
    this.velocityPreloadThreshold = 1,
    this.maxConcurrentInitializations = 2,
    this.scrollDebounce = const Duration(milliseconds: 120),
    this.jumpThreshold = 5,
    this.paginationThreshold = 5,
    this.paginationRetryDelay = const Duration(seconds: 2),
    this.autoplayFirstVideo = false,
    this.handleAppLifecycle = true,
    this.retryPolicy = const ExponentialBackoffRetryPolicy(),
    this.adaptive = true,
    this.deviceTierProbe = const PlatformDeviceTierProbe(),
    this.pressureRecoveryDuration = const Duration(seconds: 5),
    this.initializationTimeout = const Duration(seconds: 20),
  });

  /// Full-screen vertical feeds: one behind, two ahead.
  const VideoFluxConfig.tikTok()
      : this(
          preloadBackward: 1,
          preloadForward: 2,
          windowSize: 4,
        );

  /// Feeds users scrub backwards through: two behind, two ahead.
  const VideoFluxConfig.shorts()
      : this(
          preloadBackward: 2,
          preloadForward: 2,
          windowSize: 5,
        );

  /// Keeps only the active video; the baseline for very constrained devices.
  const VideoFluxConfig.currentOnly()
      : this(
          preloadBackward: 0,
          preloadForward: 0,
          windowSize: 1,
        );

  /// Items kept ready behind the active one.
  final int preloadBackward;

  /// Items kept ready ahead of the active one.
  final int preloadForward;

  /// Maximum number of controllers retained at one time.
  final int windowSize;

  /// Extra positions shifted toward the current scroll direction.
  final int directionalPreloadBias;

  /// Maximum extra positions added for fast scrolling; `0` disables it.
  final int maxVelocityPreload;

  /// Pages per second required for each extra velocity position.
  final double velocityPreloadThreshold;

  /// Maximum simultaneous `initialize` calls, or null for no limit.
  final int? maxConcurrentInitializations;

  /// How long a small scroll waits for further scrolls before it takes effect.
  ///
  /// A flick emits a burst of index changes; waiting lets the preloader act
  /// once instead of starting work for every item passed. [Duration.zero]
  /// disables the debounce.
  final Duration scrollDebounce;

  /// Index distance at or above which a move bypasses [scrollDebounce].
  final int jumpThreshold;

  /// Remaining items at which the pagination callback is invoked.
  final int paginationThreshold;

  /// Base delay before pagination is attempted again after it failed.
  ///
  /// Doubles on each consecutive failure, capped at 30 seconds.
  final Duration paginationRetryDelay;

  /// Whether to play the first video once it initializes.
  final bool autoplayFirstVideo;

  /// Whether to pause and resume playback with the app lifecycle.
  final bool handleAppLifecycle;

  /// How failed initializations are retried.
  final RetryPolicy retryPolicy;

  /// Whether to narrow the configuration by device tier and memory pressure.
  final bool adaptive;

  /// Decides the device tier when [adaptive] is true.
  final DeviceTierProbe deviceTierProbe;

  /// How long pressure must stay lower before limits grow back one level.
  final Duration pressureRecoveryDuration;

  /// How long one initialization may take before it counts as failed, or null
  /// to wait indefinitely.
  ///
  /// A hung request would otherwise hold a concurrency slot forever. A timed-out
  /// attempt goes through [retryPolicy] like any other failure.
  ///
  /// The preloader only stops waiting; it cannot cancel the backend. The
  /// request ends when the controller's `dispose` aborts it.
  final Duration? initializationTimeout;

  /// Returns a copy with the given fields replaced.
  VideoFluxConfig copyWith({
    int? preloadBackward,
    int? preloadForward,
    int? windowSize,
    int? directionalPreloadBias,
    int? maxVelocityPreload,
    double? velocityPreloadThreshold,
    int? maxConcurrentInitializations,
    Duration? scrollDebounce,
    int? jumpThreshold,
    int? paginationThreshold,
    Duration? paginationRetryDelay,
    bool? autoplayFirstVideo,
    bool? handleAppLifecycle,
    RetryPolicy? retryPolicy,
    bool? adaptive,
    DeviceTierProbe? deviceTierProbe,
    Duration? pressureRecoveryDuration,
    Duration? initializationTimeout,
  }) =>
      VideoFluxConfig(
        preloadBackward: preloadBackward ?? this.preloadBackward,
        preloadForward: preloadForward ?? this.preloadForward,
        windowSize: windowSize ?? this.windowSize,
        directionalPreloadBias:
            directionalPreloadBias ?? this.directionalPreloadBias,
        maxVelocityPreload: maxVelocityPreload ?? this.maxVelocityPreload,
        velocityPreloadThreshold:
            velocityPreloadThreshold ?? this.velocityPreloadThreshold,
        maxConcurrentInitializations:
            maxConcurrentInitializations ?? this.maxConcurrentInitializations,
        scrollDebounce: scrollDebounce ?? this.scrollDebounce,
        jumpThreshold: jumpThreshold ?? this.jumpThreshold,
        paginationThreshold: paginationThreshold ?? this.paginationThreshold,
        paginationRetryDelay: paginationRetryDelay ?? this.paginationRetryDelay,
        autoplayFirstVideo: autoplayFirstVideo ?? this.autoplayFirstVideo,
        handleAppLifecycle: handleAppLifecycle ?? this.handleAppLifecycle,
        retryPolicy: retryPolicy ?? this.retryPolicy,
        adaptive: adaptive ?? this.adaptive,
        deviceTierProbe: deviceTierProbe ?? this.deviceTierProbe,
        pressureRecoveryDuration:
            pressureRecoveryDuration ?? this.pressureRecoveryDuration,
        initializationTimeout:
            initializationTimeout ?? this.initializationTimeout,
      );

  /// Throws an [ArgumentError] when a value is out of range.
  void validate() {
    if (windowSize <= 0) {
      throw ArgumentError.value(windowSize, 'windowSize', 'Must be positive.');
    }
    if (preloadBackward < 0 || preloadForward < 0) {
      throw ArgumentError('Preload counts cannot be negative.');
    }
    if (preloadBackward + preloadForward >= windowSize) {
      throw ArgumentError(
        'preloadBackward + preloadForward must be less than windowSize.',
      );
    }
    _requireNonNegative(directionalPreloadBias, 'directionalPreloadBias');
    _requireNonNegative(maxVelocityPreload, 'maxVelocityPreload');
    _requireNonNegative(paginationThreshold, 'paginationThreshold');
    if (!velocityPreloadThreshold.isFinite || velocityPreloadThreshold <= 0) {
      throw ArgumentError.value(
        velocityPreloadThreshold,
        'velocityPreloadThreshold',
        'Must be finite and positive.',
      );
    }
    final int? concurrency = maxConcurrentInitializations;
    if (concurrency != null && concurrency < 1) {
      throw ArgumentError.value(
        concurrency,
        'maxConcurrentInitializations',
        'Must be at least one, or null for no limit.',
      );
    }
    if (jumpThreshold < 1) {
      throw ArgumentError.value(
        jumpThreshold,
        'jumpThreshold',
        'Must be at least one.',
      );
    }
    _requireNonNegativeDuration(scrollDebounce, 'scrollDebounce');
    _requireNonNegativeDuration(paginationRetryDelay, 'paginationRetryDelay');
    _requireNonNegativeDuration(
      pressureRecoveryDuration,
      'pressureRecoveryDuration',
    );
    final Duration? timeout = initializationTimeout;
    if (timeout != null && timeout <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'initializationTimeout',
        'Must be positive, or null to wait indefinitely.',
      );
    }
  }

  static void _requireNonNegative(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'Cannot be negative.');
    }
  }

  static void _requireNonNegativeDuration(Duration value, String name) {
    if (value.isNegative) {
      throw ArgumentError.value(value, name, 'Cannot be negative.');
    }
  }
}
