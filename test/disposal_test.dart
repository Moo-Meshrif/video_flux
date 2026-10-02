import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disposeAll finishes when an uninitialized controller never disposes',
      () async {
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) => FakeVideoController(
        source,
        onInitialize: () => Completer<void>().future,
        onDispose: () => Completer<void>().future,
      ),
      config: testConfig(preloadBackward: 0, preloadForward: 1, windowSize: 2),
    );

    await preloader.disposeAll().timeout(const Duration(seconds: 2));

    expect(preloader.getActiveControllers(), isEmpty);
  });

  test(
      'disposeAll releases every controller and closes its streams even '
      'when one backend dispose throws', () async {
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(
          source,
          onDispose: source == defaultSources.first
              ? () => Future<void>.error(StateError('native failure'))
              : null,
        );
        controllers.add(controller);
        return controller;
      },
      config: testConfig(preloadBackward: 0, preloadForward: 2, windowSize: 3),
    );
    await waitForControllersToInitialize(controllers, 3);
    final Completer<void> closed = Completer<void>();
    preloader.events.listen((_) {}, onDone: closed.complete);

    await preloader.disposeAll();

    expect(controllers.skip(1).every((c) => c.disposed), isTrue);
    await closed.future.timeout(const Duration(seconds: 2));
  });

  testWidgets('disposeAll cancels a retry that is still waiting',
      (WidgetTester tester) async {
    int created = 0;
    final VideoFlux preloader = VideoFlux(
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: (String source) {
        created++;
        return FailingVideoController(source);
      },
      config: testConfig(
        retryPolicy: const ExponentialBackoffRetryPolicy(
          initialDelay: Duration(hours: 1),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 10));

    await preloader.disposeAll();

    // testWidgets fails the test when a Timer is still pending here.
    expect(created, 1);
  });

  test('a disposed controller is never initialized from the queue', () async {
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final VideoFlux preloader = VideoFlux(
      items: testVideos(manySources(12)),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(source);
        controllers.add(controller);
        return controller;
      },
      config: testConfig(
        preloadBackward: 0,
        preloadForward: 2,
        windowSize: 3,
        maxConcurrentInitializations: 1,
      ),
    );

    await preloader.scroll(9);
    await settle();
    await preloader.disposeAll();

    final Iterable<FakeVideoController> neverUsed =
        controllers.where((c) => !c.initialized && c.disposeCalls > 0);
    for (final FakeVideoController controller in neverUsed) {
      expect(controller.disposeCalls, 1);
    }
  });
}
