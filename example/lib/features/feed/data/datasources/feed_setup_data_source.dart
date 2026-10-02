import '../models/feed_setup.dart';
import '../enums/feed_style.dart';

/// Where each feed style's [FeedSetup] is kept.
abstract interface class FeedSetupDataSource {
  /// The setup currently stored for [style].
  FeedSetup read(FeedStyle style);

  /// Stores [setup] for [style].
  void write(FeedStyle style, FeedSetup setup);
}

/// Keeps setups in memory, so they reset when the app restarts.
class InMemoryFeedSetupDataSource implements FeedSetupDataSource {
  final Map<FeedStyle, FeedSetup> _setups = <FeedStyle, FeedSetup>{
    for (final FeedStyle style in FeedStyle.values)
      style: FeedSetup.defaultsFor(style),
  };

  @override
  FeedSetup read(FeedStyle style) => _setups[style]!;

  @override
  void write(FeedStyle style, FeedSetup setup) => _setups[style] = setup;
}
