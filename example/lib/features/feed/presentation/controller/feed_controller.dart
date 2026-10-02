import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_flux/video_flux.dart';

import '../../../../core/playback_memory.dart';
import '../../data/models/feed_post.dart';
import '../../data/models/feed_setup.dart';
import '../../data/enums/feed_style.dart';
import '../../data/repositories/feed_repository.dart';
import 'feed_status.dart';

/// Moves the on-screen feed to a video; supplied by the layout.
typedef VideoNavigator = void Function(int videoIndex);

/// An event the preloader emitted, with when it happened.
class LoggedEvent {
  /// Creates a log entry.
  const LoggedEvent(this.at, this.event);

  /// Time since the feed started.
  final Duration at;

  /// What the preloader reported.
  final VideoFluxEvent event;
}

/// Runs one feed: its rows, its paginated content and its `VideoFlux`.
///
/// Rows are what the screen draws; videos are the subset `VideoFlux` manages.
/// In a feed with text posts the two index spaces differ, and this class maps
/// between them, so layouts only ever deal in rows or in videos, never both.
class FeedController extends ChangeNotifier {
  /// Prepares a feed of [style] from [setup]; call [load] to start it.
  FeedController({
    required this.style,
    required this.setup,
    required FeedRepository repository,
    required VideoControllerFactory controllerFactory,
    PlaybackMemory? playbackMemory,
    this.posters,
  })  : _repository = repository,
        _controllerFactory = controllerFactory,
        _playbackMemory = playbackMemory;

  static const int _maxLoggedEvents = 300;

  /// The feed style being run.
  final FeedStyle style;

  /// The configuration and content this feed runs with.
  final FeedSetup setup;

  /// Last frames of videos, shown while one initializes again; optional.
  final PosterCache? posters;

  /// The preloader being exercised; available once [status] is ready.
  late final VideoFlux<VideoPost> preloader;

  /// Bumped whenever a new event is logged; debug views listen to it.
  final ValueNotifier<int> eventRevision = ValueNotifier<int>(0);

  /// Set by the layout so the debug panel can move the feed.
  VideoNavigator? navigator;

  final FeedRepository _repository;
  final VideoControllerFactory _controllerFactory;
  final PlaybackMemory? _playbackMemory;
  final List<FeedPost> _rows = <FeedPost>[];
  final List<VideoPost> _videos = <VideoPost>[];
  final List<int> _rowOfVideo = <int>[];
  final List<int?> _videoOfRow = <int?>[];
  final List<LoggedEvent> _eventLog = <LoggedEvent>[];
  final Stopwatch _clock = Stopwatch()..start();
  late final StreamSubscription<VideoFluxEvent> _eventSubscription;
  Timer? _flickTimer;
  int _activeVideo = 0;
  FeedStatus _status = FeedStatus.loading;
  String? _errorMessage;
  bool _isPreloaderCreated = false;
  bool _isDisposed = false;

  /// Whether the feed is loading, running or failed.
  FeedStatus get status => _status;

  /// Why the first page failed, when [status] is failure.
  String? get errorMessage => _errorMessage;

  /// Every row loaded so far, in display order.
  List<FeedPost> get rows => List<FeedPost>.unmodifiable(_rows);

  /// Every video loaded so far, in display order.
  List<VideoPost> get videos => List<VideoPost>.unmodifiable(_videos);

  /// How many videos are loaded.
  int get videoCount => _videos.length;

  /// The video most recently selected.
  int get activeVideo => _activeVideo;

  /// The most recent events, oldest first.
  List<LoggedEvent> get eventLog => List<LoggedEvent>.unmodifiable(_eventLog);

  /// Whether the next page request will fail, to exercise pagination backoff.
  bool get failNextPage => _repository.failNextPage;

  set failNextPage(bool value) {
    _repository.failNextPage = value;
    notifyListeners();
  }

  /// The video at [row], or null when that row is not a video.
  int? videoIndexOfRow(int row) =>
      row < 0 || row >= _videoOfRow.length ? null : _videoOfRow[row];

  /// The row that shows [video].
  int rowOfVideo(int video) => _rowOfVideo[video];

  /// The controller retained for [video], or null outside the window.
  CustomVideoController? controllerOf(int video) =>
      preloader.getControllerAtIndex(video);

  /// The lifecycle state of [video]'s controller, or null outside the window.
  VideoFluxState<VideoPost>? stateOf(int video) {
    for (final VideoFluxState<VideoPost> state
        in preloader.controllerStates.value) {
      if (state.index == video) {
        return state;
      }
    }
    return null;
  }

  /// Fetches the first page and starts the preloader.
  Future<void> load() async {
    try {
      _append(await _repository.nextPage());
    } catch (error) {
      if (!_isDisposed) {
        _errorMessage = error.toString();
        _status = FeedStatus.failure;
        notifyListeners();
      }
      return;
    }
    if (_isDisposed) {
      return;
    }
    preloader = VideoFlux<VideoPost>(
      items: _videos,
      controllerFactory: _controllerFactory,
      config: setup.config.copyWith(
        autoplayFirstVideo: true,
      ),
      onPaginationNeeded: _loadNextPage,
    );
    _isPreloaderCreated = true;
    preloader.controllerStates.addListener(_onStatesChanged);
    _eventSubscription = preloader.events.listen(_onEvent);
    _status = FeedStatus.ready;
    notifyListeners();
  }

  /// Selects [video] and moves the preload window to it.
  Future<void> onVideoFocused(int video, {double? scrollVelocity}) async {
    if (_isDisposed || video < 0 || video >= _videos.length) {
      return;
    }
    _activeVideo = video;
    notifyListeners();
    await preloader.scroll(video, scrollVelocity: scrollVelocity);
  }

  /// Selects the video at [row]; does nothing for a row with no video.
  Future<void> onRowFocused(int row) async {
    final int? video = videoIndexOfRow(row);
    if (video != null && video != _activeVideo) {
      await onVideoFocused(video);
    }
  }

  /// Toggles playback of [controller].
  Future<void> togglePlayback(CustomVideoController controller) async {
    if (_isDisposed) {
      return;
    }
    _playbackMemory?.setPausedByUser(
      controller.dataSource,
      paused: controller.isPlaying,
    );
    await preloader.togglePlayPause(controller);
    notifyListeners();
  }

  /// Retries every controller whose initialization failed for good.
  void retryFailed() {
    for (final VideoFluxState<VideoPost> state
        in preloader.controllerStates.value) {
      if (state.status == VideoFluxStatus.failed) {
        unawaited(preloader.retry(state.index).catchError((Object _) {}));
      }
    }
  }

  /// Reports [level] as if the platform had, and shows the effect.
  void reportPressure(MemoryPressureLevel level) {
    preloader.reportMemoryPressure(level);
    notifyListeners();
  }

  /// Moves the feed to [video] in one jump.
  void jumpTo(int video) => navigator?.call(video.clamp(0, _videos.length - 1));

  /// Steps through [steps] videos quickly, like a flick of the finger.
  ///
  /// The steps go through the on-screen feed, so they reach `VideoFlux` the
  /// same way real scrolling does and exercise the debounce.
  void flick({required bool forward, int steps = 10}) {
    _flickTimer?.cancel();
    int position = _activeVideo;
    int remaining = steps;
    _flickTimer = Timer.periodic(const Duration(milliseconds: 40), (Timer t) {
      final int next = position + (forward ? 1 : -1);
      if (remaining-- <= 0 || next < 0 || next >= _videos.length) {
        t.cancel();
        return;
      }
      position = next;
      navigator?.call(position);
    });
  }

  /// Empties the event log.
  void clearEventLog() {
    _eventLog.clear();
    eventRevision.value++;
  }

  Future<List<VideoPost>> _loadNextPage() async {
    final List<FeedPost> page = await _repository.nextPage();
    if (_isDisposed) {
      return const <VideoPost>[];
    }
    final List<VideoPost> added = _append(page);
    notifyListeners();
    return added;
  }

  /// Adds [page] to the rows and returns the videos it contained.
  List<VideoPost> _append(List<FeedPost> page) {
    final List<VideoPost> added = <VideoPost>[];
    for (final FeedPost post in page) {
      final int row = _rows.length;
      _rows.add(post);
      switch (post) {
        case VideoPost():
          _videoOfRow.add(_videos.length);
          _rowOfVideo.add(row);
          _videos.add(post);
          added.add(post);
        case TextPost():
          _videoOfRow.add(null);
      }
    }
    return added;
  }

  void _onStatesChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _onEvent(VideoFluxEvent event) {
    _eventLog.add(LoggedEvent(_clock.elapsed, event));
    if (_eventLog.length > _maxLoggedEvents) {
      _eventLog.removeAt(0);
    }
    eventRevision.value++;
  }

  @override
  void notifyListeners() {
    // Async work (a page arriving, a scroll finishing) can outlive the feed.
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _flickTimer?.cancel();
    if (_isPreloaderCreated) {
      preloader.controllerStates.removeListener(_onStatesChanged);
      unawaited(_eventSubscription.cancel());
      unawaited(preloader.disposeAll());
    }
    eventRevision.dispose();
    super.dispose();
  }
}
