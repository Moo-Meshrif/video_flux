import 'package:flutter/material.dart';

/// Height of [PostCommentPreview], which timeline rows budget for.
const double kPostCommentPreviewHeight = 56;

/// One static comment shown under a post.
class PostCommentPreview extends StatelessWidget {
  /// Creates a preview of [text] written by [author].
  const PostCommentPreview({
    required this.author,
    required this.text,
    super.key,
  });

  /// Who wrote the comment.
  final String author;

  /// The comment itself.
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: kPostCommentPreviewHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: <Widget>[
              const CircleAvatar(
                  radius: 14, child: Icon(Icons.person, size: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: '$author  ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(text: text),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
