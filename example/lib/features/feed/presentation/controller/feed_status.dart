/// Where a feed is in its life: fetching its first page, running, or failed.
enum FeedStatus {
  /// The first page has not arrived yet.
  loading,

  /// The preloader is running.
  ready,

  /// The first page could not be loaded.
  failure,
}
