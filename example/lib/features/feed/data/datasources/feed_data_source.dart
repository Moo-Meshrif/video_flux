import '../models/feed_content.dart';
import '../models/feed_post.dart';

/// Where a feed's pages come from.
///
/// The example has no backend, so the only implementation is simulated. A real
/// app would put its network client behind this interface.
abstract interface class FeedDataSource {
  /// Whether every page has been served.
  bool get isExhausted;

  /// Whether the next request will fail, to exercise pagination backoff.
  bool get failNextRequest;
  set failNextRequest(bool value);

  /// Returns the next page of rows, or an empty list once exhausted.
  ///
  /// Text posts are included only when [includeText] is true.
  Future<List<FeedPost>> fetchPage({required bool includeText});
}

/// Serves [content] page by page, like a paginated API with some latency.
class SimulatedFeedDataSource implements FeedDataSource {
  /// Creates a source over [content] whose requests take [latency].
  SimulatedFeedDataSource({
    required this.content,
    this.latency = const Duration(milliseconds: 300),
  });

  /// The content being served.
  final FeedContent content;

  /// How long each request takes.
  final Duration latency;

  int _nextVideo = 0;
  int _nextText = 0;

  @override
  bool failNextRequest = false;

  @override
  bool get isExhausted => _nextVideo >= content.totalVideos;

  @override
  Future<List<FeedPost>> fetchPage({required bool includeText}) async {
    await Future<void>.delayed(latency);
    if (failNextRequest) {
      failNextRequest = false;
      throw StateError('Simulated pagination failure');
    }
    final List<FeedPost> rows = <FeedPost>[];
    final bool hasText = includeText && content.textPosts.isNotEmpty;
    for (int served = 0; served < content.pageSize && !isExhausted; served++) {
      final int video = _nextVideo++;
      if (hasText && video % content.textEvery == 0) {
        rows.add(_nextTextPost());
      }
      rows.add(
        VideoPost(
          id: 'video-$video',
          url: content.videoUrls[video % content.videoUrls.length],
          number: video + 1,
        ),
      );
    }
    return rows;
  }

  TextPost _nextTextPost() {
    final int index = _nextText++;
    return TextPost(
      id: 'text-$index',
      authorNumber: index % 5 + 1,
      body: content.textPosts[index % content.textPosts.length],
    );
  }
}
