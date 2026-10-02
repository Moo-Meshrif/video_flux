import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('concurrent initializations', () {
    test('never runs more initializations than allowed', () async {
      int running = 0;
      int peak = 0;
      final List<FakeVideoController> controllers = <FakeVideoController>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(10)),
        controllerFactory: (String source) {
          final FakeVideoController controller = FakeVideoController(
            source,
            onInitialize: () async {
              running++;
              peak = running > peak ? running : peak;
              await Future<void>.delayed(const Duration(milliseconds: 5));
              running--;
            },
          );
          controllers.add(controller);
          return controller;
        },
        config: testConfig(
          preloadBackward: 0,
          preloadForward: 5,
          windowSize: 6,
          maxConcurrentInitializations: 2,
        ),
      );

      await waitForControllersToInitialize(controllers, 6);

      expect(peak, 2);

      await preloader.disposeAll();
    });

    test('starts the nearest item first', () async {
      final List<String> startOrder = <String>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(10)),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onInitialize: () async {
            startOrder.add(source);
            await Future<void>.delayed(const Duration(milliseconds: 5));
          },
        ),
        config: testConfig(
          preloadBackward: 0,
          preloadForward: 3,
          windowSize: 4,
          maxConcurrentInitializations: 1,
        ),
      );

      await until(() => startOrder.length == 4);

      expect(startOrder, manySources(10).sublist(0, 4));

      await preloader.disposeAll();
    });

    test('drops a queued initialization whose controller left the window',
        () async {
      final List<String> initialized = <String>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(30)),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onInitialize: () async {
            initialized.add(source);
            await Future<void>.delayed(const Duration(milliseconds: 10));
          },
        ),
        config: testConfig(
          preloadBackward: 0,
          preloadForward: 3,
          windowSize: 4,
          maxConcurrentInitializations: 1,
        ),
      );

      await preloader.scroll(20);
      await until(() => preloader.stats.queuedInitializations == 0);
      await settle();

      expect(preloader.stats.initializationsCancelled, greaterThan(0));
      expect(initialized, isNot(contains(manySources(30)[2])));

      await preloader.disposeAll();
    });

    test('a waiting retry does not hold a concurrency slot', () async {
      final List<String> initialized = <String>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(3)),
        controllerFactory: (String source) => source == manySources(3)[0]
            ? FailingVideoController(source)
            : FakeVideoController(
                source,
                onInitialize: () async => initialized.add(source),
              ),
        config: testConfig(
          preloadBackward: 0,
          preloadForward: 2,
          windowSize: 3,
          maxConcurrentInitializations: 1,
          retryPolicy: const FixedDelayRetryPolicy(
            maxRetries: 50,
            delay: Duration(seconds: 30),
          ),
        ),
      );

      await until(() => initialized.length == 2);

      expect(initialized, manySources(3).sublist(1));

      await preloader.disposeAll();
    });

    test('allows unlimited initializations when configured with null',
        () async {
      int running = 0;
      int peak = 0;
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(6)),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onInitialize: () async {
            running++;
            peak = running > peak ? running : peak;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            running--;
          },
        ),
        config:
            testConfig(windowSize: 6, preloadForward: 3, preloadBackward: 2),
      );

      await until(() => peak == 6);

      await preloader.disposeAll();
    });
  });
}
