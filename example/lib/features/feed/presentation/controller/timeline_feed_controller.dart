import 'package:flutter/widgets.dart';

import '../../data/models/feed_post.dart';
import 'feed_controller.dart';
import 'timeline_geometry.dart';

/// Turns scrolling in a mixed list into "which video is in focus".
///
/// `VideoFlux` only knows about videos, so this maps the scroll offset to a row
/// and the row to a video, ignoring rows that carry none.
class TimelineFeedController {
  /// Starts driving the list for [feed].
  TimelineFeedController(this.feed)
      : geometry = TimelineGeometry.forRows(feed.rows) {
    scroll.addListener(updateFocus);
    feed.navigator = jumpToVideo;
  }

  /// Fraction of the viewport, from the top, that counts as "in focus".
  static const double focusLine = 0.4;

  /// The feed being shown.
  final FeedController feed;

  /// The list's scroll controller.
  final ScrollController scroll = ScrollController();

  /// Where each row sits on the scroll axis; rebuilt when rows are added.
  TimelineGeometry geometry;

  double _videoSurfaceHeight = TimelineGeometry.defaultVideoSurfaceHeight;

  /// Rebuilds [geometry] if [rows] changed length or the video height did.
  void syncRows(List<FeedPost> rows, {required double screenHeight}) {
    final double videoSurfaceHeight =
        screenHeight * TimelineGeometry.videoHeightFraction;
    if (rows.length != geometry.rowCount ||
        videoSurfaceHeight != _videoSurfaceHeight) {
      _videoSurfaceHeight = videoSurfaceHeight;
      geometry = TimelineGeometry.forRows(
        rows,
        videoSurfaceHeight: videoSurfaceHeight,
      );
    }
  }

  /// Selects the video at the focus line, if the row there has one.
  void updateFocus() {
    if (!scroll.hasClients) {
      return;
    }
    final ScrollPosition position = scroll.position;
    final double focusOffset =
        position.pixels + position.viewportDimension * focusLine;
    feed.onRowFocused(geometry.rowAt(focusOffset));
  }

  /// Scrolls so [video]'s row is at the top.
  void jumpToVideo(int video) {
    if (scroll.hasClients) {
      scroll.jumpTo(geometry.offsetOf(feed.rowOfVideo(video)));
    }
  }

  /// Releases the scroll controller and unregisters from the feed.
  void dispose() {
    feed.navigator = null;
    scroll.dispose();
  }
}
