import 'package:flutter/material.dart';

import '../../../data/models/feed_post.dart';
import '../../controller/feed_controller.dart';
import '../../controller/timeline_feed_controller.dart';
import 'text_post_card.dart';
import 'video_post_card.dart';

/// A scrolling list mixing video and text posts (Facebook-style).
class TimelineFeedView extends StatefulWidget {
  /// Creates the view for [feed].
  const TimelineFeedView({required this.feed, super.key});

  /// The feed to show.
  final FeedController feed;

  @override
  State<TimelineFeedView> createState() => _TimelineFeedViewState();
}

class _TimelineFeedViewState extends State<TimelineFeedView> {
  late final TimelineFeedController _controller =
      TimelineFeedController(widget.feed);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.updateFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.feed,
        builder: (BuildContext context, Widget? child) {
          final List<FeedPost> rows = widget.feed.rows;
          _controller.syncRows(
            rows,
            screenHeight: MediaQuery.sizeOf(context).height,
          );
          return ListView.builder(
            controller: _controller.scroll,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: rows.length,
            itemBuilder: (BuildContext context, int index) => SizedBox(
              height: _controller.geometry.extentOf(index),
              child: switch (rows[index]) {
                final TextPost post =>
                  TextPostCard(key: ValueKey(post.id), post: post),
                final VideoPost post => VideoPostCard(
                    key: ValueKey(post.id),
                    feed: widget.feed,
                    post: post,
                    videoIndex: widget.feed.videoIndexOfRow(index)!,
                  ),
              },
            ),
          );
        },
      );
}
