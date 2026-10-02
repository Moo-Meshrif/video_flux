import 'package:flutter/material.dart';

import '../../data/enums/feed_style.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Height of the toggle row, which sits under the toolbar.
const double kFeedStyleToggleHeight = 52;

/// Switches between the feed styles the example shows.
///
/// Every style keeps its own content and configuration, so toggling away and
/// back returns to what was set.
class FeedStyleToggle extends StatelessWidget {
  /// Creates a toggle with [selected] highlighted.
  const FeedStyleToggle({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The style currently shown.
  final FeedStyle selected;

  /// Called with the style the user picked.
  final ValueChanged<FeedStyle> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: kFeedStyleToggleHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SegmentedButton<FeedStyle>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                  segments: <ButtonSegment<FeedStyle>>[
                    for (final FeedStyle style in FeedStyle.values)
                      ButtonSegment<FeedStyle>(
                        value: style,
                        icon: Icon(style.icon, size: 18),
                        label: Text(
                          style.shortTitle(context.l10n),
                          maxLines: 1,
                          softWrap: false,
                        ),
                        tooltip: style.summary(context.l10n),
                      ),
                  ],
                  selected: <FeedStyle>{selected},
                  onSelectionChanged: (Set<FeedStyle> selection) =>
                      onChanged(selection.single),
                ),
              ),
            ),
          ),
        ),
      );
}
