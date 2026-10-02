import 'package:flutter/material.dart';

/// Gives a debug tab an always-visible scrollbar when its content overflows.
///
/// Owns its own controller and hands it to the tab's vertical list through
/// [PrimaryScrollController], so a tab's lists need no controller of their
/// own. Key it per tab so each tab gets a fresh controller.
class ScrollableTabFrame extends StatefulWidget {
  /// Wraps [child] with a scrollbar.
  const ScrollableTabFrame({required this.child, super.key});

  /// The tab content, holding a primary vertical scrollable.
  final Widget child;

  @override
  State<ScrollableTabFrame> createState() => _ScrollableTabFrameState();
}

class _ScrollableTabFrameState extends State<ScrollableTabFrame> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController(
        controller: _controller,
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: widget.child,
        ),
      );
}
