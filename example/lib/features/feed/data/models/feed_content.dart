/// The content a feed is built from; editable by the user.
class FeedContent {
  /// Creates content from [videoUrls], repeated [loops] times.
  const FeedContent({
    required this.videoUrls,
    this.textPosts = const <String>[],
    this.textEvery = 2,
    this.pageSize = 4,
    this.loops = 1,
  });

  /// Playable URLs, in feed order.
  final List<String> videoUrls;

  /// Bodies of the text posts interleaved between videos, when supported.
  final List<String> textPosts;

  /// A text post appears before every Nth video.
  final int textEvery;

  /// Videos returned per page.
  final int pageSize;

  /// How many times [videoUrls] repeats before the feed ends.
  ///
  /// The feed then returns an empty page, which sets `hasReachedEnd`.
  final int loops;

  /// Every video the feed will ever produce.
  int get totalVideos => videoUrls.length * loops;

  /// Splits [raw] into trimmed, non-empty lines.
  static List<String> parseLines(String raw) => raw
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList(growable: false);

  /// Whether [value] looks like an http(s) URL a player could open.
  static bool isPlayableUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Returns a copy with the given fields replaced.
  FeedContent copyWith({
    List<String>? videoUrls,
    List<String>? textPosts,
    int? textEvery,
    int? pageSize,
    int? loops,
  }) =>
      FeedContent(
        videoUrls: videoUrls ?? this.videoUrls,
        textPosts: textPosts ?? this.textPosts,
        textEvery: textEvery ?? this.textEvery,
        pageSize: pageSize ?? this.pageSize,
        loops: loops ?? this.loops,
      );
}
