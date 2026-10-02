import 'package:flutter/material.dart';

/// Segmented progress bar across the top of a stories feed.
class StoryProgressBar extends StatelessWidget {
  /// Creates a bar of [count] segments with [current] in progress.
  const StoryProgressBar({
    required this.count,
    required this.current,
    required this.progress,
    super.key,
  });

  /// Number of stories.
  final int count;

  /// Index of the story being shown.
  final int current;

  /// Progress of the current story, from 0 to 1.
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: progress,
        builder: (BuildContext context, Widget? child) => Row(
          children: <Widget>[
            for (int index = 0; index < count; index++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: switch (index.compareTo(current)) {
                      < 0 => 1,
                      0 => progress.value,
                      _ => 0,
                    },
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      );
}
