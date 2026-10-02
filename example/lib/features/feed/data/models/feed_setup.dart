import 'package:video_flux/video_flux.dart';

import 'feed_content.dart';
import '../enums/feed_style.dart';

/// The configuration and content one feed style runs with.
class FeedSetup {
  /// Creates setup for one feed style.
  const FeedSetup({required this.config, required this.content});

  /// Starting setup for [style].
  factory FeedSetup.defaultsFor(FeedStyle style) => FeedSetup(
        config: style.defaultConfig,
        content: style.defaultContent,
      );

  /// The preload tuning passed to `VideoFlux`.
  final VideoFluxConfig config;

  /// What the feed shows.
  final FeedContent content;

  /// Returns a copy with the given fields replaced.
  FeedSetup copyWith({VideoFluxConfig? config, FeedContent? content}) =>
      FeedSetup(
        config: config ?? this.config,
        content: content ?? this.content,
      );
}
