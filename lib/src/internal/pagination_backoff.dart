import 'dart:math' as math;

/// Exponential delay between failed pagination attempts, capped at [maximum].
class PaginationBackoff {
  /// Creates a backoff that starts at [baseDelay].
  PaginationBackoff({
    required this.baseDelay,
    this.maximum = const Duration(seconds: 30),
  });

  /// The delay after the first failure; it doubles with each further one.
  final Duration baseDelay;

  /// The longest delay ever returned.
  final Duration maximum;

  int _failures = 0;

  /// Records a failure and returns how long to wait before trying again.
  Duration recordFailure() {
    _failures++;
    final int exponent = math.min(_failures - 1, 10);
    return Duration(
      microseconds: math.min(
        baseDelay.inMicroseconds * (1 << exponent),
        maximum.inMicroseconds,
      ),
    );
  }

  /// Forgets earlier failures after a page loads.
  void reset() => _failures = 0;
}
