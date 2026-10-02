import 'package:flutter/material.dart';

import '../../controller/feed_controller.dart';
import '../video_surface.dart';
import '../../controller/vertical_feed_controller.dart';
import 'video_caption_overlay.dart';

/// A full-screen vertical feed: one video per page (TikTok, Shorts).
class VerticalFeedView extends StatefulWidget {
  /// Creates the view for [feed].
  const VerticalFeedView({required this.feed, super.key});

  /// The feed to show.
  final FeedController feed;

  @override
  State<VerticalFeedView> createState() => _VerticalFeedViewState();
}

class _VerticalFeedViewState extends State<VerticalFeedView> {
  late final VerticalFeedController _controller =
      VerticalFeedController(widget.feed);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.feed,
        builder: (BuildContext context, Widget? child) => PageView.builder(
          controller: _controller.pages,
          scrollDirection: Axis.vertical,
          itemCount: widget.feed.videoCount,
          onPageChanged: widget.feed.onVideoFocused,
          itemBuilder: (BuildContext context, int index) => Stack(
            key: ValueKey<String>(widget.feed.videos[index].id),
            fit: StackFit.expand,
            children: <Widget>[
              VideoSurface(feed: widget.feed, videoIndex: index),
              VideoCaptionOverlay(
                number: widget.feed.videos[index].number,
                videoTotal: widget.feed.setup.content.totalVideos,
                position: index + 1,
                total: widget.feed.videoCount,
              ),
            ],
          ),
        ),
      );
}
