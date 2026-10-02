import 'package:video_flux/video_flux.dart';

import 'core/playback_memory.dart';
import 'core/video_player_adapter.dart';
import 'features/feed/data/datasources/feed_data_source.dart';
import 'features/feed/data/datasources/feed_setup_data_source.dart';
import 'features/feed/data/models/feed_setup.dart';
import 'features/feed/data/enums/feed_style.dart';
import 'features/feed/data/repositories/feed_repository.dart';
import 'features/feed/data/repositories/feed_setup_repository.dart';
import 'features/feed/presentation/controller/feed_setup_controller.dart';

/// The example's dependencies, wired in one place and handed down the tree.
///
/// This is the only place that picks concrete data sources, so swapping the
/// simulated feed for a real API changes one method.
class AppDependencies {
  /// Creates the dependencies around [controllerFactory], which defaults to
  /// the `video_player` adapter wired to [playbackMemory].
  ///
  /// [pageLatency] is how long a simulated page takes to arrive; tests pass
  /// [Duration.zero].
  AppDependencies({
    VideoControllerFactory? controllerFactory,
    this.pageLatency = const Duration(milliseconds: 300),
  }) : setups = FeedSetupController(
          FeedSetupRepositoryImpl(InMemoryFeedSetupDataSource()),
        ) {
    this.controllerFactory = controllerFactory ??
        (String url) =>
            VideoPlayerControllerAdapter(url, memory: playbackMemory);
  }

  /// Creates a backend video controller per video.
  late final VideoControllerFactory controllerFactory;

  /// What the user last did with each video, kept for this run only.
  final PlaybackMemory playbackMemory = PlaybackMemory();

  /// The last frame of each video, shown while one initializes again.
  final PosterCache posters = PosterCache();

  /// How long a simulated page takes to arrive.
  final Duration pageLatency;

  /// Every feed style's setup, observable.
  final FeedSetupController setups;

  /// The repository a feed of [style] reads its pages from, using [setup].
  FeedRepository feedRepositoryFor(FeedStyle style, FeedSetup setup) =>
      FeedRepositoryImpl(
        SimulatedFeedDataSource(content: setup.content, latency: pageLatency),
        includesTextPosts: style.includesTextPosts,
      );

  /// Releases what the dependencies own.
  void dispose() {
    setups.dispose();
    posters.dispose();
  }
}
