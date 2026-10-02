import 'package:flutter/material.dart';

import '../../controller/feed_controller.dart';
import '../video_surface.dart';
import '../../controller/stories_controller.dart';
import 'story_progress_bar.dart';

/// Horizontal stories: tap to move, and advance when a clip has played.
class StoriesView extends StatefulWidget {
  /// Creates the view for [feed].
  const StoriesView({required this.feed, super.key});

  /// The feed to show.
  final FeedController feed;

  @override
  State<StoriesView> createState() => _StoriesViewState();
}

class _StoriesViewState extends State<StoriesView>
    with SingleTickerProviderStateMixin {
  late final StoriesController _controller =
      StoriesController(widget.feed, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ListenableBuilder(
              listenable: widget.feed,
              builder: (BuildContext context, Widget? child) =>
                  PageView.builder(
                controller: _controller.pages,
                itemCount: widget.feed.videoCount,
                onPageChanged: _controller.onPageChanged,
                itemBuilder: (BuildContext context, int index) => VideoSurface(
                  key: ValueKey<String>(widget.feed.videos[index].id),
                  feed: widget.feed,
                  videoIndex: index,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (TapUpDetails details) =>
                  _controller.onTapUp(details, constraints.maxWidth),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: ListenableBuilder(
                listenable: Listenable.merge(<Listenable>[
                  widget.feed,
                  _controller,
                ]),
                builder: (BuildContext context, Widget? child) =>
                    StoryProgressBar(
                  count: widget.feed.videoCount,
                  current: _controller.current,
                  progress: _controller.progress,
                ),
              ),
            ),
          ],
        ),
      );
}
