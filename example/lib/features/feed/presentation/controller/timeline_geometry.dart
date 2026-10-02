import '../../data/models/feed_post.dart';

/// Where each row of a fixed-height timeline sits on the scroll axis.
///
/// Fixed heights let the feed decide which row is in focus from the scroll
/// offset alone, with no per-row visibility plugin.
class TimelineGeometry {
  /// Creates geometry for rows with the given [heights].
  TimelineGeometry(List<double> heights)
      : _offsets = _prefixSums(heights),
        rowCount = heights.length;

  /// Creates geometry for [rows] whose videos are [videoSurfaceHeight] tall.
  factory TimelineGeometry.forRows(
    List<FeedPost> rows, {
    double videoSurfaceHeight = defaultVideoSurfaceHeight,
  }) =>
      TimelineGeometry(
        rows
            .map((FeedPost post) => heightOf(post, videoSurfaceHeight))
            .toList(growable: false),
      );

  /// Height of a text post: its content (132) plus the engagement row (81).
  static const double textHeight = 213;

  /// Height of everything in a video post except the video itself: the card
  /// header and margins, the engagement row (81) and a comment preview (56).
  static const double videoChromeHeight = 213;

  /// The video height used until the screen size is known.
  static const double defaultVideoSurfaceHeight = 364;

  /// The share of the screen height a video may take.
  static const double videoHeightFraction = 0.5;

  /// The height a row of [post]'s style is drawn at.
  static double heightOf(FeedPost post, double videoSurfaceHeight) =>
      switch (post) {
        TextPost() => textHeight,
        VideoPost() => videoChromeHeight + videoSurfaceHeight,
      };

  /// Number of rows.
  final int rowCount;

  final List<double> _offsets;

  /// Scroll offset at which [row] starts.
  double offsetOf(int row) => _offsets[row];

  /// Height of [row].
  double extentOf(int row) => _offsets[row + 1] - _offsets[row];

  /// The row that contains [offset], clamped to the first and last rows.
  int rowAt(double offset) {
    int low = 0;
    int high = rowCount - 1;
    while (low < high) {
      final int middle = (low + high + 1) ~/ 2;
      if (_offsets[middle] <= offset) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  static List<double> _prefixSums(List<double> heights) {
    final List<double> offsets = <double>[0];
    for (final double height in heights) {
      offsets.add(offsets.last + height);
    }
    return offsets;
  }
}
