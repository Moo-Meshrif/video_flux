import 'package:flutter/material.dart';

import '../../../data/models/feed_post.dart';
import '../../controller/feed_controller.dart';
import '../video_surface.dart';
import 'post_comment_preview.dart';
import 'post_engagement.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// A post carrying a video, drawn inside a timeline card.
class VideoPostCard extends StatelessWidget {
  /// Creates a card for [post], which is video number [videoIndex].
  const VideoPostCard({
    required this.feed,
    required this.post,
    required this.videoIndex,
    super.key,
  });

  /// The feed the post belongs to.
  final FeedController feed;

  /// The post to show.
  final VideoPost post;

  /// Index among the feed's videos, not among its rows.
  final int videoIndex;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: feed,
        builder: (BuildContext context, Widget? child) {
          final bool isActive = feed.activeVideo == videoIndex;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(child: Icon(Icons.videocam)),
                  title: Text(
                    context.l10n.clipCaption(
                      post.number,
                      feed.setup.content.totalVideos,
                    ),
                  ),
                  subtitle: Text(context.l10n.videoNumber(post.number)),
                ),
                Expanded(
                  child: VideoSurface(
                    feed: feed,
                    videoIndex: videoIndex,
                  ),
                ),
                PostEngagement(seed: post.id),
                PostCommentPreview(
                  author: context.l10n.sampleCommenter,
                  text: context.l10n.sampleComment,
                ),
              ],
            ),
          );
        },
      );
}
