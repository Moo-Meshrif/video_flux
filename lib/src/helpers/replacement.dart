part of '../video_flux.dart';

/// Replacing the whole feed while keeping the controllers still wanted.
extension _Replacement<T extends VideoFluxItem> on VideoFlux<T> {
  Future<void> _replaceItems(List<T> items) async {
    if (_isDisposed) {
      return;
    }
    final Map<String, CustomVideoController> keepable = _keepableControllers(
      items,
    );
    _cancelQueuedInitializations();

    final String? activeId = getItemAtIndex(_activeIndex)?.id;
    _items
      ..clear()
      ..addAll(items);
    _itemIndexesById.clear();
    _registerItems(items);
    _restartPagination();
    _followActiveItem(activeId);

    final WindowRange target = items.isEmpty
        ? (start: 0, end: 0)
        : _planWindow(
            _activeIndex < 0 ? 0 : _activeIndex, VideoFluxDirection.idle, 0);
    final Map<int, CustomVideoController> kept = <int, CustomVideoController>{};
    final List<CustomVideoController> outgoing = <CustomVideoController>[];
    for (final CustomVideoController controller in _preloadWindow) {
      final VideoFluxState<T>? state =
          _controllerStatesByController[controller];
      final int? index = state == null ? null : _itemIndexesById[state.item.id];
      final bool isKept = index != null &&
          keepable[state!.item.id] == controller &&
          index >= target.start &&
          index < target.end;
      if (isKept) {
        kept[index] = controller;
      } else {
        outgoing.add(controller);
      }
    }
    _windowStart = target.start;
    _preloadWindow.clear();

    for (final CustomVideoController controller in outgoing) {
      await _releaseWithoutBlocking(controller);
      if (_isDisposed) {
        return;
      }
    }

    for (int index = target.start; index < target.end; index++) {
      final CustomVideoController? controller = kept[index];
      if (controller == null) {
        _preloadWindow.add(_createController(index, pump: false));
        continue;
      }
      _reindexControllerState(controller, index, items[index]);
      _preloadWindow.add(controller);
    }
    _pumpInitializations();
    _notify(
      ItemsReplaced(
        itemCount: items.length,
        retained: kept.length,
        released: outgoing.length,
      ),
    );

    if (_activeIndex >= 0) {
      // The old active controller may have survived at a new position.
      await _pauseAllExcept(_activeIndex);
      unawaited(_paginateInBackground(_activeIndex));
    }
  }

  /// Ready controllers whose item is in [items] with an unchanged url, by id.
  Map<String, CustomVideoController> _keepableControllers(List<T> items) {
    final Map<String, String> urlsById = <String, String>{
      for (final T item in items) item.id: item.url,
    };
    final Map<String, CustomVideoController> keepable =
        <String, CustomVideoController>{};
    for (final CustomVideoController controller in _preloadWindow) {
      final VideoFluxState<T>? state =
          _controllerStatesByController[controller];
      if (state != null &&
          state.status == VideoFluxStatus.ready &&
          urlsById[state.item.id] == state.item.url) {
        keepable[state.item.id] = controller;
      }
    }
    return keepable;
  }

  /// Queued jobs are numbered for the old feed; none of them is kept.
  void _cancelQueuedInitializations() {
    for (final PendingInitialization job in _initializationQueue.drain()) {
      _notify(
        InitializationCancelled(index: job.index, id: _items[job.index].id),
      );
    }
  }

  void _restartPagination() {
    _hasReachedEnd = false;
    _paginationBackoffTimer?.cancel();
    _paginationBackoffTimer = null;
    _paginationBackoff.reset();
  }

  /// Points the active index at the item it was on, or clamps it.
  void _followActiveItem(String? activeId) {
    if (_activeIndex >= 0) {
      _activeIndex = _items.isEmpty
          ? -1
          : _itemIndexesById[activeId] ??
              math.min(_activeIndex, _items.length - 1);
    }
    _lastRequestedIndex = _activeIndex;
    _preloadDirection = VideoFluxDirection.idle;
  }
}
