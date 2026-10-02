import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extensions.dart';

/// The shared chrome of an editor bottom sheet.
///
/// Wraps to its content's height, pins a [title] and a close button above the
/// content, and shows a scrollbar once the content outgrows the screen.
class EditorSheetFrame extends StatefulWidget {
  /// Creates a frame titled [title] around [children].
  const EditorSheetFrame({
    required this.title,
    required this.children,
    super.key,
  });

  /// The heading shown beside the close button.
  final String title;

  /// The scrollable content.
  final List<Widget> children;

  @override
  State<EditorSheetFrame> createState() => _EditorSheetFrameState();
}

class _EditorSheetFrameState extends State<EditorSheetFrame> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView(
                  controller: _scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: widget.children,
                ),
              ),
            ),
          ],
        ),
      );
}
