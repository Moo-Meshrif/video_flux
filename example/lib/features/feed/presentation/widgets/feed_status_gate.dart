import 'package:flutter/material.dart';

import '../controller/feed_controller.dart';
import '../controller/feed_status.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Shows a spinner or an error until the feed is ready, then [child].
///
/// [child] is built once by the caller and handed through, so the running
/// feed is not rebuilt each time the controller notifies.
class FeedStatusGate extends StatelessWidget {
  /// Creates a gate on [feed]'s status.
  const FeedStatusGate({
    required this.feed,
    required this.onRetry,
    required this.child,
    super.key,
  });

  /// The feed whose first page is loading.
  final FeedController feed;

  /// Called when the user asks to try loading again.
  final VoidCallback onRetry;

  /// What to show once the feed is ready.
  final Widget child;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: feed,
        child: child,
        builder: (BuildContext context, Widget? ready) => switch (feed.status) {
          FeedStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          FeedStatus.failure => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(feed.errorMessage ?? context.l10n.couldNotLoadFeed),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onRetry,
                    child: Text(context.l10n.tryAgain),
                  ),
                ],
              ),
            ),
          FeedStatus.ready => ready!,
        },
      );
}
