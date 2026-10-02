import 'package:flutter/widgets.dart';

import 'feed_controller.dart';

/// Drives a vertical page view from a [FeedController].
///
/// Registers itself as the feed's navigator, so the debug panel can move the
/// on-screen pages the same way a finger would.
class VerticalFeedController {
  /// Starts driving pages for [feed].
  VerticalFeedController(this.feed) {
    feed.navigator = pages.jumpToPage;
  }

  /// The feed being shown.
  final FeedController feed;

  /// The page controller of the vertical page view.
  final PageController pages = PageController();

  /// Releases the page controller and unregisters from the feed.
  void dispose() {
    feed.navigator = null;
    pages.dispose();
  }
}
