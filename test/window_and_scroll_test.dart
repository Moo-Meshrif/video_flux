import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('release before allocate', () {
    test('disposes outgoing controllers before creating incoming ones',
        () async {
      final List<String> log = <String>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(20)),
        controllerFactory: (String source) {
          log.add('create $source');
          return FakeVideoController(
            source,
            onDispose: () async => log.add('dispose $source'),
          );
        },
        config:
            testConfig(preloadBackward: 1, preloadForward: 1, windowSize: 3),
      );
      await preloader.scroll(10);
      await settle();
      log.clear();

      await preloader.scroll(9);

      final int lastDispose = log.lastIndexWhere(
        (String entry) => entry.startsWith('dispose'),
      );
      final int firstCreate = log.indexWhere(
        (String entry) => entry.startsWith('create'),
      );
      expect(lastDispose, lessThan(firstCreate));

      await preloader.disposeAll();
    });

    test('survives a jump past the whole window', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(200)),
        controllerFactory: FakeVideoController.new,
        config:
            testConfig(preloadBackward: 1, preloadForward: 1, windowSize: 3),
      );

      await preloader.scroll(150);

      expect(
        preloader
            .getActiveControllers()
            .map((CustomVideoController controller) => controller.dataSource),
        manySources(200).sublist(149, 152),
      );

      await preloader.disposeAll();
    });

    test('never holds more controllers than the window allows', () async {
      int peakRetained = 0;
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(100)),
        controllerFactory: FakeVideoController.new,
        config:
            testConfig(preloadBackward: 1, preloadForward: 1, windowSize: 3),
      );
      preloader.controllerStates.addListener(() {
        final int live = preloader.controllerStates.value
            .where(
              (VideoFluxState state) =>
                  state.status != VideoFluxStatus.disposed,
            )
            .length;
        peakRetained = live > peakRetained ? live : peakRetained;
      });

      for (final int index in <int>[5, 40, 6, 90, 2, 60]) {
        await preloader.scroll(index);
      }

      expect(peakRetained, lessThanOrEqualTo(3));

      await preloader.disposeAll();
    });
  });

  group('fast scroll debounce', () {
    test('a burst of small scrolls takes effect once', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(50)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          preloadBackward: 1,
          preloadForward: 1,
          windowSize: 3,
          scrollDebounce: const Duration(milliseconds: 40),
        ),
      );
      await preloader.scroll(10);
      final int scrollsBefore = preloader.stats.scrollCount;

      await flick(preloader, 11, 14);

      expect(preloader.stats.scrollCount - scrollsBefore, 1);
      expect(preloader.activeIndex, 14);

      await preloader.disposeAll();
    });

    test('a jump bypasses the debounce', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(50)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          scrollDebounce: const Duration(seconds: 30),
          jumpThreshold: 5,
        ),
      );
      await preloader.scroll(0);

      await preloader.scroll(20).timeout(const Duration(seconds: 2));

      expect(preloader.activeIndex, 20);

      await preloader.disposeAll();
    });

    test('measures a jump from the last requested index, not the committed one',
        () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(50)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          scrollDebounce: const Duration(milliseconds: 30),
          jumpThreshold: 5,
        ),
      );
      await preloader.scroll(0);
      final int scrollsBefore = preloader.stats.scrollCount;

      await flick(preloader, 1, 12);

      expect(preloader.stats.scrollCount - scrollsBefore, 1);

      await preloader.disposeAll();
    });

    test('rejects a negative debounce', () {
      expect(
        () => testConfig(scrollDebounce: const Duration(milliseconds: -1))
            .validate(),
        throwsArgumentError,
      );
    });
  });

  group('warm-up', () {
    test('runs once after initialization and before the controller is ready',
        () async {
      final List<String> log = <String>[];
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onInitialize: () async => log.add('initialize'),
          onWarmUp: () async => log.add('warmUp'),
        ),
        config: testConfig(),
        onControllerInitialized: (_) => log.add('ready'),
      );

      await waitForControllerStatus(preloader, VideoFluxStatus.ready);

      expect(log, <String>['initialize', 'warmUp', 'ready']);

      await preloader.disposeAll();
    });

    test('a failing warm-up does not fail the controller', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(<String>[defaultSources.first]),
        controllerFactory: (String source) => FakeVideoController(
          source,
          onWarmUp: () => Future<void>.error(StateError('seek failed')),
        ),
        config: testConfig(),
      );

      await waitForControllerStatus(preloader, VideoFluxStatus.ready);

      expect(preloader.stats.initializationsFailed, 0);

      await preloader.disposeAll();
    });
  });
}
