import 'package:video_flux/video_flux.dart';

import '../enums/retry_choice.dart';
import '../enums/tier_choice.dart';

/// The editable form of a [VideoFluxConfig].
///
/// `maxConcurrentInitializations` is nullable in the config and uses `0` for
/// "no limit" here, because a stepper cannot hold null. Fields the form does not expose keep the value of [base].
class ConfigDraft {
  /// Creates a draft from [base].
  ConfigDraft.from(this.base)
      : preloadBackward = base.preloadBackward,
        preloadForward = base.preloadForward,
        windowSize = base.windowSize,
        directionalPreloadBias = base.directionalPreloadBias,
        maxVelocityPreload = base.maxVelocityPreload,
        concurrency = base.maxConcurrentInitializations ?? 0,
        debounceMs = base.scrollDebounce.inMilliseconds,
        jumpThreshold = base.jumpThreshold,
        paginationThreshold = base.paginationThreshold,
        adaptive = base.adaptive,
        tier = TierChoice.fromProbe(base.deviceTierProbe),
        retry = RetryChoice.fromPolicy(base.retryPolicy);

  /// The configuration this draft started from.
  final VideoFluxConfig base;

  /// See [VideoFluxConfig.preloadBackward].
  int preloadBackward;

  /// See [VideoFluxConfig.preloadForward].
  int preloadForward;

  /// See [VideoFluxConfig.windowSize].
  int windowSize;

  /// See [VideoFluxConfig.directionalPreloadBias].
  int directionalPreloadBias;

  /// See [VideoFluxConfig.maxVelocityPreload].
  int maxVelocityPreload;

  /// Simultaneous initializations; `0` means unlimited.
  int concurrency;

  /// Scroll debounce in milliseconds.
  int debounceMs;

  /// See [VideoFluxConfig.jumpThreshold].
  int jumpThreshold;

  /// See [VideoFluxConfig.paginationThreshold].
  int paginationThreshold;

  /// See [VideoFluxConfig.adaptive].
  bool adaptive;

  /// How the device tier is decided.
  TierChoice tier;

  /// How failed initializations are retried.
  RetryChoice retry;

  /// Builds the configuration this draft describes.
  VideoFluxConfig toConfig() => VideoFluxConfig(
        preloadBackward: preloadBackward,
        preloadForward: preloadForward,
        windowSize: windowSize,
        directionalPreloadBias: directionalPreloadBias,
        maxVelocityPreload: maxVelocityPreload,
        velocityPreloadThreshold: base.velocityPreloadThreshold,
        maxConcurrentInitializations: concurrency == 0 ? null : concurrency,
        scrollDebounce: Duration(milliseconds: debounceMs),
        jumpThreshold: jumpThreshold,
        paginationThreshold: paginationThreshold,
        paginationRetryDelay: base.paginationRetryDelay,
        autoplayFirstVideo: base.autoplayFirstVideo,
        handleAppLifecycle: base.handleAppLifecycle,
        retryPolicy: retry.policy,
        adaptive: adaptive,
        deviceTierProbe: tier.probe,
        pressureRecoveryDuration: base.pressureRecoveryDuration,
      );
}
