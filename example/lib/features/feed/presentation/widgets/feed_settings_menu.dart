import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../data/enums/feed_style.dart';

/// What the user can pick from the settings menu.
enum FeedMenuAction {
  /// Switch between English and Arabic.
  language,

  /// Open the content editor.
  editContent,

  /// Open the configuration editor.
  editConfiguration,

  /// Restore the current style's defaults.
  reset,

  /// Show or hide the debug panel.
  debugPanel,
}

/// One app bar button that opens every feed setting in a menu.
class FeedSettingsMenu extends StatelessWidget {
  /// Creates the menu for [style].
  const FeedSettingsMenu({
    required this.style,
    required this.isDebugVisible,
    required this.onSelected,
    super.key,
  });

  /// The style shown, named in the reset item.
  final FeedStyle style;

  /// Whether the debug panel is open, shown as a check on its item.
  final bool isDebugVisible;

  /// Called with the item the user picked.
  final ValueChanged<FeedMenuAction> onSelected;

  PopupMenuItem<FeedMenuAction> _item(
    FeedMenuAction action,
    IconData icon,
    String label, {
    bool isChecked = false,
  }) =>
      PopupMenuItem<FeedMenuAction>(
        value: action,
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            if (isChecked) const Icon(Icons.check, size: 20),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => PopupMenuButton<FeedMenuAction>(
        tooltip: context.l10n.settings,
        icon: const Icon(Icons.settings),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<FeedMenuAction>>[
          _item(
            FeedMenuAction.language,
            Icons.translate,
            context.l10n.switchLanguage,
          ),
          _item(
            FeedMenuAction.editContent,
            Icons.edit_note,
            context.l10n.editContent,
          ),
          _item(
            FeedMenuAction.editConfiguration,
            Icons.tune,
            context.l10n.editConfiguration,
          ),
          _item(
            FeedMenuAction.reset,
            Icons.restore,
            context.l10n.resetStyle(style.title(context.l10n)),
          ),
          _item(
            FeedMenuAction.debugPanel,
            Icons.bug_report_outlined,
            context.l10n.debugPanel,
            isChecked: isDebugVisible,
          ),
        ],
      );
}
