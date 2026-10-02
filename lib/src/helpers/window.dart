part of '../video_flux.dart';

/// Moving the retained window, releasing before allocating.
extension _Window<T extends VideoFluxItem> on VideoFlux<T> {
  void _fillWindowTo(int endExclusive) {
    while (_windowEnd < endExclusive) {
      _preloadWindow.add(_createController(_windowEnd, pump: false));
    }
    _pumpInitializations();
  }

  /// Moves the window to its target, releasing before allocating.
  ///
  /// Every controller that leaves is disposed before any new one is created, so
  /// the outgoing and incoming decoders are never alive at the same moment.
  Future<void> _reconcileWindow(
    int activeIndex,
    VideoFluxDirection direction,
    int velocityPreload,
  ) async {
    final WindowRange target = _planWindow(
      activeIndex,
      direction,
      velocityPreload,
    );
    final int targetStart = target.start;
    final int targetEnd = target.end;

    final List<CustomVideoController> kept = <CustomVideoController>[];
    final List<CustomVideoController> outgoing = <CustomVideoController>[];
    for (int offset = 0; offset < _preloadWindow.length; offset++) {
      final int index = _windowStart + offset;
      final bool isInTarget = index >= targetStart && index < targetEnd;
      (isInTarget ? kept : outgoing).add(_preloadWindow[offset]);
    }
    _windowStart =
        kept.isEmpty ? targetStart : math.max(_windowStart, targetStart);
    _preloadWindow
      ..clear()
      ..addAll(kept);

    for (final CustomVideoController controller in outgoing) {
      await _releaseWithoutBlocking(controller);
      if (_isDisposed) {
        return;
      }
    }

    while (_windowStart > targetStart) {
      _windowStart--;
      _preloadWindow.insert(0, _createController(_windowStart, pump: false));
    }
    _fillWindowTo(targetEnd);
  }

  WindowRange _planWindow(
    int activeIndex,
    VideoFluxDirection direction,
    int velocityPreload,
  ) =>
      WindowPlanner.plan(
        activeIndex: activeIndex,
        direction: direction,
        directionalShift: _config.directionalPreloadBias + velocityPreload,
        itemCount: _items.length,
        preloadBackward: _limits.preloadBackward,
        windowSize: _limits.windowSize,
      );

  /// Disposes [controller], awaiting it only once it has initialized.
  ///
  /// A backend may wait for a pending initialization before disposing, which
  /// on a slow network would stall every later operation behind this one.
  Future<void> _releaseWithoutBlocking(CustomVideoController controller) {
    final Future<void> release = _disposeController(controller);
    if (controller.isInitialized) {
      return release;
    }
    unawaited(release);
    return Future<void>.value();
  }

  Future<void> _disposeController(CustomVideoController controller) async {
    if (_disposedControllers[controller] ?? false) {
      return;
    }
    _disposedControllers[controller] = true;
    _releaseInitializationSlot(controller);
    final VideoFluxState<T>? state = _controllerStatesByController[controller];
    try {
      await controller.pause();
      await controller.dispose();
    } catch (_) {
      // Disposal is best-effort: other controllers must still be released.
    } finally {
      _updateControllerState(controller, VideoFluxStatus.disposed);
      _removeControllerState(controller);
      if (state != null) {
        _notify(ControllerReleased(index: state.index, id: state.item.id));
      }
    }
  }
}
