part of '../video_flux.dart';

/// Loading more items, with backoff after failures.
extension _Pagination<T extends VideoFluxItem> on VideoFlux<T> {
  Future<void> _paginateIfNeeded(int activeIndex) async {
    final Future<List<T>> Function()? fetch = onPaginationNeeded;
    if (fetch == null ||
        _isPaginating ||
        _hasReachedEnd ||
        _paginationBackoffTimer != null) {
      return;
    }
    final int remainingItems = _items.length - activeIndex - 1;
    if (remainingItems > _paginationThreshold) {
      return;
    }

    _isPaginating = true;
    final int itemsGeneration = _itemsGeneration;
    try {
      final List<T> page = await fetch();
      // A page fetched for a feed that has since been replaced is stale.
      if (!_isDisposed && itemsGeneration == _itemsGeneration) {
        _acceptPage(page);
      }
    } catch (error, stackTrace) {
      if (!_isDisposed) {
        _handlePaginationFailure(error, stackTrace);
      }
    } finally {
      _isPaginating = false;
    }
  }

  /// Fetches without holding the operation queue, so a slow request cannot
  /// delay scrolling; the window is extended once new items arrive.
  Future<void> _paginateInBackground(int activeIndex) async {
    final int itemCountBefore = _items.length;
    await _paginateIfNeeded(activeIndex);
    if (_isDisposed || _items.length == itemCountBefore) {
      return;
    }
    await _enqueue(_reconcileToLimits);
  }

  void _acceptPage(List<T> page) {
    if (page.isEmpty) {
      _hasReachedEnd = true;
      _notify(const PaginationEnded());
      return;
    }
    _appendItems(page);
    _paginationBackoff.reset();
    _notify(PaginationCompleted(page.length));
  }

  void _handlePaginationFailure(Object error, StackTrace stackTrace) {
    final Duration delay = _paginationBackoff.recordFailure();
    _paginationBackoffTimer = Timer(delay, () {
      _paginationBackoffTimer = null;
    });
    _notify(
      PaginationFailed(error: error, stackTrace: stackTrace, retryAfter: delay),
    );
    onPaginationError?.call(error, stackTrace);
  }
}
