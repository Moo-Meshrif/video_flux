import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps a bounded window when scrolling forward', () async {
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final Completer<void> initialized = Completer<void>();
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(source);
        controllers.add(controller);
        return controller;
      },
      config: testConfig(
        preloadBackward: 1,
        preloadForward: 1,
        windowSize: 3,
      ),
      onControllerInitialized: (_) {
        if (!initialized.isCompleted &&
            controllers.every((FakeVideoController item) => item.initialized)) {
          initialized.complete();
        }
      },
    );

    await initialized.future;
    await preloader.scroll(3);

    expect(
      preloader
          .getActiveControllers()
          .map((CustomVideoController controller) => controller.dataSource),
      <String>[defaultSources[2], defaultSources[3], defaultSources[4]],
    );
    expect(controllers[0].disposed, isTrue);
    expect(controllers[1].disposed, isTrue);
    expect(controllers[2].disposed, isFalse);

    await preloader.disposeAll();
  });

  test('biases the window toward scroll direction and velocity', () async {
    final List<String> sources = List<String>.generate(
      12,
      (int index) => 'https://example.com/$index.mp4',
    );
    final VideoFlux preloader = VideoFlux(
      items: testVideos(sources),
      controllerFactory: FakeVideoController.new,
      config: testConfig(
        preloadBackward: 2,
        preloadForward: 2,
        windowSize: 5,
        directionalPreloadBias: 1,
        maxVelocityPreload: 2,
        velocityPreloadThreshold: 1,
      ),
    );

    await preloader.scroll(4);
    await preloader.scroll(5, scrollVelocity: 1.2);

    expect(preloader.preloadDirection, VideoFluxDirection.forward);
    expect(
      preloader
          .getActiveControllers()
          .map((CustomVideoController controller) => controller.dataSource),
      sources.sublist(5, 10),
    );

    await preloader.scroll(4);

    expect(preloader.preloadDirection, VideoFluxDirection.backward);
    expect(
      preloader
          .getActiveControllers()
          .map((CustomVideoController controller) => controller.dataSource),
      sources.sublist(1, 6),
    );

    await preloader.disposeAll();
  });

  test('uses stable IDs and typed pagination items', () async {
    final List<TestVideo> initialItems = <TestVideo>[
      const TestVideo('first', 'https://example.com/first.mp4'),
      const TestVideo('second', 'https://example.com/second.mp4'),
    ];
    final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
      items: initialItems,
      controllerFactory: FakeVideoController.new,
      config: testConfig(
        paginationThreshold: 1,
      ),
      onPaginationNeeded: () async => <TestVideo>[
        const TestVideo('third', 'https://example.com/third.mp4'),
      ],
    );

    await preloader.scrollToId('first');

    expect(preloader.activeIndex, 0);
    expect(preloader.getItemById('second')?.id, 'second');
    expect(preloader.getItemAtIndex(2)?.id, 'third');
    expect(preloader.getControllerById('first'), isNotNull);
    expect(preloader.controllerStates.value.first.item.id, 'first');

    await preloader.disposeAll();
  });

  test('rejects duplicate stable item IDs', () {
    expect(
      () => VideoFlux<TestVideo>(
        config: testConfig(),
        items: const <TestVideo>[
          TestVideo('duplicate', 'first.mp4'),
          TestVideo('duplicate', 'second.mp4'),
        ],
        controllerFactory: FakeVideoController.new,
      ),
      throwsArgumentError,
    );
  });

  test('reports initialization errors from the selected backend', () async {
    final Completer<Object> error = Completer<Object>();
    final VideoFlux preloader = VideoFlux(
      config: testConfig(),
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: FailingVideoController.new,
      onControllerInitializationError: (
        CustomVideoController ignoredController,
        Object value,
        StackTrace ignoredStackTrace,
      ) {
        error.complete(value);
      },
    );

    expect(await error.future, isA<StateError>());

    await preloader.disposeAll();
  });

  test('publishes initializing then ready controller states', () async {
    final Completer<void> allowInitialization = Completer<void>();
    final FakeVideoController controller = FakeVideoController(
      defaultSources.first,
      onInitialize: () => allowInitialization.future,
    );
    final VideoFlux preloader = VideoFlux(
      config: testConfig(),
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: (_) => controller,
    );

    expect(
      preloader.controllerStates.value.single.status,
      VideoFluxStatus.initializing,
    );

    allowInitialization.complete();
    await waitForControllersToInitialize(<FakeVideoController>[controller], 1);

    final VideoFluxState state = preloader.controllerStates.value.single;
    expect(state.index, 0);
    expect(state.controller, same(controller));
    expect(state.status, VideoFluxStatus.ready);

    await preloader.disposeAll();
  });

  test('publishes the initialization failure with its error', () async {
    final VideoFlux preloader = VideoFlux(
      config: testConfig(),
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: FailingVideoController.new,
    );

    await waitForControllerStatus(preloader, VideoFluxStatus.failed);

    final VideoFluxState state = preloader.controllerStates.value.single;
    expect(state.status, VideoFluxStatus.failed);
    expect(state.error, isA<StateError>());
    expect(state.stackTrace, isNotNull);

    await preloader.disposeAll();
  });

  test('publishes disposed before evicted controller state is removed',
      () async {
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(source);
        controllers.add(controller);
        return controller;
      },
      config: testConfig(
        preloadBackward: 1,
        preloadForward: 1,
        windowSize: 3,
      ),
    );
    final List<VideoFluxState> emittedStates = <VideoFluxState>[];
    preloader.controllerStates.addListener(() {
      emittedStates.addAll(preloader.controllerStates.value);
    });

    await waitForControllersToInitialize(controllers, 3);
    await preloader.scroll(3);

    expect(
      emittedStates.any(
        (VideoFluxState state) =>
            state.index == 0 && state.status == VideoFluxStatus.disposed,
      ),
      isTrue,
    );
    expect(
      preloader.controllerStates.value
          .map((VideoFluxState state) => state.index),
      <int>[2, 3, 4],
    );

    await preloader.disposeAll();
  });

  test('retries initialization with a fresh controller after failure',
      () async {
    int factoryCalls = 0;
    final VideoFlux preloader = VideoFlux(
      config: testConfig(),
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: (String source) {
        factoryCalls++;
        return FakeVideoController(
          source,
          onInitialize: factoryCalls == 1
              ? () => Future<void>.error(StateError('Unavailable'))
              : null,
        );
      },
    );

    await waitForControllerStatus(preloader, VideoFluxStatus.ready);

    expect(factoryCalls, 2);
    expect(
      preloader.controllerStates.value.single.initializationAttempt,
      2,
    );

    await preloader.disposeAll();
  });

  test('retries a failed retained controller when requested manually',
      () async {
    bool shouldFail = true;
    int factoryCalls = 0;
    final VideoFlux preloader = VideoFlux(
      config: testConfig(),
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: (String source) {
        factoryCalls++;
        return FakeVideoController(
          source,
          onInitialize: shouldFail
              ? () => Future<void>.error(StateError('Unavailable'))
              : null,
        );
      },
    );

    await waitForControllerStatus(preloader, VideoFluxStatus.failed);
    shouldFail = false;
    await preloader.retry(0);
    await waitForControllerStatus(preloader, VideoFluxStatus.ready);

    expect(factoryCalls, 3);
    expect(
      preloader.controllerStates.value.single.initializationAttempt,
      1,
    );

    await preloader.disposeAll();
  });

  test('pauses and resumes the active controller with app lifecycle changes',
      () async {
    final FakeVideoController controller = FakeVideoController(
      defaultSources.first,
    );
    final VideoFlux preloader = VideoFlux(
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: (_) => controller,
      config: testConfig(
        handleAppLifecycle: true,
      ),
    );

    await waitForControllerStatus(preloader, VideoFluxStatus.ready);
    await preloader.scroll(0);
    expect(controller.isPlaying, isTrue);

    preloader.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isPlaying, isFalse);

    preloader.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(controller.isPlaying, isTrue);

    await preloader.disposeAll();
  });

  test('plays only the latest selection when scroll requests overlap',
      () async {
    final Completer<void> firstDisposalStarted = Completer<void>();
    final Completer<void> allowFirstDisposal = Completer<void>();
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(
          source,
          onDispose: source == defaultSources.first
              ? () async {
                  firstDisposalStarted.complete();
                  await allowFirstDisposal.future;
                }
              : null,
        );
        controllers.add(controller);
        return controller;
      },
      config: testConfig(
        preloadBackward: 0,
        preloadForward: 2,
        windowSize: 3,
      ),
    );

    await waitForControllersToInitialize(controllers, 3);

    final Future<void> firstScroll = preloader.scroll(3);
    await firstDisposalStarted.future;
    final Future<void> secondScroll = preloader.scroll(4);
    allowFirstDisposal.complete();
    await Future.wait(<Future<void>>[firstScroll, secondScroll]);

    expect(preloader.activeIndex, 4);
    expect(
      controllers
          .where((FakeVideoController controller) => controller.isPlaying)
          .map((FakeVideoController controller) => controller.dataSource),
      <String>[defaultSources[4]],
    );

    await preloader.disposeAll();
  });

  test('a stalled initialization does not block scrolling back', () async {
    final Completer<void> neverFinishes = Completer<void>();
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) {
        final bool stalls = source == defaultSources[3];
        final FakeVideoController controller = FakeVideoController(
          source,
          onInitialize: stalls ? () => neverFinishes.future : null,
          onDispose: stalls ? () => neverFinishes.future : null,
        );
        controllers.add(controller);
        return controller;
      },
      config: testConfig(
        preloadBackward: 0,
        preloadForward: 2,
        windowSize: 3,
      ),
    );
    await waitForControllersToInitialize(controllers, 2);

    await preloader.scroll(1);
    await preloader.scroll(0).timeout(const Duration(seconds: 2));

    expect(preloader.activeIndex, 0);

    await preloader.disposeAll().timeout(const Duration(seconds: 2));
  });

  test('a hung initialization times out and frees its slot', () async {
    final List<FakeVideoController> controllers = <FakeVideoController>[];
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(
          source,
          onInitialize: source == defaultSources.first
              ? () => Completer<void>().future
              : null,
        );
        controllers.add(controller);
        return controller;
      },
      config: testConfig(
        preloadBackward: 0,
        preloadForward: 1,
        windowSize: 2,
        maxConcurrentInitializations: 1,
        retryPolicy: const NoRetryPolicy(),
        initializationTimeout: const Duration(milliseconds: 50),
      ),
    );

    await until(
      () =>
          preloader.stats.failedControllers == 1 &&
          preloader.stats.readyControllers == 1,
    );

    await preloader.disposeAll().timeout(const Duration(seconds: 2));
  });

  test('disposes a controller once when initialization finishes after disposal',
      () async {
    final Completer<void> allowInitialization = Completer<void>();
    final FakeVideoController controller = FakeVideoController(
      defaultSources.first,
      onInitialize: () => allowInitialization.future,
    );
    final VideoFlux preloader = VideoFlux(
      config: testConfig(),
      items: testVideos(<String>[defaultSources.first]),
      controllerFactory: (_) => controller,
    );

    final Future<void> disposal = preloader.disposeAll();
    allowInitialization.complete();
    await disposal;
    await Future<void>.delayed(Duration.zero);

    expect(controller.disposeCalls, 1);
    expect(controller.isPlaying, isFalse);
  });
}
