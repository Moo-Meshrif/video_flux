import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stats', () {
    test('counts scrolls and pool hits', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(20)),
        controllerFactory: FakeVideoController.new,
        config:
            testConfig(preloadBackward: 1, preloadForward: 2, windowSize: 4),
      );
      await settle();

      await preloader.scroll(1);
      await settle();
      await preloader.scroll(15);

      final VideoFluxStats stats = preloader.stats;
      expect(stats.scrollCount, 2);
      expect(stats.poolHitRate, 0.5);

      await preloader.disposeAll();
    });

    test('describes the retained controllers', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(10)),
        controllerFactory: FakeVideoController.new,
        config:
            testConfig(preloadBackward: 1, preloadForward: 1, windowSize: 3),
      );
      await preloader.scroll(3);
      await settle();

      final VideoFluxStats stats = preloader.stats;

      expect(stats.activeControllers, 3);
      expect(stats.readyControllers, 3);
      expect(stats.initializingControllers, 0);
      expect(stats.failedControllers, 0);
      expect(stats.controllersReleased, greaterThan(0));
      expect(stats.deviceTier, DeviceTier.high);
      expect(stats.memoryPressure, MemoryPressureLevel.none);

      await preloader.disposeAll();
    });

    test('counts failures and retries separately', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: FailingVideoController.new,
        config: testConfig(),
      );

      await waitForControllerStatus(preloader, VideoFluxStatus.failed);

      final VideoFluxStats stats = preloader.stats;
      expect(stats.initializationsFailed, 2);
      expect(stats.initializationsRetried, 1);
      expect(stats.failedControllers, 1);

      await preloader.disposeAll();
    });

    test('measures initialization durations', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(3)),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onInitialize: () =>
              Future<void>.delayed(const Duration(milliseconds: 15)),
        ),
        config:
            testConfig(preloadBackward: 0, preloadForward: 2, windowSize: 3),
      );

      await until(() => preloader.stats.initializationsSucceeded == 3);

      final VideoFluxStats stats = preloader.stats;
      expect(
        stats.averageInitializationDuration,
        greaterThanOrEqualTo(const Duration(milliseconds: 10)),
      );
      expect(
        stats.p95InitializationDuration,
        greaterThanOrEqualTo(stats.averageInitializationDuration),
      );

      await preloader.disposeAll();
    });

    test('reports zero durations before anything has loaded', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onInitialize: () => Completer<void>().future,
        ),
        config: testConfig(),
      );

      expect(preloader.stats.averageInitializationDuration, Duration.zero);
      expect(preloader.stats.p95InitializationDuration, Duration.zero);
      expect(preloader.stats.poolHitRate, 0);

      unawaited(preloader.disposeAll());
    });
  });

  group('events', () {
    test('streams what the preloader does, in order', () async {
      final List<VideoFluxEvent> events = <VideoFluxEvent>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
      );
      preloader.events.listen(events.add);

      await waitForControllerStatus(preloader, VideoFluxStatus.ready);
      await preloader.scroll(0);
      await preloader.disposeAll();

      expect(
        events.map((VideoFluxEvent event) => event.runtimeType),
        containsAllInOrder(<Type>[
          ControllerReady,
          ScrollSelected,
          ControllerReleased,
        ]),
      );
    });

    test('carries the failure and whether a retry follows', () async {
      final List<InitializationFailed> failures = <InitializationFailed>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: FailingVideoController.new,
        config: testConfig(),
      );
      preloader.events.listen((VideoFluxEvent event) {
        if (event is InitializationFailed) {
          failures.add(event);
        }
      });

      await waitForControllerStatus(preloader, VideoFluxStatus.failed);
      await settle();

      expect(
        failures.map((InitializationFailed failure) => failure.willRetry),
        <bool>[true, false],
      );
      expect(failures.last.error, isA<StateError>());

      await preloader.disposeAll();
    });

    test('announces pressure and limit changes', () async {
      final List<VideoFluxEvent> events = <VideoFluxEvent>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(20)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(adaptive: true),
      );
      preloader.events.listen(events.add);

      preloader.reportMemoryPressure(MemoryPressureLevel.critical);
      await settle();

      expect(
        events.whereType<PressureChanged>().single.level,
        MemoryPressureLevel.critical,
      );
      expect(events.whereType<LimitsChanged>().single.limits.windowSize, 1);

      await preloader.disposeAll();
    });

    test('announces pagination outcomes', () async {
      final List<VideoFluxEvent> events = <VideoFluxEvent>[];
      int page = 0;
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
        onPaginationNeeded: () async => page++ == 0
            ? <TestVideo>[const TestVideo('more', 'more.mp4')]
            : const <TestVideo>[],
      );
      preloader.events.listen(events.add);

      await preloader.scroll(0);
      await preloader.scroll(1);
      await settle();

      expect(events.whereType<PaginationCompleted>().single.itemCount, 1);
      expect(events.whereType<PaginationEnded>(), hasLength(1));

      await preloader.disposeAll();
    });

    test('keeps counting stats with nobody listening', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
      );

      await waitForControllerStatus(preloader, VideoFluxStatus.ready);

      expect(preloader.stats.initializationsSucceeded, 1);

      await preloader.disposeAll();
    });

    test('closes the stream on disposal', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
      );
      final Future<void> done = preloader.events.drain<void>();

      await preloader.disposeAll();

      await done.timeout(const Duration(seconds: 1));
    });
  });
}
