import 'package:flutter/material.dart';
import 'package:video_flux/video_flux.dart';

import '../../../../feed/presentation/controller/feed_controller.dart';
import 'debug_row.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// Buttons that provoke the situations the package is built to handle.
class ControlsTab extends StatelessWidget {
  /// Creates the tab for [feed].
  const ControlsTab({required this.feed, super.key});

  /// The feed being driven.
  final FeedController feed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int last = feed.videoCount - 1;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: <Widget>[
        DebugHeading(l10n.controlsMemoryPressure),
        SegmentedButton<MemoryPressureLevel>(
          showSelectedIcon: false,
          segments: <ButtonSegment<MemoryPressureLevel>>[
            for (final MemoryPressureLevel level in MemoryPressureLevel.values)
              ButtonSegment<MemoryPressureLevel>(
                value: level,
                label: Text(level.label(l10n)),
              ),
          ],
          selected: <MemoryPressureLevel>{feed.preloader.memoryPressure},
          onSelectionChanged: (Set<MemoryPressureLevel> selection) =>
              feed.reportPressure(selection.single),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.memoryPressureHint,
                style: const TextStyle(color: Colors.white54, fontSize: 12))),
        DebugHeading(l10n.controlsScrolling),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: () => feed.flick(forward: true),
              child: Text(l10n.flickForward),
            ),
            OutlinedButton(
              onPressed: () => feed.flick(forward: false),
              child: Text(l10n.flickBack),
            ),
            OutlinedButton(
              onPressed: () => feed.jumpTo(0),
              child: Text(l10n.jumpFirst),
            ),
            OutlinedButton(
              onPressed: () => feed.jumpTo(last ~/ 2),
              child: Text(l10n.jumpMiddle),
            ),
            OutlinedButton(
              onPressed: () => feed.jumpTo(last),
              child: Text(l10n.jumpLast),
            ),
          ],
        ),
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.flickHint,
                style: const TextStyle(color: Colors.white54, fontSize: 12))),
        DebugHeading(l10n.controlsFailures),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.failNextPage),
          subtitle: Text(l10n.failNextPageHint),
          value: feed.failNextPage,
          onChanged: (bool value) => feed.failNextPage = value,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: feed.retryFailed,
            child: Text(l10n.retryAllFailed),
          ),
        ),
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.failuresHint,
                style: const TextStyle(color: Colors.white54, fontSize: 12))),
        const SizedBox(height: 16),
      ],
    );
  }
}
