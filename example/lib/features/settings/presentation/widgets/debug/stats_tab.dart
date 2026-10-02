import 'package:flutter/material.dart';
import 'package:video_flux/video_flux.dart';

import '../../../../feed/presentation/controller/feed_controller.dart';
import 'debug_row.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// Live counters from `VideoFlux.stats` and the limits it is enforcing.
class StatsTab extends StatelessWidget {
  /// Creates the tab for [feed].
  const StatsTab({required this.feed, super.key});

  /// The feed being inspected.
  final FeedController feed;

  static String _milliseconds(Duration duration) =>
      '${duration.inMilliseconds} ms';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final VideoFluxStats stats = feed.preloader.stats;
    final VideoFluxLimits limits = stats.effectiveLimits;
    final VideoFluxConfig config = feed.setup.config;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: <Widget>[
        DebugHeading(l10n.statsWindow),
        DebugRow(
          label: l10n.statRetainedWindow,
          value: '${stats.activeControllers} / ${limits.windowSize}',
        ),
        DebugRow(label: l10n.statReady, value: '${stats.readyControllers}'),
        DebugRow(
          label: l10n.statInitializing,
          value: '${stats.initializingControllers}',
        ),
        DebugRow(label: l10n.statFailed, value: '${stats.failedControllers}'),
        DebugRow(
          label: l10n.statQueued,
          value: '${stats.queuedInitializations}',
        ),
        DebugHeading(l10n.statsWork),
        DebugRow(
            label: l10n.statInitsStarted,
            value: '${stats.initializationsStarted}'),
        DebugRow(
            label: l10n.statSucceeded,
            value: '${stats.initializationsSucceeded}'),
        DebugRow(
            label: l10n.statFailedAttempts,
            value: '${stats.initializationsFailed}'),
        DebugRow(
            label: l10n.statRetried, value: '${stats.initializationsRetried}'),
        DebugRow(
          label: l10n.statDropped,
          value: '${stats.initializationsCancelled}',
        ),
        DebugRow(
            label: l10n.statReleased, value: '${stats.controllersReleased}'),
        DebugHeading(l10n.statsScrolling),
        DebugRow(label: l10n.statScrolls, value: '${stats.scrollCount}'),
        DebugRow(
          label: l10n.statPoolHit,
          value: '${(stats.poolHitRate * 100).round()}%',
        ),
        DebugRow(
          label: l10n.statAvgInit,
          value: _milliseconds(stats.averageInitializationDuration),
        ),
        DebugRow(
          label: l10n.statP95Init,
          value: _milliseconds(stats.p95InitializationDuration),
        ),
        DebugHeading(l10n.statsEnvironment),
        DebugRow(label: l10n.statDeviceTier, value: stats.deviceTier.name),
        DebugRow(
            label: l10n.statMemoryPressure, value: stats.memoryPressure.name),
        DebugRow(
          label: l10n.statPagination,
          value: stats.hasReachedEnd
              ? l10n.paginationReachedEnd
              : l10n.paginationMoreAvailable,
        ),
        DebugHeading(l10n.statsEnforced),
        DebugRow(
          label: l10n.statBehindAhead,
          value: l10n.withConfig(
              '${limits.preloadBackward} / ${limits.preloadForward}',
              '${config.preloadBackward} / ${config.preloadForward}'),
        ),
        DebugRow(
          label: l10n.statWindow,
          value:
              l10n.withConfig('${limits.windowSize}', '${config.windowSize}'),
        ),
        DebugRow(
          label: l10n.statConcurrentInits,
          value: l10n.withConfig(
              '${limits.maxConcurrentInitializations ?? l10n.unlimited}',
              '${config.maxConcurrentInitializations ?? l10n.unlimited}'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
