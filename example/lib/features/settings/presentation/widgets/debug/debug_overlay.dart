import 'package:flutter/material.dart';

import '../../../../feed/presentation/controller/feed_controller.dart';
import '../../controller/debug_panel_controller.dart';
import 'controls_tab.dart';
import 'events_tab.dart';
import 'scrollable_tab_frame.dart';
import 'stats_tab.dart';
import 'window_tab.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// A panel over the bottom of the feed that shows what the preloader is doing.
///
/// The feed stays interactive above it, so scrolling and watching the panel
/// happen together.
class DebugOverlay extends StatefulWidget {
  /// Creates the panel for [feed].
  const DebugOverlay({
    required this.feed,
    required this.onClose,
    super.key,
  });

  /// The feed being inspected.
  final FeedController feed;

  /// Called when the user closes the panel.
  final VoidCallback onClose;

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final DebugPanelController _controller = DebugPanelController();

  @override
  void dispose() {
    _tabs.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _tab(int index) => ScrollableTabFrame(
        key: ValueKey<int>(index),
        child: switch (index) {
          0 => StatsTab(feed: widget.feed),
          1 => WindowTab(feed: widget.feed),
          2 => EventsTab(feed: widget.feed),
          _ => ControlsTab(feed: widget.feed),
        },
      );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: Material(
          color: const Color(0xFF101014),
          elevation: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TabBar(
                      controller: _tabs,
                      dividerColor: Colors.transparent,
                      tabs: <Tab>[
                        Tab(text: context.l10n.tabStats),
                        Tab(text: context.l10n.tabWindow),
                        Tab(text: context.l10n.tabEvents),
                        Tab(text: context.l10n.tabControls),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.closeDebugPanel,
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const Divider(height: 1),
              Flexible(
                child: ListenableBuilder(
                  listenable:
                      Listenable.merge(<Listenable>[_controller, _tabs]),
                  builder: (BuildContext context, Widget? child) =>
                      _tab(_tabs.index),
                ),
              ),
            ],
          ),
        ),
      );
}
