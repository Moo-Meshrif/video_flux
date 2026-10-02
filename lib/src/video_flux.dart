import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'enums/device_tier.dart';
import 'enums/memory_pressure_level.dart';
import 'enums/video_flux_direction.dart';
import 'enums/video_flux_status.dart';
import 'internal/initialization_queue.dart';
import 'internal/pagination_backoff.dart';
import 'internal/window_planner.dart';
import 'models/video_flux_item.dart';
import 'models/video_flux_config.dart';
import 'models/video_flux_event.dart';
import 'models/video_flux_limits.dart';
import 'models/video_flux_state.dart';
import 'models/video_flux_stats.dart';
import 'video_controller.dart';
import 'video_flux_typedefs.dart';

part 'helpers/controller_states.dart';
part 'helpers/initialization.dart';
part 'helpers/items_and_lifecycle.dart';
part 'helpers/limits_and_pressure.dart';
part 'helpers/pagination.dart';
part 'helpers/playback.dart';
part 'helpers/replacement.dart';
part 'helpers/scrolling.dart';
part 'helpers/window.dart';

/// Maintains a bounded, initialized window of video controllers.
///
/// The application selects the playback package by supplying [controllerFactory].
/// This package never imports or creates a concrete video-player controller.
///
/// A typical forward-scrolling feed retains two items before and after the
/// selected item:
///
/// ```dart
/// VideoFlux<FeedVideo>(
///   items: videos,
///   controllerFactory: MyController.new,
///   config: const VideoFluxConfig.shorts(),
/// );
/// ```
class VideoFlux<T extends VideoFluxItem> with WidgetsBindingObserver {
  /// Creates a preloader for [items].
  ///
  /// * [items] is copied when this is created; use [onPaginationNeeded]
  ///   to append later pages.
  /// * [controllerFactory] must return a new, uninitialized backend controller
  ///   for each URL.
  /// * [config] holds every tunable. Invalid values throw an [ArgumentError].
  ///
  /// The callbacks notify UI of initialization, errors, playback changes and
  /// pagination. [onPaginationNeeded] returns the next items.
  VideoFlux({
    required List<T> items,
    required VideoControllerFactory controllerFactory,
    VideoFluxConfig config = const VideoFluxConfig(),
    this.onControllerInitialized,
    this.onControllerInitializationError,
    this.onPlayStateChanged,
    this.onPaginationNeeded,
    this.onPaginationError,
  })  : _items = List<T>.of(items),
        _controllerFactory = controllerFactory,
        _config = config {
    config.validate();
    _registerItems(_items);
    _deviceTier =
        config.adaptive ? config.deviceTierProbe.detect() : DeviceTier.high;
    _limits = _resolveLimits();
    _paginationThreshold = config.paginationThreshold;
    _isObservingAppLifecycle = config.handleAppLifecycle;
    WidgetsBinding.instance.addObserver(this);
    _isObservingBinding = true;
    _fillWindowTo(_initialWindowSize);
  }

  final VideoFluxConfig _config;
  final List<T> _items;
  final Map<String, int> _itemIndexesById = <String, int>{};
  final List<CustomVideoController> _preloadWindow = <CustomVideoController>[];
  final InitializationQueue _initializationQueue = InitializationQueue();
  final VideoFluxStatsRecorder _statsRecorder = VideoFluxStatsRecorder();
  final StreamController<VideoFluxEvent> _eventController =
      StreamController<VideoFluxEvent>.broadcast();
  // Weakly keyed: a disposed controller must be collectable, not retained here
  // for the life of the preloader.
  final Expando<bool> _disposedControllers = Expando<bool>('disposed');
  // Controllers currently occupying an initialization slot. A slot is freed as
  // soon as its controller is disposed, not when a stale initialize() settles.
  final HashSet<CustomVideoController> _slotHolders =
      HashSet<CustomVideoController>.identity();
  final Map<Timer, Completer<void>> _retryTimers = <Timer, Completer<void>>{};
  final HashMap<CustomVideoController, VideoFluxState<T>>
      _controllerStatesByController =
      HashMap<CustomVideoController, VideoFluxState<T>>.identity();
  final ValueNotifier<List<VideoFluxState<T>>> _controllerStates =
      ValueNotifier<List<VideoFluxState<T>>>(
    List<VideoFluxState<T>>.empty(),
  );

  VideoControllerFactory _controllerFactory;
  late final DeviceTier _deviceTier;
  late VideoFluxLimits _limits;
  late int _paginationThreshold;
  late final PaginationBackoff _paginationBackoff = PaginationBackoff(
    baseDelay: _config.paginationRetryDelay,
  );
  MemoryPressureLevel _pressure = MemoryPressureLevel.none;
  MemoryPressureLevel _pressureTarget = MemoryPressureLevel.none;
  Timer? _pressureRecoveryTimer;
  Timer? _paginationBackoffTimer;
  int _runningInitializations = 0;
  int _windowStart = 0;
  int _activeIndex = -1;
  int _lastRequestedIndex = -1;
  VideoFluxDirection _preloadDirection = VideoFluxDirection.idle;
  int _selectionGeneration = 0;
  int _itemsGeneration = 0;
  bool _isPaginating = false;
  bool _hasReachedEnd = false;
  bool _isDisposed = false;
  bool _areStatesDisposed = false;
  bool _isObservingBinding = false;
  bool _isObservingAppLifecycle = false;
  bool _isAppLifecyclePaused = false;
  bool _resumeAfterLifecyclePause = false;
  Future<void> _operationTail = Future<void>.value();
  Future<void>? _disposeFuture;

  /// Called after a controller has initialized successfully.
  final void Function(CustomVideoController controller)?
      onControllerInitialized;

  /// Called when a controller fails to initialize for good.
  ///
  /// Failures that the retry policy retries are not reported here.
  final ControllerInitializationError? onControllerInitializationError;

  /// Called after this preloader changes playback state.
  final void Function()? onPlayStateChanged;

  /// Fetches additional items when the active item nears the end.
  ///
  /// Return the next page in feed order, or an empty list when there are no
  /// more videos. Only one pagination request runs at a time.
  final Future<List<T>> Function()? onPaginationNeeded;

  /// Called when [onPaginationNeeded] throws.
  ///
  /// Pagination pauses with an increasing delay and resumes on a later scroll.
  final PaginationError? onPaginationError;

  /// Observes lifecycle changes for the controllers in the retained window.
  ///
  /// A controller emits [VideoFluxStatus.disposed] before it is removed
  /// from this bounded list. The listenable is disposed with this preloader.
  ValueListenable<List<VideoFluxState<T>>> get controllerStates =>
      _controllerStates;

  /// A lazy stream of everything this preloader does.
  ///
  /// Events are delivered only while someone listens, so an unused stream costs
  /// nothing to keep. The hierarchy is sealed, so a `switch` over an event is
  /// exhaustive.
  Stream<VideoFluxEvent> get events => _eventController.stream;

  /// A snapshot of what is retained and how the preloader has performed.
  VideoFluxStats get stats {
    int ready = 0;
    int initializing = 0;
    int failed = 0;
    for (final VideoFluxState<T> state
        in _controllerStatesByController.values) {
      switch (state.status) {
        case VideoFluxStatus.ready:
          ready++;
        case VideoFluxStatus.initializing:
          initializing++;
        case VideoFluxStatus.failed:
          failed++;
        case VideoFluxStatus.disposed:
          break;
      }
    }
    return _statsRecorder.snapshot(
      activeControllers: _preloadWindow.length,
      readyControllers: ready,
      initializingControllers: initializing,
      failedControllers: failed,
      queuedInitializations: _initializationQueue.length,
      deviceTier: _deviceTier,
      memoryPressure: _pressure,
      effectiveLimits: _limits,
      hasReachedEnd: _hasReachedEnd,
    );
  }

  /// The limits being enforced: the configuration narrowed by device tier
  /// and memory pressure.
  VideoFluxLimits get effectiveLimits => _limits;

  /// The device tier this preloader classified the device as.
  DeviceTier get deviceTier => _deviceTier;

  /// The memory pressure level currently applied.
  MemoryPressureLevel get memoryPressure => _pressure;

  /// Whether [onPaginationNeeded] reported that there is nothing more to load.
  bool get hasReachedEnd => _hasReachedEnd;

  int get _initialWindowSize => math.min(_items.length, _limits.windowSize);

  int get _windowEnd => _windowStart + _preloadWindow.length;

  /// Updates the active source and adjusts the preloaded controller window.
  ///
  /// Small moves wait [VideoFluxConfig.scrollDebounce] for further scrolls, so
  /// a flick through many items takes effect once. A move of
  /// [VideoFluxConfig.jumpThreshold] items or more does not wait.
  Future<void> scroll(int index, {double? scrollVelocity}) {
    _ensureUsable();
    _validateVideoIndex(index);
    _validateScrollVelocity(scrollVelocity);
    final bool isJump = _lastRequestedIndex == -1 ||
        (index - _lastRequestedIndex).abs() >= _config.jumpThreshold;
    _lastRequestedIndex = index;
    final int selectionGeneration = ++_selectionGeneration;
    return _enqueue(
      () => _scroll(index, selectionGeneration, scrollVelocity, isJump),
    );
  }

  /// The controller for the active item, or null while it is outside the
  /// window or has not been selected yet.
  ///
  /// Like [getControllerAtIndex], a missing controller is a normal state, not
  /// an error: it is also null right after a memory-pressure shrink.
  CustomVideoController? get currentController =>
      getControllerAtIndex(_activeIndex);

  /// Returns the controllers currently retained in the preload window.
  List<CustomVideoController> getActiveControllers() =>
      List<CustomVideoController>.unmodifiable(_preloadWindow);

  /// Returns the loaded item at [index], or null when it is out of range.
  T? getItemAtIndex(int index) =>
      index < 0 || index >= _items.length ? null : _items[index];

  /// Returns the loaded item with [id], or null when it is unknown.
  T? getItemById(String id) {
    final int? index = _itemIndexesById[id];
    return index == null ? null : _items[index];
  }

  /// Returns the retained controller for the item with [id], when available.
  CustomVideoController? getControllerById(String id) {
    final int? index = _itemIndexesById[id];
    return index == null ? null : getControllerAtIndex(index);
  }

  /// Selects the loaded item with [id].
  Future<void> scrollToId(String id, {double? scrollVelocity}) {
    final int? index = _itemIndexesById[id];
    if (index == null) {
      throw ArgumentError.value(id, 'id', 'No item has this ID.');
    }
    return scroll(index, scrollVelocity: scrollVelocity);
  }

  /// Replaces the whole feed, keeping every ready controller whose item
  /// survives.
  ///
  /// Use it for a refresh, a deletion or an inserted item, instead of creating
  /// a new preloader and initializing every controller again.
  ///
  /// * A ready controller is kept, without being reinitialized, when its item
  ///   id is still present with the same `url` and falls inside the new window.
  ///   Its playback state is untouched.
  /// * Every other controller is released before any new one is created, and
  ///   controllers for newly needed items are initialized as usual. A controller
  ///   that was still initializing, or had failed, is not carried over.
  /// * The active item follows its id to its new index. When it is gone, the
  ///   same position is kept, clamped to the new length.
  /// * Pagination starts over: [hasReachedEnd] is reset, and a page that was
  ///   still being fetched for the old feed is discarded.
  ///
  /// Throws [ArgumentError] right away, changing nothing, when an id is empty
  /// or repeated. The change applies once earlier operations finish, so `await`
  /// the result before calling [scroll] with an index from the new list.
  Future<void> replaceItems(List<T> items) {
    _ensureUsable();
    final List<T> next = List<T>.of(items);
    _validateItems(next);
    _itemsGeneration++;
    return _enqueue(() => _replaceItems(next));
  }

  /// Releases every retained controller.
  Future<void> disposeAll() {
    final Future<void>? disposeFuture = _disposeFuture;
    if (disposeFuture != null) {
      return disposeFuture;
    }
    _isDisposed = true;
    _pressureRecoveryTimer?.cancel();
    _paginationBackoffTimer?.cancel();
    _initializationQueue.clear();
    _cancelRetryTimers();
    _detachFromBinding();
    _disposeFuture = _enqueue(() async {
      try {
        for (final CustomVideoController controller in _preloadWindow) {
          await _releaseWithoutBlocking(controller);
        }
      } finally {
        _preloadWindow.clear();
        _areStatesDisposed = true;
        _controllerStates.dispose();
        await _eventController.close();
      }
    });
    return _disposeFuture!;
  }

  /// Returns the controller at [index], or null when it is outside the window.
  CustomVideoController? getControllerAtIndex(int index) {
    final int offset = index - _windowStart;
    if (offset < 0 || offset >= _preloadWindow.length) {
      return null;
    }
    return _preloadWindow[offset];
  }

  /// The first global index represented by the preload window.
  int get windowStart => _windowStart;

  /// The index most recently passed to [scroll], or `-1` before the first one.
  int get activeIndex => _activeIndex;

  /// Returns the direction used to position the current preload window.
  VideoFluxDirection get preloadDirection => _preloadDirection;

  /// Attempts to play the controller at [index] when it has initialized.
  Future<void> forceAutoPlay(int index) {
    _ensureUsable();
    _validateVideoIndex(index);
    final int selectionGeneration = ++_selectionGeneration;
    return _enqueue(
      () => _forceAutoPlay(index, selectionGeneration),
    );
  }

  /// Toggles [controller] and pauses every other playing window controller.
  Future<void> togglePlayPause(CustomVideoController controller) {
    _ensureUsable();
    return _enqueue(() => _togglePlayPause(controller));
  }

  /// The remaining-item count at which [onPaginationNeeded] is called.
  int get paginationThreshold => _paginationThreshold;

  /// Updates the threshold used before calling [onPaginationNeeded].
  set paginationThreshold(int threshold) {
    if (threshold < 0) {
      throw ArgumentError.value(threshold, 'threshold', 'Cannot be negative.');
    }
    _paginationThreshold = threshold;
  }

  /// The number of items currently loaded, including appended pages.
  int get itemCount => _items.length;

  /// Updates the factory for controllers created after this call.
  void setControllerFactory(VideoControllerFactory factory) {
    _controllerFactory = factory;
  }

  /// Retries initialization for the failed controller currently retained at
  /// [index].
  ///
  /// A retry creates a fresh backend controller through [VideoControllerFactory].
  Future<void> retry(int index) {
    _ensureUsable();
    _validateVideoIndex(index);
    return _enqueue(() async {
      final CustomVideoController? controller = getControllerAtIndex(index);
      if (controller == null) {
        throw StateError('No controller is retained for index $index.');
      }
      final VideoFluxState? state = _controllerStatesByController[controller];
      if (state?.status != VideoFluxStatus.failed) {
        throw StateError('The controller at index $index has not failed.');
      }
      await _replaceController(index, controller, initializationAttempt: 1);
    });
  }

  /// Reports how constrained memory is, narrowing what the window may hold.
  ///
  /// A more severe level applies immediately. A milder one is applied one level
  /// at a time, each after [VideoFluxConfig.pressureRecoveryDuration], so a
  /// device near its limit cannot oscillate between shrinking and growing.
  /// The platform's low-memory warning is reported as
  /// [MemoryPressureLevel.critical] automatically. Has no effect when
  /// [VideoFluxConfig.adaptive] is false.
  void reportMemoryPressure(MemoryPressureLevel level) {
    _ensureUsable();
    if (!_config.adaptive) {
      return;
    }
    _pressureTarget = level;
    if (level.index > _pressure.index) {
      _applyPressure(level);
      return;
    }
    _scheduleRecovery();
  }

  /// Pauses every retained controller without changing the active index.
  Future<void> pauseAll() {
    _ensureUsable();
    return _enqueue(() async {
      if (_isDisposed) {
        return;
      }
      bool didPause = false;
      for (final CustomVideoController controller in _preloadWindow) {
        if (controller.isPlaying) {
          await controller.pause();
          didPause = true;
        }
      }
      if (didPause) {
        onPlayStateChanged?.call();
      }
    });
  }

  /// Resumes the active controller when it is retained and initialized.
  Future<void> resumeActive() {
    _ensureUsable();
    return _enqueue(() async {
      if (_isDisposed) {
        return;
      }
      final CustomVideoController? controller =
          getControllerAtIndex(_activeIndex);
      if (controller != null) {
        await _play(controller);
      }
    });
  }

  /// Starts pausing and resuming playback with app lifecycle changes.
  void bindToAppLifecycle() {
    _ensureUsable();
    _isObservingAppLifecycle = true;
  }

  /// Stops pausing and resuming playback with app lifecycle changes.
  void unbindFromAppLifecycle() {
    _isObservingAppLifecycle = false;
    _isAppLifecyclePaused = false;
    _resumeAfterLifecyclePause = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isObservingAppLifecycle || _isDisposed) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _resumeFromLifecyclePause();
      return;
    }
    _pauseForLifecycle(state);
  }

  @override
  void didHaveMemoryPressure() {
    if (!_isDisposed) {
      reportMemoryPressure(MemoryPressureLevel.critical);
    }
  }
}
