import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app_dependencies.dart';
import '../../../settings/presentation/widgets/debug/debug_overlay.dart';
import '../../../settings/presentation/pages/config_editor_sheet.dart';
import '../../../settings/presentation/pages/content_editor_sheet.dart';
import '../../data/models/feed_setup.dart';
import '../../data/enums/feed_layout.dart';
import '../../data/enums/feed_style.dart';
import '../controller/feed_controller.dart';
import '../controller/feed_setup_controller.dart';
import '../widgets/feed_settings_menu.dart';
import '../widgets/feed_status_gate.dart';
import '../widgets/feed_style_toggle.dart';
import '../widgets/stories/stories_view.dart';
import '../widgets/timeline/timeline_feed_view.dart';
import '../widgets/vertical/vertical_feed_view.dart';
import '../../../../l10n/l10n_extensions.dart';

/// The example's one screen: a feed with a toggle between its styles.
///
/// Switching style, or editing the current style's content or configuration,
/// restarts the feed: a new [FeedController] replaces the old one, which is
/// disposed after the frame so nothing still on screen touches a disposed
/// preloader.
class FeedPage extends StatefulWidget {
  /// Creates the page, starting on [initialStyle].
  const FeedPage({
    required this.dependencies,
    this.initialStyle = FeedStyle.facebook,
    this.onToggleLanguage,
    super.key,
  });

  /// Everything the feed needs, wired in one place.
  final AppDependencies dependencies;

  /// The style shown first.
  final FeedStyle initialStyle;

  /// Called when the user asks to switch between English and Arabic.
  final VoidCallback? onToggleLanguage;

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ValueNotifier<bool> _isDebugVisible = ValueNotifier<bool>(false);
  late FeedStyle _style = widget.initialStyle;
  late FeedController _feed = _createFeed();
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.dependencies.setups.addListener(_restart);
  }

  @override
  void dispose() {
    widget.dependencies.setups.removeListener(_restart);
    _isDebugVisible.dispose();
    _feed.dispose();
    super.dispose();
  }

  FeedController _createFeed() {
    final AppDependencies dependencies = widget.dependencies;
    final FeedSetup setup = dependencies.setups.setupOf(_style);
    final FeedController feed = FeedController(
      style: _style,
      setup: setup,
      repository: dependencies.feedRepositoryFor(_style, setup),
      controllerFactory: dependencies.controllerFactory,
      playbackMemory: dependencies.playbackMemory,
      posters: dependencies.posters,
    );
    unawaited(feed.load());
    return feed;
  }

  void _restart() {
    final FeedController previous = _feed;
    setState(() {
      _generation++;
      _feed = _createFeed();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  void _selectStyle(FeedStyle style) {
    if (style == _style) {
      return;
    }
    _style = style;
    _restart();
  }

  void _onMenuAction(FeedMenuAction action) {
    final FeedSetupController setups = widget.dependencies.setups;
    switch (action) {
      case FeedMenuAction.language:
        widget.onToggleLanguage?.call();
      case FeedMenuAction.editContent:
        ContentEditorSheet.show(context, style: _style, setups: setups);
      case FeedMenuAction.editConfiguration:
        ConfigEditorSheet.show(context, style: _style, setups: setups);
      case FeedMenuAction.reset:
        setups.reset(_style);
      case FeedMenuAction.debugPanel:
        _isDebugVisible.value = !_isDebugVisible.value;
    }
  }

  Widget _layout(FeedController feed) => switch (_style.layout) {
        FeedLayout.vertical => VerticalFeedView(feed: feed),
        FeedLayout.timeline => TimelineFeedView(feed: feed),
        FeedLayout.stories => StoriesView(feed: feed),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.appTitle),
          actions: <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: _isDebugVisible,
              builder: (BuildContext context, bool isVisible, Widget? child) =>
                  FeedSettingsMenu(
                style: _style,
                isDebugVisible: isVisible,
                onSelected: _onMenuAction,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kFeedStyleToggleHeight),
            child: FeedStyleToggle(selected: _style, onChanged: _selectStyle),
          ),
        ),
        body: KeyedSubtree(
          key: ValueKey<int>(_generation),
          child: FeedStatusGate(
            feed: _feed,
            onRetry: _restart,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _layout(_feed),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isDebugVisible,
                    builder: (BuildContext context, bool isVisible,
                            Widget? child) =>
                        isVisible
                            ? DebugOverlay(
                                key: ObjectKey(_feed),
                                feed: _feed,
                                onClose: () => _isDebugVisible.value = false,
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
