/// Contract for an item that can be preloaded by `VideoFlux`.
abstract interface class VideoFluxItem {
  /// Stable identifier, unique within a preloader instance.
  String get id;

  /// Source URL passed to the configured video controller factory.
  String get url;
}
