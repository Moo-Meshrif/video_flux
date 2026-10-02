import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('retry policies', () {
    const StackTrace trace = StackTrace.empty;

    test('exponential backoff doubles the delay and then gives up', () {
      const RetryPolicy policy = ExponentialBackoffRetryPolicy(
        maxRetries: 2,
        initialDelay: Duration(milliseconds: 100),
      );

      expect(
          policy.nextDelay(1, 'e', trace), const Duration(milliseconds: 100));
      expect(
          policy.nextDelay(2, 'e', trace), const Duration(milliseconds: 200));
      expect(policy.nextDelay(3, 'e', trace), isNull);
    });

    test('exponential backoff never exceeds its maximum delay', () {
      const RetryPolicy policy = ExponentialBackoffRetryPolicy(
        maxRetries: 10,
        initialDelay: Duration(seconds: 10),
        maxDelay: Duration(seconds: 15),
      );

      expect(policy.nextDelay(5, 'e', trace), const Duration(seconds: 15));
    });

    test('fixed delay repeats the same delay', () {
      const RetryPolicy policy =
          FixedDelayRetryPolicy(maxRetries: 2, delay: Duration(seconds: 1));

      expect(policy.nextDelay(1, 'e', trace), const Duration(seconds: 1));
      expect(policy.nextDelay(2, 'e', trace), const Duration(seconds: 1));
      expect(policy.nextDelay(3, 'e', trace), isNull);
    });

    test('no retry policy fails immediately', () {
      expect(const NoRetryPolicy().nextDelay(1, 'e', trace), isNull);
    });

    test('a custom policy can refuse permanent errors', () async {
      int factoryCalls = 0;
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: (String source) {
          factoryCalls++;
          return FailingVideoController(source);
        },
        config: testConfig(retryPolicy: RetryOnlyStateErrors()),
      );

      await waitForControllerStatus(preloader, VideoFluxStatus.failed);

      expect(factoryCalls, 2);

      await preloader.disposeAll();
    });

    test('no retry policy reports the first failure as final', () async {
      int factoryCalls = 0;
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: (String source) {
          factoryCalls++;
          return FailingVideoController(source);
        },
        config: testConfig(retryPolicy: const NoRetryPolicy()),
      );

      await waitForControllerStatus(preloader, VideoFluxStatus.failed);

      expect(factoryCalls, 1);

      await preloader.disposeAll();
    });
  });
}
