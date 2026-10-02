part of '../video_flux.dart';

/// Events, operation serialization and the published controller states.
extension _ControllerStates<T extends VideoFluxItem> on VideoFlux<T> {
  /// Feeds [event] to the stats counters and, if anyone listens, the stream.
  void _notify(VideoFluxEvent event) {
    _statsRecorder.record(event);
    if (!_eventController.isClosed && _eventController.hasListener) {
      _eventController.add(event);
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final Future<void> result = _operationTail.then((_) => operation());
    _operationTail = result.catchError((Object _) {});
    return result;
  }

  bool _isCurrentSelection(int generation) =>
      generation == _selectionGeneration;

  void _setControllerState(VideoFluxState<T> state) {
    _controllerStatesByController[state.controller] = state;
    _publishControllerStates();
  }

  void _updateControllerState(
    CustomVideoController controller,
    VideoFluxStatus status, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final VideoFluxState<T>? previous =
        _controllerStatesByController[controller];
    if (previous == null) {
      return;
    }
    _setControllerState(
      VideoFluxState<T>(
        index: previous.index,
        item: previous.item,
        controller: controller,
        status: status,
        initializationAttempt: previous.initializationAttempt,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Re-publishes [controller]'s state at its new [index] and [item], keeping
  /// its status.
  void _reindexControllerState(
    CustomVideoController controller,
    int index,
    T item,
  ) {
    final VideoFluxState<T>? previous =
        _controllerStatesByController[controller];
    if (previous == null) {
      return;
    }
    _setControllerState(
      VideoFluxState<T>(
        index: index,
        item: item,
        controller: controller,
        status: previous.status,
        initializationAttempt: previous.initializationAttempt,
        error: previous.error,
        stackTrace: previous.stackTrace,
      ),
    );
  }

  void _removeControllerState(CustomVideoController controller) {
    if (_controllerStatesByController.remove(controller) != null) {
      _publishControllerStates();
    }
  }

  void _publishControllerStates() {
    // A release that was not awaited can finish after disposeAll closed this.
    if (_areStatesDisposed) {
      return;
    }
    final List<VideoFluxState<T>> states =
        _controllerStatesByController.values.toList()
          ..sort(
            (VideoFluxState<T> first, VideoFluxState<T> second) =>
                first.index.compareTo(second.index),
          );
    _controllerStates.value = List<VideoFluxState<T>>.unmodifiable(states);
  }
}
