import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/src/internal/pagination_backoff.dart';

void main() {
  test('doubles the delay with each failure', () {
    final PaginationBackoff backoff =
        PaginationBackoff(baseDelay: const Duration(seconds: 2));

    expect(backoff.recordFailure(), const Duration(seconds: 2));
    expect(backoff.recordFailure(), const Duration(seconds: 4));
    expect(backoff.recordFailure(), const Duration(seconds: 8));
  });

  test('caps the delay at the maximum', () {
    final PaginationBackoff backoff =
        PaginationBackoff(baseDelay: const Duration(seconds: 2));

    Duration last = Duration.zero;
    for (int i = 0; i < 40; i++) {
      last = backoff.recordFailure();
    }

    expect(last, const Duration(seconds: 30));
  });

  test('starts again from the base delay after a reset', () {
    final PaginationBackoff backoff =
        PaginationBackoff(baseDelay: const Duration(seconds: 2));
    backoff
      ..recordFailure()
      ..recordFailure()
      ..reset();

    expect(backoff.recordFailure(), const Duration(seconds: 2));
  });
}
