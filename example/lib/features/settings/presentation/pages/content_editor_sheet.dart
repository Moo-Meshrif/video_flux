import 'package:flutter/material.dart';

import '../../../feed/data/enums/feed_style.dart';
import '../../../feed/presentation/controller/feed_setup_controller.dart';
import '../controller/content_editor_controller.dart';
import '../widgets/editor_sheet_frame.dart';
import '../widgets/stepper_field.dart';
import '../../../../l10n/l10n_extensions.dart';

/// A sheet for putting your own videos (and text posts) into a feed style.
///
/// Saving restarts the feed with the new content. Lines that are not http(s)
/// URLs are reported and skipped rather than silently dropped.
class ContentEditorSheet extends StatefulWidget {
  /// Creates the sheet for [style].
  const ContentEditorSheet({
    required this.style,
    required this.setups,
    super.key,
  });

  /// The feed style whose content is edited.
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
            ContentEditorSheet(style: style, setups: setups),
      );

  @override
  State<ContentEditorSheet> createState() => _ContentEditorSheetState();
}

class _ContentEditorSheetState extends State<ContentEditorSheet> {
  late final ContentEditorController _controller = ContentEditorController(
    style: widget.style,
    setups: widget.setups,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    _controller.save();
    Navigator.of(context).pop();
  }

  String get _helperText {
    final int skipped = _controller.invalidCount;
    final int valid = _controller.validUrls.length;
    return skipped == 0
        ? context.l10n.playableSummary(valid)
        : context.l10n.playableSummarySkipped(valid, skipped);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) => EditorSheetFrame(
          title: context.l10n.contentTitle(widget.style.title(context.l10n)),
          children: <Widget>[
            Text(context.l10n.savingRestartsFeed),
            const SizedBox(height: 16),
            TextField(
              controller: _controller.urls,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: context.l10n.videoUrlsLabel,
                border: const OutlineInputBorder(),
                helperText: _helperText,
              ),
            ),
            Wrap(
              spacing: 8,
              children: <Widget>[
                TextButton.icon(
                  onPressed: _controller.addBrokenUrl,
                  icon: const Icon(Icons.link_off),
                  label: Text(context.l10n.addBrokenUrl),
                ),
                TextButton.icon(
                  onPressed: _controller.resetToSamples,
                  icon: const Icon(Icons.restore),
                  label: Text(context.l10n.resetToSamples),
                ),
              ],
            ),
            if (widget.style.includesTextPosts) ...<Widget>[
              const SizedBox(height: 8),
              TextField(
                controller: _controller.texts,
                minLines: 3,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: context.l10n.textPostsLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              StepperField(
                label: context.l10n.textPostBeforeEvery,
                hint: context.l10n.nthVideo,
                value: _controller.textEvery,
                min: 1,
                max: 5,
                onChanged: (int v) => _controller.textEvery = v,
              ),
            ],
            const SizedBox(height: 8),
            StepperField(
              label: context.l10n.videosPerPage,
              value: _controller.pageSize,
              min: 1,
              max: 10,
              onChanged: (int v) => _controller.pageSize = v,
            ),
            StepperField(
              label: context.l10n.repeatTheList,
              hint: context.l10n.repeatHint,
              value: _controller.loops,
              min: 1,
              max: 10,
              format: context.l10n.repeatCount,
              onChanged: (int v) => _controller.loops = v,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.feedHoldsTotal(_controller.totalVideos),
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: _controller.canSave ? _save : null,
                child: Text(context.l10n.save),
              ),
            ),
          ],
        ),
      );
}
