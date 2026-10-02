/// The direction used to shift the retained preload window.
enum VideoFluxDirection {
  /// No direction is available before the first selection or when unchanged.
  idle,

  /// The active index increased.
  forward,

  /// The active index decreased.
  backward,
}
