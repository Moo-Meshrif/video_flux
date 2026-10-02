import 'package:flutter/material.dart';

import '../../../feed/data/enums/feed_style.dart';
import '../../../feed/presentation/controller/feed_setup_controller.dart';
import '../../data/enums/retry_choice.dart';
import '../../data/enums/tier_choice.dart';
import '../controller/config_editor_controller.dart';
import '../widgets/editor_sheet_frame.dart';
import '../widgets/stepper_field.dart';
import '../../../../l10n/l10n_extensions.dart';

/// A sheet for tuning every `VideoFluxConfig` field a feed style exposes.
///
/// Applying restarts the feed, because a preloader's configuration is fixed
/// when it is created. Invalid combinations are caught by the package's own
/// validation and shown instead of applied.
class ConfigEditorSheet extends StatefulWidget {
  /// Creates the sheet for [style].
  const ConfigEditorSheet({
    required this.style,
    required this.setups,
    super.key,
  });

  /// The feed style being configured.
  final FeedStyle style;

  /// Where the feed style's setup lives.
  final FeedSetupController setups;

  /// Shows the sheet over [context].
  static Future<void> show(
    BuildContext context, {
    required FeedStyle style,
    required FeedSetupController setups,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (BuildContext context) =>
            ConfigEditorSheet(style: style, setups: setups),
      );

  @override
  State<ConfigEditorSheet> createState() => _ConfigEditorSheetState();
}

class _ConfigEditorSheetState extends State<ConfigEditorSheet> {
  late final ConfigEditorController _controller = ConfigEditorController(
    style: widget.style,
    setups: widget.setups,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    if (_controller.apply()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) => EditorSheetFrame(
          title: context.l10n.configTitle(widget.style.title(context.l10n)),
          children: <Widget>[
            Text(context.l10n.applyingRestartsFeed),
            _Section(context.l10n.sectionWindow),
            StepperField(
              label: context.l10n.fieldBehind,
              value: _controller.draft.preloadBackward,
              min: 0,
              max: 6,
              onChanged: (int v) =>
                  _controller.edit(() => _controller.draft.preloadBackward = v),
            ),
            StepperField(
              label: context.l10n.fieldAhead,
              value: _controller.draft.preloadForward,
              min: 0,
              max: 6,
              onChanged: (int v) =>
                  _controller.edit(() => _controller.draft.preloadForward = v),
            ),
            StepperField(
              label: context.l10n.fieldWindowSize,
              hint: context.l10n.fieldWindowSizeHint,
              value: _controller.draft.windowSize,
              min: 1,
              max: 14,
              onChanged: (int v) =>
                  _controller.edit(() => _controller.draft.windowSize = v),
            ),
            StepperField(
              label: context.l10n.fieldDirectionBias,
              hint: context.l10n.fieldDirectionBiasHint,
              value: _controller.draft.directionalPreloadBias,
              min: 0,
              max: 3,
              onChanged: (int v) => _controller
                  .edit(() => _controller.draft.directionalPreloadBias = v),
            ),
            StepperField(
              label: context.l10n.fieldVelocityPreload,
              hint: context.l10n.fieldVelocityPreloadHint,
              value: _controller.draft.maxVelocityPreload,
              min: 0,
              max: 4,
              onChanged: (int v) => _controller
                  .edit(() => _controller.draft.maxVelocityPreload = v),
            ),
            _Section(context.l10n.sectionFastScrolling),
            StepperField(
              label: context.l10n.fieldConcurrentInits,
              value: _controller.draft.concurrency,
              min: 0,
              max: 6,
              format: (int v) => v == 0 ? context.l10n.unlimited : '$v',
              onChanged: (int v) =>
                  _controller.edit(() => _controller.draft.concurrency = v),
            ),
            StepperField(
              label: context.l10n.fieldScrollDebounce,
              value: _controller.draft.debounceMs,
              min: 0,
              max: 600,
              step: 30,
              format: context.l10n.millisecondsValue,
              onChanged: (int v) =>
                  _controller.edit(() => _controller.draft.debounceMs = v),
            ),
            StepperField(
              label: context.l10n.fieldJumpThreshold,
              hint: context.l10n.fieldJumpThresholdHint,
              value: _controller.draft.jumpThreshold,
              min: 1,
              max: 20,
              onChanged: (int v) =>
                  _controller.edit(() => _controller.draft.jumpThreshold = v),
            ),
            _Section(context.l10n.sectionPagination),
            StepperField(
              label: context.l10n.fieldPaginationThreshold,
              hint: context.l10n.fieldPaginationThresholdHint,
              value: _controller.draft.paginationThreshold,
              min: 0,
              max: 12,
              onChanged: (int v) => _controller
                  .edit(() => _controller.draft.paginationThreshold = v),
            ),
            _Section(context.l10n.sectionMemory),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(context.l10n.fieldAdaptive),
              subtitle: Text(context.l10n.fieldAdaptiveHint),
              value: _controller.draft.adaptive,
              onChanged: (bool v) =>
                  _controller.edit(() => _controller.draft.adaptive = v),
            ),
            DropdownButtonFormField<TierChoice>(
              value: _controller.draft.tier,
              decoration:
                  InputDecoration(labelText: context.l10n.fieldDeviceTier),
              items: <DropdownMenuItem<TierChoice>>[
                for (final TierChoice choice in TierChoice.values)
                  DropdownMenuItem<TierChoice>(
                    value: choice,
                    child: Text(choice.label(context.l10n)),
                  ),
              ],
              onChanged: (TierChoice? v) => _controller.edit(
                  () => _controller.draft.tier = v ?? _controller.draft.tier),
            ),
            _Section(context.l10n.sectionFailures),
            DropdownButtonFormField<RetryChoice>(
              value: _controller.draft.retry,
              decoration:
                  InputDecoration(labelText: context.l10n.fieldRetryPolicy),
              items: <DropdownMenuItem<RetryChoice>>[
                for (final RetryChoice choice in RetryChoice.values)
                  DropdownMenuItem<RetryChoice>(
                    value: choice,
                    child: Text(choice.label(context.l10n)),
                  ),
              ],
              onChanged: (RetryChoice? v) => _controller.edit(
                  () => _controller.draft.retry = v ?? _controller.draft.retry),
            ),
            if (_controller.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: _controller.resetToPreset,
                  child: Text(context.l10n.resetToPreset),
                ),
                const Spacer(),
                FilledButton(
                    onPressed: _apply, child: Text(context.l10n.apply)),
              ],
            ),
          ],
        ),
      );
}

/// A small heading above a group of fields.
class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
