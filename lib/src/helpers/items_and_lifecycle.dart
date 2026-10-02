part of '../video_flux.dart';

/// Item registration, validation and app-lifecycle bookkeeping.
extension _ItemsAndLifecycle<T extends VideoFluxItem> on VideoFlux<T> {
  void _pauseForLifecycle(AppLifecycleState state) {
    if (_isAppLifecyclePaused ||
        (state != AppLifecycleState.inactive &&
            state != AppLifecycleState.hidden &&
            state != AppLifecycleState.paused &&
            state != AppLifecycleState.detached)) {
      return;
    }
    _isAppLifecyclePaused = true;
    _resumeAfterLifecyclePause = _preloadWindow
        .any((CustomVideoController controller) => controller.isPlaying);
    unawaited(pauseAll());
  }

  void _resumeFromLifecyclePause() {
    if (!_isAppLifecyclePaused) {
      return;
    }
    _isAppLifecyclePaused = false;
    final bool shouldResume = _resumeAfterLifecyclePause;
    _resumeAfterLifecyclePause = false;
    if (shouldResume) {
      unawaited(resumeActive());
    }
  }

  void _detachFromBinding() {
    if (!_isObservingBinding) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _isObservingBinding = false;
    _isAppLifecyclePaused = false;
    _resumeAfterLifecyclePause = false;
  }

  void _ensureUsable() {
    if (_isDisposed) {
      throw StateError('VideoFlux has already been disposed.');
    }
  }

  void _validateVideoIndex(int index) {
    if (index < 0 || index >= _items.length) {
      throw RangeError.index(index, _items, 'index');
    }
  }

  void _validateScrollVelocity(double? scrollVelocity) {
    if (scrollVelocity != null && !scrollVelocity.isFinite) {
      throw ArgumentError.value(
        scrollVelocity,
        'scrollVelocity',
        'Must be finite when provided.',
      );
    }
  }

  /// Throws unless every id is non-empty and unique, also against [known].
  void _validateItems(
    Iterable<T> items, {
    Set<String> known = const <String>{},
  }) {
    final Set<String> seen = <String>{...known};
    for (final T item in items) {
      if (item.id.isEmpty) {
        throw ArgumentError.value(item.id, 'item.id', 'Cannot be empty.');
      }
      if (!seen.add(item.id)) {
        throw ArgumentError.value(item.id, 'item.id', 'Must be unique.');
      }
    }
  }

  void _registerItems(Iterable<T> items) {
    final List<T> itemsToRegister = List<T>.of(items);
    _validateItems(itemsToRegister, known: _itemIndexesById.keys.toSet());
    for (final T item in itemsToRegister) {
      _itemIndexesById[item.id] = _itemIndexesById.length;
    }
  }

  void _appendItems(List<T> items) {
    _registerItems(items);
    _items.addAll(items);
  }
}
