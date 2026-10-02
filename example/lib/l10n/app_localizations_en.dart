import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Video Flux';

  @override
  String get editContent => 'Edit content';

  @override
  String get editConfiguration => 'Edit configuration';

  @override
  String resetStyle(String style) {
    return 'Reset $style to its defaults';
  }

  @override
  String get debugPanel => 'Debug panel';

  @override
  String get closeDebugPanel => 'Close debug panel';

  @override
  String get switchLanguage => 'Switch language';

  @override
  String get close => 'Close';

  @override
  String get styleFacebook => 'Facebook';

  @override
  String get styleTikTok => 'TikTok';

  @override
  String get styleShorts => 'Shorts';

  @override
  String get styleStories => 'Stories';

  @override
  String get styleFacebookTitle => 'Facebook feed';

  @override
  String get styleTikTokTitle => 'TikTok';

  @override
  String get styleShortsTitle => 'Shorts';

  @override
  String get styleStoriesTitle => 'Stories';

  @override
  String get styleFacebookSummary => 'Video posts between text posts in a scrolling list. Only the videos are preloaded, one ahead.';

  @override
  String get styleTikTokSummary => 'Full-screen vertical pages, one video each. Looks one behind and two ahead.';

  @override
  String get styleShortsSummary => 'Same shape, but keeps two behind as well, because people scrub backwards.';

  @override
  String get styleStoriesSummary => 'Horizontal, tap to advance, auto-advances when a clip ends. Keeps only the next one warm.';

  @override
  String get couldNotLoadFeed => 'Could not load the feed.';

  @override
  String get tryAgain => 'Try again';

  @override
  String clipCaption(int number, int total) {
    return 'Clip $number of $total';
  }

  @override
  String videoNumber(int number) {
    return 'Video $number';
  }

  @override
  String authorName(int number) {
    return 'Author $number';
  }

  @override
  String positionOfTotal(int position, int total) {
    return '$position / $total';
  }

  @override
  String get outsideWindow => 'Outside the preload window — not loaded';

  @override
  String initializingAttempt(int attempt) {
    return 'Initializing (attempt $attempt)…';
  }

  @override
  String couldNotLoadVideo(String error) {
    return 'Could not load this video\n$error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get share => 'Share';

  @override
  String commentsAndShares(int comments, int shares) {
    return '$comments comments · $shares shares';
  }

  @override
  String get sampleCommenter => 'Sara';

  @override
  String get sampleComment => 'Smooth! No stutter at all when I swipe.';

  @override
  String contentTitle(String style) {
    return '$style content';
  }

  @override
  String configTitle(String style) {
    return '$style configuration';
  }

  @override
  String get savingRestartsFeed => 'Saving restarts the feed.';

  @override
  String get applyingRestartsFeed => 'Applying restarts the feed.';

  @override
  String get videoUrlsLabel => 'Video URLs, one per line';

  @override
  String playableSummary(int valid) {
    return '$valid playable';
  }

  @override
  String playableSummarySkipped(int valid, int skipped) {
    return '$valid playable, $skipped skipped (not http/https)';
  }

  @override
  String get addBrokenUrl => 'Add a broken URL';

  @override
  String get resetToSamples => 'Reset to samples';

  @override
  String get textPostsLabel => 'Text posts, one per line';

  @override
  String get textPostBeforeEvery => 'A text post before every';

  @override
  String get nthVideo => 'Nth video';

  @override
  String get videosPerPage => 'Videos per page';

  @override
  String get repeatTheList => 'Repeat the list';

  @override
  String get repeatHint => 'After this many passes the feed ends.';

  @override
  String repeatCount(int count) {
    return '$count×';
  }

  @override
  String feedHoldsTotal(int count) {
    return 'The feed holds $count videos in total.';
  }

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get resetToPreset => 'Reset to preset';

  @override
  String decreaseField(String label) {
    return 'Decrease $label';
  }

  @override
  String increaseField(String label) {
    return 'Increase $label';
  }

  @override
  String get sectionWindow => 'Window';

  @override
  String get sectionFastScrolling => 'Fast scrolling';

  @override
  String get sectionPagination => 'Pagination';

  @override
  String get sectionMemory => 'Memory';

  @override
  String get sectionFailures => 'Failures';

  @override
  String get fieldBehind => 'Behind';

  @override
  String get fieldAhead => 'Ahead';

  @override
  String get fieldWindowSize => 'Window size';

  @override
  String get fieldWindowSizeHint => 'Must exceed behind + ahead.';

  @override
  String get fieldDirectionBias => 'Direction bias';

  @override
  String get fieldDirectionBiasHint => 'Extra items toward the scroll direction.';

  @override
  String get fieldVelocityPreload => 'Velocity preload';

  @override
  String get fieldVelocityPreloadHint => 'Extra items for fast scrolling (needs a velocity).';

  @override
  String get fieldConcurrentInits => 'Concurrent initializations';

  @override
  String get unlimited => 'unlimited';

  @override
  String get fieldScrollDebounce => 'Scroll debounce';

  @override
  String millisecondsValue(int value) {
    return '$value ms';
  }

  @override
  String get fieldJumpThreshold => 'Jump threshold';

  @override
  String get fieldJumpThresholdHint => 'A move this big skips the debounce.';

  @override
  String get fieldPaginationThreshold => 'Pagination threshold';

  @override
  String get fieldPaginationThresholdHint => 'Load more when this few items remain.';

  @override
  String get fieldAdaptive => 'Adaptive';

  @override
  String get fieldAdaptiveHint => 'Narrow by device tier and memory pressure.';

  @override
  String get fieldDeviceTier => 'Device tier';

  @override
  String get fieldRetryPolicy => 'Retry policy';

  @override
  String get tierAuto => 'Auto-detect';

  @override
  String get tierLow => 'Force low';

  @override
  String get tierMid => 'Force mid';

  @override
  String get tierHigh => 'Force high';

  @override
  String get retryExponential => 'Exponential, 1 retry';

  @override
  String get retryExponentialThree => 'Exponential, 3 retries';

  @override
  String get retryFixed => 'Fixed delay, 2 retries';

  @override
  String get retryNone => 'No retry';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabWindow => 'Window';

  @override
  String get tabEvents => 'Events';

  @override
  String get tabControls => 'Controls';

  @override
  String eventsCount(int count) {
    return '$count events';
  }

  @override
  String get clear => 'Clear';

  @override
  String get legendNotLoaded => 'not loaded';

  @override
  String get legendInitializing => 'initializing';

  @override
  String get legendReady => 'ready';

  @override
  String get legendFailed => 'failed';

  @override
  String get firstRetainedIndex => 'first retained index';

  @override
  String get activeIndex => 'active index';

  @override
  String get direction => 'direction';

  @override
  String get videosLoaded => 'videos loaded';

  @override
  String get rowsLoaded => 'rows loaded';

  @override
  String get tapCellToJump => 'Tap a cell to jump there.';

  @override
  String get statsWindow => 'Window';

  @override
  String get statsWork => 'Work';

  @override
  String get statsScrolling => 'Scrolling';

  @override
  String get statsEnvironment => 'Environment';

  @override
  String get statsEnforced => 'Enforced vs configured';

  @override
  String get statRetainedWindow => 'retained / window size';

  @override
  String get statReady => 'ready';

  @override
  String get statInitializing => 'initializing';

  @override
  String get statFailed => 'failed';

  @override
  String get statQueued => 'queued for a slot';

  @override
  String get statInitsStarted => 'initializations started';

  @override
  String get statSucceeded => 'succeeded';

  @override
  String get statFailedAttempts => 'failed attempts';

  @override
  String get statRetried => 'retried';

  @override
  String get statDropped => 'dropped before starting';

  @override
  String get statReleased => 'controllers released';

  @override
  String get statScrolls => 'scrolls that took effect';

  @override
  String get statPoolHit => 'pool hit rate';

  @override
  String get statAvgInit => 'avg init';

  @override
  String get statP95Init => 'p95 init';

  @override
  String get statDeviceTier => 'device tier';

  @override
  String get statMemoryPressure => 'memory pressure';

  @override
  String get statPagination => 'pagination';

  @override
  String get paginationReachedEnd => 'reached the end';

  @override
  String get paginationMoreAvailable => 'more available';

  @override
  String get statBehindAhead => 'behind / ahead';

  @override
  String get statWindow => 'window';

  @override
  String get statConcurrentInits => 'concurrent inits';

  @override
  String withConfig(String value, String config) {
    return '$value   (config $config)';
  }

  @override
  String get controlsMemoryPressure => 'Memory pressure';

  @override
  String get memoryPressureHint => 'Shrinking is immediate. Choosing a milder level grows the window back one level at a time.';

  @override
  String get pressureNone => 'none';

  @override
  String get pressureModerate => 'moderate';

  @override
  String get pressureCritical => 'critical';

  @override
  String get controlsScrolling => 'Scrolling';

  @override
  String get flickForward => 'Flick ×10 forward';

  @override
  String get flickBack => 'Flick ×10 back';

  @override
  String get jumpFirst => 'Jump to first';

  @override
  String get jumpMiddle => 'Jump to middle';

  @override
  String get jumpLast => 'Jump to last loaded';

  @override
  String get flickHint => 'A flick steps one video every 40 ms: watch the debounce collapse it, and \"dropped before starting\" climb.';

  @override
  String get controlsFailures => 'Failures';

  @override
  String get failNextPage => 'Fail the next page request';

  @override
  String get failNextPageHint => 'Exercises pagination backoff.';

  @override
  String get retryAllFailed => 'Retry every failed video';

  @override
  String get failuresHint => 'Add a broken URL in \"Edit content\" to see retries and failure states.';

  @override
  String get settings => 'Settings';
}
