import 'dart:collection';

import '../enums/device_tier.dart';
import '../enums/memory_pressure_level.dart';
import 'video_flux_event.dart';
import 'video_flux_limits.dart';

/// A snapshot of what a preloader is holding and how it has performed.
class VideoFluxStats {
  /// Creates a snapshot.
  const VideoFluxStats({
    required this.activeControllers,
    required this.readyControllers,
    required this.initializingControllers,
    required this.failedControllers,
    required this.queuedInitializations,
    required this.initializationsStarted,
    required this.initializationsSucceeded,
    required this.initializationsFailed,
    required this.initializationsRetried,
    required this.initializationsCancelled,
    required this.controllersReleased,
    required this.scrollCount,
    required this.poolHitRate,
    required this.averageInitializationDuration,
    required this.p95InitializationDuration,
    required this.deviceTier,
    required this.memoryPressure,
    required this.effectiveLimits,
    required this.hasReachedEnd,
  });

  /// Controllers currently retained.
  final int activeControllers;

  /// Retained controllers that are initialized.
  final int readyControllers;

  /// Retained controllers that are initializing or waiting to.
  final int initializingControllers;

  /// Retained controllers whose initialization failed for good.
  final int failedControllers;

  /// Initializations waiting for a concurrency slot.
  final int queuedInitializations;

  /// Initializations that have started, including retries.
  final int initializationsStarted;

  /// Initializations that succeeded.
  final int initializationsSucceeded;

  /// Initialization attempts that failed, including ones that were retried.
  final int initializationsFailed;

  /// Retries that were scheduled.
  final int initializationsRetried;

  /// Initializations dropped before they started.
  ///
  /// Climbing during a fast scroll is healthy: it is work that was avoided.
  final int initializationsCancelled;

  /// Controllers disposed so far.
  final int controllersReleased;

  /// Scrolls that took effect.
  final int scrollCount;

  /// Fraction of scrolls whose controller was already initialized.
  ///
  /// `0` until the first scroll.
  final double poolHitRate;

  /// Mean initialization time over the most recent successes.
  final Duration averageInitializationDuration;

  /// 95th-percentile initialization time over the most recent successes.
  ///
  /// The number that predicts black frames: the mean hides the tail.
  final Duration p95InitializationDuration;

  /// The detected device tier.
  final DeviceTier deviceTier;

  /// The current memory pressure level.
  final MemoryPressureLevel memoryPressure;

  /// The limits being enforced right now.
  final VideoFluxLimits effectiveLimits;

  /// Whether pagination reported that there is nothing more to load.
  final bool hasReachedEnd;

  @override
  String toString() => 'VideoFluxStats('
      'active $activeControllers/${effectiveLimits.windowSize}, '
      'ready $readyControllers, queued $queuedInitializations, '
      'cancelled $initializationsCancelled, released $controllersReleased, '
      'retried $initializationsRetried, failed $initializationsFailed, '
      'hitRate ${(poolHitRate * 100).round()}%, '
      'p95 ${p95InitializationDuration.inMilliseconds}ms, '
      'tier ${deviceTier.name}, pressure ${memoryPressure.name})';
}

/// Accumulates counters from the event stream.
///
/// Internal: the preloader feeds every event through [record], so the counters
/// and the public event stream can never disagree.
class VideoFluxStatsRecorder {
  static const int _maxDurationSamples = 100;

  final Queue<Duration> _durations = Queue<Duration>();
  int _started = 0;
  int _succeeded = 0;
  int _failed = 0;
  int _retried = 0;
  int _cancelled = 0;
  int _released = 0;
  int _scrolls = 0;
  int _scrollHits = 0;

  /// Folds [event] into the counters.
  void record(VideoFluxEvent event) {
    switch (event) {
      case ScrollSelected(:final wasReady):
        _scrolls++;
        if (wasReady) {
          _scrollHits++;
        }
      case InitializationStarted():
        _started++;
      case ControllerReady(:final duration):
        _succeeded++;
        _durations.addLast(duration);
        if (_durations.length > _maxDurationSamples) {
          _durations.removeFirst();
        }
      case InitializationFailed(:final willRetry):
        _failed++;
        if (willRetry) {
          _retried++;
        }
      case InitializationCancelled():
        _cancelled++;
      case ControllerReleased():
        _released++;
      case PressureChanged() ||
            LimitsChanged() ||
            ItemsReplaced() ||
            PaginationCompleted() ||
            PaginationEnded() ||
            PaginationFailed():
        break;
    }
  }

  /// Builds a snapshot from the counters and the preloader's live state.
  VideoFluxStats snapshot({
    required int activeControllers,
    required int readyControllers,
    required int initializingControllers,
    required int failedControllers,
    required int queuedInitializations,
    required DeviceTier deviceTier,
    required MemoryPressureLevel memoryPressure,
    required VideoFluxLimits effectiveLimits,
    required bool hasReachedEnd,
  }) =>
      VideoFluxStats(
        activeControllers: activeControllers,
        readyControllers: readyControllers,
        initializingControllers: initializingControllers,
        failedControllers: failedControllers,
        queuedInitializations: queuedInitializations,
        initializationsStarted: _started,
        initializationsSucceeded: _succeeded,
        initializationsFailed: _failed,
        initializationsRetried: _retried,
        initializationsCancelled: _cancelled,
        controllersReleased: _released,
        scrollCount: _scrolls,
        poolHitRate: _scrolls == 0 ? 0 : _scrollHits / _scrolls,
        averageInitializationDuration: _average(),
        p95InitializationDuration: _percentile95(),
        deviceTier: deviceTier,
        memoryPressure: memoryPressure,
        effectiveLimits: effectiveLimits,
        hasReachedEnd: hasReachedEnd,
      );

  Duration _average() {
    if (_durations.isEmpty) {
      return Duration.zero;
    }
    final int totalMicroseconds = _durations.fold<int>(
      0,
      (int total, Duration duration) => total + duration.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ _durations.length);
  }

  Duration _percentile95() {
    if (_durations.isEmpty) {
      return Duration.zero;
    }
    final List<Duration> sorted = _durations.toList()..sort();
    final int rank = (sorted.length * 0.95).ceil();
    return sorted[rank - 1];
  }
}
