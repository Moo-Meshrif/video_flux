import 'package:flutter/material.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// Height of [PostEngagement], which timeline rows budget for.
const double kPostEngagementHeight = 81;

/// Static reactions, comment and share counts with the action buttons
/// (Like, Comment, Share) under a timeline post.
///
/// The numbers are derived from [seed] so a post always shows the same ones;
/// nothing here is interactive state.
class PostEngagement extends StatelessWidget {
  /// Creates the engagement row for the post identified by [seed].
  const PostEngagement({required this.seed, super.key});

  /// The post's durable id.
  final String seed;

  int get _hash =>
      seed.codeUnits.fold(7, (int sum, int unit) => sum * 31 + unit);

  @override
  Widget build(BuildContext context) {
    final int reactions = 12 + _hash % 480;
    final int comments = 2 + _hash % 38;
    final int shares = _hash % 14;
    return SizedBox(
      height: kPostEngagementHeight,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const _ReactionIcon(
                    icon: Icons.thumb_up,
                    color: Colors.blue,
                  ),
                  const Align(
                    widthFactor: 0.6,
                    child: _ReactionIcon(
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$reactions'),
                  const Spacer(),
                  Text(
                    context.l10n.commentsAndShares(comments, shares),
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 44,
            child: Row(
              children: <Widget>[
                _Action(
                  icon: Icons.thumb_up_outlined,
                  label: context.l10n.like,
                ),
                _Action(
                  icon: Icons.mode_comment_outlined,
                  label: context.l10n.comment,
                ),
                _Action(
                  icon: Icons.share_outlined,
                  label: context.l10n.share,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 10,
        backgroundColor: color,
        child: Icon(icon, size: 12, color: Colors.white),
      );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: TextButton.icon(
          onPressed: () {},
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      );
}
