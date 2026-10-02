part of '../video_flux.dart';

/// Turning a scroll into a selection: debounce, direction and velocity.
extension _Scrolling<T extends VideoFluxItem> on VideoFlux<T> {
  Future<void> _scroll(
    int index,
    int selectionGeneration,
    double? scrollVelocity,
    bool isJump,
  ) async {
    if (_isDisposed || !_isCurrentSelection(selectionGeneration)) {
      return;
    }
    unawaited(_paginateInBackground(index));
    if (!isJump && _config.scrollDebounce > Duration.zero) {
      await Future<void>.delayed(_config.scrollDebounce);
      if (_isDisposed || !_isCurrentSelection(selectionGeneration)) {
        return;
      }
    }

    _notify(
      ScrollSelected(
        index: index,
        wasReady: getControllerAtIndex(index)?.isInitialized ?? false,
      ),
    );
    final VideoFluxDirection direction = _directionFor(index);
    final int velocityPreload = _velocityPreloadFor(scrollVelocity);
    _activeIndex = index;
    _preloadDirection = direction;
    await _pauseAllExcept(index);
    _refreshLimits();
    await _reconcileWindow(index, direction, velocityPreload);
    if (_isDisposed || !_isCurrentSelection(selectionGeneration)) {
      return;
    }

    final CustomVideoController? controller = getControllerAtIndex(index);
    if (controller != null) {
      await _play(controller);
    }
  }

  VideoFluxDirection _directionFor(int index) {
    if (_activeIndex == -1 || index == _activeIndex) {
      return VideoFluxDirection.idle;
    }
    return index > _activeIndex
        ? VideoFluxDirection.forward
        : VideoFluxDirection.backward;
  }

  int _velocityPreloadFor(double? scrollVelocity) {
    if (scrollVelocity == null || _config.maxVelocityPreload == 0) {
      return 0;
    }
    final int requestedPreload =
        (scrollVelocity.abs() / _config.velocityPreloadThreshold).floor();
    return math.min(requestedPreload, _config.maxVelocityPreload);
  }
}
