import 'package:flutter/material.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// Caption and position chip drawn over a full-screen video.
class VideoCaptionOverlay extends StatelessWidget {
  /// Creates an overlay describing video number [position] of [total].
  const VideoCaptionOverlay({
    required this.number,
    required this.videoTotal,
    required this.position,
    required this.total,
    super.key,
  });

  /// One-based number of the video, shown as its caption.
  final int number;

  /// Number of videos the feed holds in total.
  final int videoTotal;

  /// One-based position of the video.
  final int position;

  /// Number of videos loaded so far.
  final int total;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PositionedDirectional(
              start: 16,
              bottom: 24,
              end: 96,
              child: Text(
                context.l10n.clipCaption(number, videoTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  shadows: const <Shadow>[
                    Shadow(blurRadius: 6, color: Colors.black),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: 24,
              child: Chip(
                  label: Text(context.l10n.positionOfTotal(position, total))),
            ),
          ],
        ),
      );
}
