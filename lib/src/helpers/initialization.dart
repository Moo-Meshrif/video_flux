part of '../video_flux.dart';

/// Creating controllers and initializing them through a bounded queue.
extension _Initialization<T extends VideoFluxItem> on VideoFlux<T> {
  /// Creates the controller for [index] and queues its initialization.
  ///
  /// Pass `pump: false` when creating several controllers in a row and call
  /// [_pumpInitializations] afterwards: pumping per controller would start the
  /// first ones created, whatever their distance to the active item.
  CustomVideoController _createController(
    int index, {
    int initializationAttempt = 1,
    bool pump = true,
  }) {
    final CustomVideoController controller = _controllerFactory(
      _items[index].url,
    );
    _setControllerState(
      VideoFluxState<T>(
        index: index,
        item: _items[index],
        controller: controller,
        status: VideoFluxStatus.initializing,
        initializationAttempt: initializationAttempt,
      ),
    );
    _initializationQueue.add(
      PendingInitialization(controller, index, initializationAttempt),
    );
    if (pump) {
      _pumpInitializations();
    }
    return controller;
  }

  bool get _hasFreeInitializationSlot {
    final int? maximum = _limits.maxConcurrentInitializations;
    return maximum == null || _runningInitializations < maximum;
  }

  /// Starts queued initializations while slots are free, nearest item first.
  ///
  /// A controller that left the window while it waited is dropped without ever
  /// being initialized: that is the work a fast scroll avoids.
  ///
  /// The active item never waits for a slot: stale loads for items the user
  /// scrolled past must not delay the video on screen.
  void _pumpInitializations() {
    final PendingInitialization? active =
        _initializationQueue.takeIndex(_activeIndex);
    if (active != null) {
      _startInitialization(active);
    }
    while (_initializationQueue.isNotEmpty && _hasFreeInitializationSlot) {
      final PendingInitialization next = _takeNextInitialization();
      if (_isDisposed || (_disposedControllers[next.controller] ?? false)) {
        _notify(
          InitializationCancelled(
            index: next.index,
            id: _items[next.index].id,
          ),
        );
        continue;
      }
      _startInitialization(next);
    }
  }

  void _startInitialization(PendingInitialization job) {
    _runningInitializations++;
    _slotHolders.add(job.controller);
    unawaited(_initializeController(job));
  }

  /// Frees [controller]'s slot if it still holds one.
  ///
  /// After a fast scroll the evicted controllers' network initializations may
  /// still be pending; without this they keep every slot busy and the item the
  /// user stopped on waits behind them.
  void _releaseInitializationSlot(CustomVideoController controller) {
    if (_slotHolders.remove(controller)) {
      _runningInitializations--;
      _pumpInitializations();
    }
  }

  PendingInitialization _takeNextInitialization() =>
      _initializationQueue.takeNearest(_activeIndex < 0 ? 0 : _activeIndex);

  Future<void> _initializeController(PendingInitialization job) async {
    final String id = _items[job.index].id;
    final Stopwatch stopwatch = Stopwatch()..start();
    _notify(
      InitializationStarted(index: job.index, id: id, attempt: job.attempt),
    );

    Object? error;
    StackTrace? stackTrace;
    try {
      await _withinTimeout(job.controller.initialize());
      await _warmUp(job.controller);
    } catch (caught, caughtStackTrace) {
      error = caught;
      stackTrace = caughtStackTrace;
    }

    // Free the slot before any retry wait: a waiting retry must not starve the
    // queue behind it.
    _releaseInitializationSlot(job.controller);

    if (error != null) {
      await _handleInitializationFailure(
        job,
        id,
        error,
        stackTrace ?? StackTrace.current,
      );
      return;
    }
    await _enqueue(() => _completeInitialization(job, id, stopwatch.elapsed));
  }

  Future<void> _withinTimeout(Future<void> work) {
    final Duration? timeout = _config.initializationTimeout;
    return timeout == null ? work : work.timeout(timeout);
  }

  Future<void> _warmUp(CustomVideoController controller) async {
    try {
      await _withinTimeout(controller.warmUp());
    } catch (_) {
      // Best effort: a failed warm-up costs a black first frame, not the video.
    }
  }

  Future<void> _handleInitializationFailure(
    PendingInitialization job,
    String id,
    Object error,
    StackTrace stackTrace,
  ) async {
    final Duration? delay = _config.retryPolicy.nextDelay(
      job.attempt,
      error,
      stackTrace,
    );
    _notify(
      InitializationFailed(
        index: job.index,
        id: id,
        attempt: job.attempt,
        error: error,
        stackTrace: stackTrace,
        retryDelay: delay,
      ),
    );
    if (delay != null) {
      await _scheduleInitializationRetry(job, delay);
      return;
    }
    onControllerInitializationError?.call(job.controller, error, stackTrace);
    await _enqueue(() async {
      _updateControllerState(
        job.controller,
        VideoFluxStatus.failed,
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  Future<void> _completeInitialization(
    PendingInitialization job,
    String id,
    Duration duration,
  ) async {
    final CustomVideoController controller = job.controller;
    if (_isDisposed || !_preloadWindow.contains(controller)) {
      await _disposeController(controller);
      return;
    }

    _updateControllerState(controller, VideoFluxStatus.ready);
    _notify(
      ControllerReady(
        index: job.index,
        id: id,
        attempt: job.attempt,
        duration: duration,
      ),
    );
    onControllerInitialized?.call(controller);
    if ((_config.autoplayFirstVideo &&
            _selectionGeneration == 0 &&
            _activeIndex == -1 &&
            job.index == 0) ||
        job.index == _activeIndex) {
      _activeIndex = job.index;
      await _play(controller);
    }
  }

  Future<void> _scheduleInitializationRetry(
    PendingInitialization job,
    Duration delay,
  ) async {
    final Completer<void> elapsed = Completer<void>();
    final Timer timer = Timer(delay, elapsed.complete);
    _retryTimers[timer] = elapsed;
    await elapsed.future;
    _retryTimers.remove(timer);
    await _enqueue(() {
      if (_isDisposed ||
          getControllerAtIndex(job.index) != job.controller ||
          !_controllerStatesByController.containsKey(job.controller)) {
        return Future<void>.value();
      }
      return _replaceController(
        job.index,
        job.controller,
        initializationAttempt: job.attempt + 1,
      );
    });
  }

  /// Stops every waiting retry so nothing outlives [disposeAll].
  void _cancelRetryTimers() {
    for (final MapEntry<Timer, Completer<void>> entry in _retryTimers.entries) {
      entry.key.cancel();
      entry.value.complete();
    }
    _retryTimers.clear();
  }

  Future<void> _replaceController(
    int index,
    CustomVideoController controller, {
    required int initializationAttempt,
  }) async {
    final int offset = index - _windowStart;
    if (offset < 0 ||
        offset >= _preloadWindow.length ||
        _preloadWindow[offset] != controller) {
      return;
    }

    await _releaseWithoutBlocking(controller);
    if (_isDisposed) {
      return;
    }
    _preloadWindow[offset] = _createController(
      index,
      initializationAttempt: initializationAttempt,
    );
  }
}
