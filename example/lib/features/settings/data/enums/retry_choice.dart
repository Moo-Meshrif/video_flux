import 'package:video_flux/video_flux.dart';

/// How failed initializations are retried.
enum RetryChoice {
  /// One retry after 500 ms.
  exponential(ExponentialBackoffRetryPolicy()),

  /// Three retries, doubling the delay.
  exponentialThree(ExponentialBackoffRetryPolicy(maxRetries: 3)),

  /// Two retries, fixed delay.
  fixed(FixedDelayRetryPolicy()),

  /// Fail on the first error.
  none(NoRetryPolicy());

  const RetryChoice(this.policy);

  /// The policy this choice installs.
  final RetryPolicy policy;

  /// The choice that describes [policy].
  static RetryChoice fromPolicy(RetryPolicy policy) => switch (policy) {
        NoRetryPolicy() => none,
        FixedDelayRetryPolicy() => fixed,
        ExponentialBackoffRetryPolicy(:final maxRetries) when maxRetries > 1 =>
          exponentialThree,
        _ => exponential,
      };
}
