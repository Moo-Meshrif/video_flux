/// Contract implemented by the application's selected video-player backend.
///
/// This package deliberately does not provide a player implementation. The
/// application owns its player dependency and supplies a factory that creates
/// one controller for each video source.
abstract class CustomVideoController {
  /// Initializes the backend and prepares the source for playback.
  ///
  /// The preloader stops waiting after `VideoFluxConfig.initializationTimeout`
  /// but cannot cancel this call. Implement [dispose] so that it aborts a
  /// pending initialization and releases native resources, because that is how
  /// an abandoned or evicted initialization is stopped.
  Future<void> initialize();

  /// Starts playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Releases the resources held by the backend.
  ///
  /// May be called while [initialize] is still pending. The preloader does not
  /// await this for a controller that has not finished initializing, so a slow
  /// backend never stalls scrolling or disposal.
  Future<void> dispose();

  /// Whether the backend is currently playing.
  bool get isPlaying;

  /// Whether initialization completed successfully.
  bool get isInitialized;

  /// The source identifier associated with this controller.
  String get dataSource;

  /// Decodes the first frame so the video paints immediately when shown.
  ///
  /// Called once after [initialize] succeeds. Override it to seek to the start
  /// and pause, which removes the black flash before playback begins. Failures
  /// are ignored: a missing warm-up only costs that flash, never the video.
  Future<void> warmUp() async {}

  /// Toggles playback according to the current backend state.
  Future<void> togglePlayPause() => isPlaying ? pause() : play();
}
