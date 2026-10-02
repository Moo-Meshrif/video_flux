import 'video_flux_item.dart';

import '../enums/video_flux_status.dart';
import '../video_controller.dart';

/// Immutable lifecycle information for one preloaded controller.
class VideoFluxState<T extends VideoFluxItem> {
  /// Creates lifecycle information for a controller at [index].
  const VideoFluxState({
    required this.index,
    required this.item,
    required this.controller,
    required this.status,
    required this.initializationAttempt,
    this.error,
    this.stackTrace,
  });

  /// The source position associated with [controller].
  final int index;

  /// The stable item associated with [controller].
  final T item;

  /// The player-specific controller managed for [index].
  final CustomVideoController controller;

  /// The controller's current lifecycle status.
  final VideoFluxStatus status;

  /// The one-based initialization attempt for this controller instance.
  final int initializationAttempt;

  /// The initialization error when [status] is [VideoFluxStatus.failed].
  final Object? error;

  /// The initialization stack trace when [status] is failed.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      other is VideoFluxState<T> &&
      index == other.index &&
      item == other.item &&
      identical(controller, other.controller) &&
      status == other.status &&
      initializationAttempt == other.initializationAttempt &&
      error == other.error &&
      stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(
        index,
        item,
        identityHashCode(controller),
        status,
        initializationAttempt,
        error,
        stackTrace,
      );
}
