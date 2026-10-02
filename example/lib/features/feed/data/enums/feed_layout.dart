/// How a feed style arranges its posts on screen.
enum FeedLayout {
  /// One full-screen video per vertical page.
  vertical,

  /// A scrolling list mixing video and text posts.
  timeline,

  /// Horizontal pages that advance on tap or when a clip ends.
  stories,
}
