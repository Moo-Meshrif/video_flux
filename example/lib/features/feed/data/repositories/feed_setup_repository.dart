import '../datasources/feed_setup_data_source.dart';
import '../models/feed_setup.dart';
import '../enums/feed_style.dart';

/// Reads and changes the setup each feed style runs with.
abstract interface class FeedSetupRepository {
  /// The setup currently applied to [style].
  FeedSetup setupOf(FeedStyle style);

  /// Replaces the setup of [style].
  void update(FeedStyle style, FeedSetup setup);

  /// Restores the starting setup of [style].
  void reset(FeedStyle style);
}

/// A [FeedSetupRepository] backed by a [FeedSetupDataSource].
class FeedSetupRepositoryImpl implements FeedSetupRepository {
  /// Creates a repository over [dataSource].
  FeedSetupRepositoryImpl(this._dataSource);

  final FeedSetupDataSource _dataSource;

  @override
  FeedSetup setupOf(FeedStyle style) => _dataSource.read(style);

  @override
  void update(FeedStyle style, FeedSetup setup) =>
      _dataSource.write(style, setup);

  @override
  void reset(FeedStyle style) =>
      _dataSource.write(style, FeedSetup.defaultsFor(style));
}
