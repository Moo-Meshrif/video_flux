import 'package:flutter/widgets.dart';
import 'package:video_flux/video_flux.dart';

import '../../../../core/video_player_adapter.dart';
import 'feed_controller.dart';

/// Runs a stories feed: which story is showing, and when it advances.
///
/// The story timer starts only once the story's video is actually on screen,
/// so one that is still loading does not silently run out.
class StoriesController extends ChangeNotifier {
  /// Starts running stories for [feed]; [vsync] drives the progress timer.
  StoriesController(this.feed, {required TickerProvider vsync})
      : progress = AnimationController(vsync: vsync) {
    progress.addStatusListener(_onProgressStatus);
    feed
      ..navigator = pages.jumpToPage
      ..addListener(startWhenReady);
  }

  static const Duration _shortestStory = Duration(seconds: 3);
  static const Duration _longestStory = Duration(seconds: 8);

  /// The feed being shown.
  final FeedController feed;

  /// The page controller of the stories pager.
  final PageController pages = PageController();

  /// Progress of the current story, from 0 to 1.
  final AnimationController progress;

  /// Index of the story being shown.
  int current = 0;

  /// Starts the timer if the current story's video is ready and idle.
  void startWhenReady() {
    if (progress.isAnimating || progress.value > 0) {
      return;
    }
    final CustomVideoController? controller = feed.controllerOf(current);
    if (controller is! VideoPlayerControllerAdapter ||
        !controller.isInitialized) {
      return;
    }
    final Duration clip = controller.player.value.duration;
    progress
      ..duration = clip < _shortestStory
          ? _shortestStory
          : (clip > _longestStory ? _longestStory : clip)
      ..forward();
  }

  /// Moves to [story], if it exists.
  void goTo(int story) {
    if (story >= 0 && story < feed.videoCount) {
      pages.jumpToPage(story);
    }
  }

  /// Handles the pager settling on [story].
  void onPageChanged(int story) {
    current = story;
    progress.reset();
    notifyListeners();
    feed.onVideoFocused(story);
    startWhenReady();
  }

  /// A tap in the left third goes back; anywhere else goes forward.
  void onTapUp(TapUpDetails details, double width) =>
      goTo(current + (details.localPosition.dx < width / 3 ? -1 : 1));

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      goTo(current + 1);
    }
  }

  @override
  void dispose() {
    feed
      ..removeListener(startWhenReady)
      ..navigator = null;
    progress.dispose();
    pages.dispose();
    super.dispose();
  }
}
