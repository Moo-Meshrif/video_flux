import '../enums/memory_pressure_level.dart';
import 'video_flux_limits.dart';

/// Something the preloader did or observed.
///
/// The hierarchy is sealed, so a `switch` over an event is exhaustive.
sealed class VideoFluxEvent {
  const VideoFluxEvent();
}

/// A scroll took effect and selected [index].
final class ScrollSelected extends VideoFluxEvent {
  /// Creates the event.
  const ScrollSelected({required this.index, required this.wasReady});

  /// The selected index.
  final int index;

  /// Whether the selected controller was already initialized.
  ///
  /// A pool hit: the user did not wait for it.
  final bool wasReady;
}

/// A controller started its `initialize` call.
final class InitializationStarted extends VideoFluxEvent {
  /// Creates the event.
  const InitializationStarted({
    required this.index,
    required this.id,
    required this.attempt,
  });

  /// The item's index.
  final int index;

  /// The item's stable id.
  final String id;

  /// The one-based attempt number.
  final int attempt;
}

/// A controller finished initializing and is ready.
final class ControllerReady extends VideoFluxEvent {
  /// Creates the event.
  const ControllerReady({
    required this.index,
    required this.id,
    required this.attempt,
    required this.duration,
  });

  /// The item's index.
  final int index;

  /// The item's stable id.
  final String id;

  /// The one-based attempt number that succeeded.
  final int attempt;

  /// How long initialization took.
  final Duration duration;
}

/// An initialization attempt failed.
final class InitializationFailed extends VideoFluxEvent {
  /// Creates the event.
  const InitializationFailed({
    required this.index,
    required this.id,
    required this.attempt,
    required this.error,
    required this.stackTrace,
    required this.retryDelay,
  });

  /// The item's index.
  final int index;

  /// The item's stable id.
  final String id;

  /// The one-based attempt number that failed.
  final int attempt;

  /// The backend error.
  final Object error;

  /// The backend stack trace.
  final StackTrace stackTrace;

  /// The delay before the next attempt, or null when this failure is final.
  final Duration? retryDelay;

  /// Whether another attempt has been scheduled.
  bool get willRetry => retryDelay != null;
}

/// A queued initialization was dropped before it started.
///
/// Its controller left the window first, so no work was spent on it.
final class InitializationCancelled extends VideoFluxEvent {
  /// Creates the event.
  const InitializationCancelled({required this.index, required this.id});

  /// The item's index.
  final int index;

  /// The item's stable id.
  final String id;
}

/// A controller was disposed.
final class ControllerReleased extends VideoFluxEvent {
  /// Creates the event.
  const ControllerReleased({required this.index, required this.id});

  /// The item's index.
  final int index;

  /// The item's stable id.
  final String id;
}

/// The memory pressure level changed.
final class PressureChanged extends VideoFluxEvent {
  /// Creates the event.
  const PressureChanged(this.level);

  /// The new level.
  final MemoryPressureLevel level;
}

/// The enforced limits changed.
final class LimitsChanged extends VideoFluxEvent {
  /// Creates the event.
  const LimitsChanged(this.limits);

  /// The new limits.
  final VideoFluxLimits limits;
}

/// A page of items was appended.
final class PaginationCompleted extends VideoFluxEvent {
  /// Creates the event.
  const PaginationCompleted(this.itemCount);

  /// How many items were appended.
  final int itemCount;
}

/// The whole feed was replaced through `VideoFlux.replaceItems`.
final class ItemsReplaced extends VideoFluxEvent {
  /// Creates the event.
  const ItemsReplaced({
    required this.itemCount,
    required this.retained,
    required this.released,
  });

  /// How many items the feed now holds.
  final int itemCount;

  /// How many ready controllers were kept because their item survived.
  final int retained;

  /// How many controllers were released because their item did not survive.
  final int released;
}

/// The pagination callback returned no items, so the feed has ended.
final class PaginationEnded extends VideoFluxEvent {
  /// Creates the event.
  const PaginationEnded();
}

/// The pagination callback failed.
final class PaginationFailed extends VideoFluxEvent {
  /// Creates the event.
  const PaginationFailed({
    required this.error,
    required this.stackTrace,
    required this.retryAfter,
  });

  /// The error thrown by the callback.
  final Object error;

  /// The stack trace of [error].
  final StackTrace stackTrace;

  /// How long pagination is paused before it may run again.
  final Duration retryAfter;
}
