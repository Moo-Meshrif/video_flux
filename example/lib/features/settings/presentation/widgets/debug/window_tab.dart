import 'package:flutter/material.dart';
import 'package:video_flux/video_flux.dart';

import '../../../../feed/presentation/controller/feed_controller.dart';
import 'debug_row.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// A map of every loaded video, coloured by what the preloader holds for it.
class WindowTab extends StatelessWidget {
  /// Creates the tab for [feed].
  const WindowTab({required this.feed, super.key});

  /// The feed being inspected.
  final FeedController feed;

  @override
  Widget build(BuildContext context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _Legend(color: Colors.grey, label: context.l10n.legendNotLoaded),
              _Legend(
                  color: Colors.amber, label: context.l10n.legendInitializing),
              _Legend(color: Colors.green, label: context.l10n.legendReady),
              _Legend(color: Colors.red, label: context.l10n.legendFailed),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (int video = 0; video < feed.videoCount; video++)
                _Cell(
                  video: video,
                  status: feed.stateOf(video)?.status,
                  isActive: video == feed.activeVideo,
                  onTap: () => feed.jumpTo(video),
                ),
            ],
          ),
          DebugHeading(context.l10n.statsWindow),
          DebugRow(
              label: context.l10n.firstRetainedIndex,
              value: '${feed.preloader.windowStart}'),
          DebugRow(
              label: context.l10n.activeIndex, value: '${feed.activeVideo}'),
          DebugRow(
            label: context.l10n.direction,
            value: feed.preloader.preloadDirection.name,
          ),
          DebugRow(
              label: context.l10n.videosLoaded, value: '${feed.videoCount}'),
          DebugRow(
              label: context.l10n.rowsLoaded, value: '${feed.rows.length}'),
          const SizedBox(height: 8),
          Text(
            context.l10n.tapCellToJump,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      );
}

/// One video in the window map.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.video,
    required this.status,
    required this.isActive,
    required this.onTap,
  });

  final int video;
  final VideoFluxStatus? status;
  final bool isActive;
  final VoidCallback onTap;

  Color get _color => switch (status) {
        null || VideoFluxStatus.disposed => Colors.grey.shade800,
        VideoFluxStatus.initializing => Colors.amber.shade700,
        VideoFluxStatus.ready => Colors.green.shade600,
        VideoFluxStatus.failed => Colors.red.shade600,
      };

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(6),
            border: isActive ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: Text('$video', style: const TextStyle(fontSize: 11)),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
