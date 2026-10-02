import 'package:flutter/material.dart';

import '../../../data/models/feed_post.dart';
import 'post_engagement.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// A post with no video. The preloader never sees it.
class TextPostCard extends StatelessWidget {
  /// Creates a card for [post].
  const TextPostCard({required this.post, super.key});

  /// The post to show.
  final TextPost post;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const CircleAvatar(
                            radius: 16, child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.authorName(post.authorNumber),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Expanded so a larger system font clips the text instead of overflowing
                    // the fixed-height row.
                    Expanded(
                      child: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PostEngagement(seed: post.id),
          ],
        ),
      );
}
