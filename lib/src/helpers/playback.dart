part of '../video_flux.dart';

/// Starting and pausing playback so only the active video plays.
extension _Playback<T extends VideoFluxItem> on VideoFlux<T> {
  Future<void> _pauseAllExcept(int activeIndex) async {
    for (int offset = 0; offset < _preloadWindow.length; offset++) {
      final int index = _windowStart + offset;
      final CustomVideoController controller = _preloadWindow[offset];
      if (index != activeIndex && controller.isPlaying) {
        await controller.pause();
      }
    }
  }

  Future<void> _play(CustomVideoController controller) async {
    if (_isDisposed ||
        _isAppLifecyclePaused ||
        !controller.isInitialized ||
        controller.isPlaying) {
      return;
    }
    await controller.play();
    onPlayStateChanged?.call();
  }

  Future<void> _forceAutoPlay(int index, int selectionGeneration) async {
    if (_isDisposed || !_isCurrentSelection(selectionGeneration)) {
      return;
    }
    _activeIndex = index;
    await _pauseAllExcept(index);
    if (_isDisposed || !_isCurrentSelection(selectionGeneration)) {
      return;
    }
    final CustomVideoController? controller = getControllerAtIndex(index);
    if (controller != null) {
      await _play(controller);
    }
  }

  Future<void> _togglePlayPause(CustomVideoController controller) async {
    if (_isDisposed) {
      return;
    }
    if (controller.isPlaying) {
      await controller.pause();
      onPlayStateChanged?.call();
      return;
    }
    for (final CustomVideoController activeController in _preloadWindow) {
      if (activeController != controller && activeController.isPlaying) {
        await activeController.pause();
      }
    }
    await _play(controller);
  }
}
