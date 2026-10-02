import '../datasources/feed_data_source.dart';
import '../models/feed_post.dart';

/// Supplies a feed's pages, already shaped for the feed style that asked.
abstract interface class FeedRepository {
  /// Whether every page has been served.
  bool get isExhausted;

  /// Whether the next page request will fail, to exercise pagination backoff.
  bool get failNextPage;
  set failNextPage(bool value);

  /// Returns the next page of rows, or an empty list once exhausted.
  Future<List<FeedPost>> nextPage();
}

/// A [FeedRepository] that reads pages from a [FeedDataSource].
class FeedRepositoryImpl implements FeedRepository {
  /// Creates a repository over [dataSource].
  ///
  /// [includesTextPosts] is true for feed styles that mix in posts with no
  /// video; the repository asks the source for them accordingly.
  FeedRepositoryImpl(this._dataSource, {required this.includesTextPosts});

  final FeedDataSource _dataSource;

  /// Whether pages include text posts.
  final bool includesTextPosts;

  @override
  bool get isExhausted => _dataSource.isExhausted;

  @override
  bool get failNextPage => _dataSource.failNextRequest;

  @override
  set failNextPage(bool value) => _dataSource.failNextRequest = value;

  @override
  Future<List<FeedPost>> nextPage() =>
      _dataSource.fetchPage(includeText: includesTextPosts);
}
