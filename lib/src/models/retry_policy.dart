import 'dart:math' as math;

/// Decides whether, and after how long, a failed initialization is retried.
abstract class RetryPolicy {
  /// Creates a retry policy.
  const RetryPolicy();

  /// Returns the delay before the next attempt, or null to give up.
  ///
  /// [attempt] is the one-based number of the attempt that just failed, so the
  /// first failure is reported as `1`.
  Duration? nextDelay(int attempt, Object error, StackTrace stackTrace);
}

/// Retries with a delay that grows by [multiplier] on every attempt.
class ExponentialBackoffRetryPolicy extends RetryPolicy {
  /// Creates a policy that retries up to [maxRetries] times.
  const ExponentialBackoffRetryPolicy({
    this.maxRetries = 1,
    this.initialDelay = const Duration(milliseconds: 500),
    this.multiplier = 2,
    this.maxDelay = const Duration(seconds: 30),
  })  : assert(maxRetries >= 0, 'maxRetries cannot be negative.'),
        assert(multiplier >= 1, 'multiplier must be at least 1.');

  /// How many times a failed initialization is retried.
  final int maxRetries;

  /// Delay before the first retry.
  final Duration initialDelay;

  /// Factor the delay grows by after each failed attempt.
  final double multiplier;

  /// Upper bound for any single delay.
  final Duration maxDelay;

  @override
  Duration? nextDelay(int attempt, Object error, StackTrace stackTrace) {
    if (attempt > maxRetries) {
      return null;
    }
    final double scaled = initialDelay.inMicroseconds.toDouble() *
        math.pow(multiplier, attempt - 1);
    final double capped = math.min(scaled, maxDelay.inMicroseconds.toDouble());
    return Duration(microseconds: capped.round());
  }
}

/// Retries with the same [delay] every time.
class FixedDelayRetryPolicy extends RetryPolicy {
  /// Creates a policy that retries up to [maxRetries] times.
  const FixedDelayRetryPolicy({
    this.maxRetries = 2,
    this.delay = const Duration(milliseconds: 500),
  }) : assert(maxRetries >= 0, 'maxRetries cannot be negative.');

  /// How many times a failed initialization is retried.
  final int maxRetries;

  /// Delay before every retry.
  final Duration delay;

  @override
  Duration? nextDelay(int attempt, Object error, StackTrace stackTrace) =>
      attempt > maxRetries ? null : delay;
}

/// Never retries; the first failure is final.
class NoRetryPolicy extends RetryPolicy {
  /// Creates a policy that fails immediately.
  const NoRetryPolicy();

  @override
  Duration? nextDelay(int attempt, Object error, StackTrace stackTrace) => null;
}
