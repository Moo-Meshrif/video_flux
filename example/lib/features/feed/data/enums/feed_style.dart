import 'package:flutter/material.dart';
import 'package:video_flux/video_flux.dart';

import '../../../../core/sample_content.dart';
import '../models/feed_content.dart';
import 'feed_layout.dart';

/// The feed styles the example shows, each with its own preload tuning.
enum FeedStyle {
  /// Mixed video and text posts.
  facebook(
    icon: Icons.dynamic_feed_outlined,
    layout: FeedLayout.timeline,
    includesTextPosts: true,
    defaultConfig: VideoFluxConfig(
      preloadBackward: 1,
      preloadForward: 2,
      windowSize: 4,
      scrollDebounce: Duration(milliseconds: 150),
    ),
  ),

  /// Full-screen vertical feed.
  tikTok(
    icon: Icons.smart_display_outlined,
    layout: FeedLayout.vertical,
    includesTextPosts: false,
    defaultConfig: VideoFluxConfig.tikTok(),
  ),

  /// Vertical feed users scrub back through.
  shorts(
    icon: Icons.movie_filter_outlined,
    layout: FeedLayout.vertical,
    includesTextPosts: false,
    defaultConfig: VideoFluxConfig.shorts(),
  ),

  /// Tap-through stories.
  stories(
    icon: Icons.amp_stories_outlined,
    layout: FeedLayout.stories,
    includesTextPosts: false,
    defaultConfig: VideoFluxConfig(
      preloadBackward: 0,
      preloadForward: 1,
      windowSize: 2,
      scrollDebounce: Duration.zero,
    ),
  );

  const FeedStyle({
    required this.icon,
    required this.layout,
    required this.includesTextPosts,
    required this.defaultConfig,
  });

  /// Icon shown on the home screen.
  final IconData icon;

  /// How the feed is laid out.
  final FeedLayout layout;

  /// Whether the feed mixes in posts that carry no video.
  final bool includesTextPosts;

  /// The preload tuning this feed shape starts with.
  final VideoFluxConfig defaultConfig;

  /// The content this feed starts with, before the user edits it.
  FeedContent get defaultContent => includesTextPosts
      ? const FeedContent(
          videoUrls: sampleVideoUrls,
          textPosts: sampleTextPosts,
        )
      : const FeedContent(videoUrls: sampleVideoUrls);
}
