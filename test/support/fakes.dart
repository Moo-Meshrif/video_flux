import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

VideoFluxConfig testConfig({
  int preloadBackward = 3,
  int preloadForward = 3,
  int windowSize = 8,
  int directionalPreloadBias = 0,
  int maxVelocityPreload = 0,
  double velocityPreloadThreshold = 1,
  int paginationThreshold = 5,
  bool handleAppLifecycle = true,
  int? maxConcurrentInitializations,
  Duration scrollDebounce = Duration.zero,
  int jumpThreshold = 5,
  RetryPolicy retryPolicy =
      const ExponentialBackoffRetryPolicy(initialDelay: Duration.zero),
  bool adaptive = false,
  DeviceTierProbe deviceTierProbe = const FixedDeviceTierProbe(DeviceTier.high),
  Duration pressureRecoveryDuration = const Duration(milliseconds: 20),
  Duration paginationRetryDelay = const Duration(milliseconds: 20),
  Duration? initializationTimeout,
}) =>
    VideoFluxConfig(
      preloadBackward: preloadBackward,
      preloadForward: preloadForward,
      windowSize: windowSize,
      directionalPreloadBias: directionalPreloadBias,
      maxVelocityPreload: maxVelocityPreload,
      velocityPreloadThreshold: velocityPreloadThreshold,
      paginationThreshold: paginationThreshold,
      handleAppLifecycle: handleAppLifecycle,
      maxConcurrentInitializations: maxConcurrentInitializations,
      scrollDebounce: scrollDebounce,
      jumpThreshold: jumpThreshold,
      retryPolicy: retryPolicy,
      adaptive: adaptive,
      deviceTierProbe: deviceTierProbe,
      pressureRecoveryDuration: pressureRecoveryDuration,
      paginationRetryDelay: paginationRetryDelay,
      initializationTimeout: initializationTimeout,
    );

Future<void> waitForControllersToInitialize(
  List<FakeVideoController> controllers,
  int expectedCount,
) async {
  while (controllers.length < expectedCount ||
      controllers
          .any((FakeVideoController controller) => !controller.initialized)) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> until(bool Function() condition) async {
  final Stopwatch stopwatch = Stopwatch()..start();
  while (!condition()) {
    if (stopwatch.elapsed > const Duration(seconds: 5)) {
      fail('Timed out waiting for a condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

/// Scrolls through [from]..[to] one item every few milliseconds, like a flick.
///
/// Spacing the calls matters: calls issued in the same tick are collapsed by
/// the selection generation alone and would not exercise the debounce.
Future<void> flick(VideoFlux preloader, int from, int to) async {
  final List<Future<void>> scrolls = <Future<void>>[];
  for (int index = from; index <= to; index++) {
    scrolls.add(preloader.scroll(index));
    await Future<void>.delayed(const Duration(milliseconds: 3));
  }
  await Future.wait(scrolls);
}

/// Lets queued initializations and microtasks run to completion.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

List<String> manySources(int count) => List<String>.generate(
      count,
      (int index) => 'https://example.com/$index.mp4',
    );

class RetryOnlyStateErrors extends RetryPolicy {
  @override
  Duration? nextDelay(int attempt, Object error, StackTrace stackTrace) =>
      error is StateError && attempt < 2 ? Duration.zero : null;
}

Future<void> waitForControllerStatus(
  VideoFlux preloader,
  VideoFluxStatus status,
) async {
  while (preloader.controllerStates.value.length != 1 ||
      preloader.controllerStates.value.single.status != status) {
    await Future<void>.delayed(Duration.zero);
  }
}

const List<String> defaultSources = <String>[
  'https://example.com/0.mp4',
  'https://example.com/1.mp4',
  'https://example.com/2.mp4',
  'https://example.com/3.mp4',
  'https://example.com/4.mp4',
];

List<TestVideo> testVideos(Iterable<String> sources) => sources
    .map((String source) => TestVideo(source, source))
    .toList(growable: false);

class TestVideo implements VideoFluxItem {
  const TestVideo(this.id, this.url);

  @override
  final String id;

  @override
  final String url;
}

class FakeVideoController extends CustomVideoController {
  FakeVideoController(
    this.dataSource, {
    this.onDispose,
    this.onInitialize,
    this.onWarmUp,
  });

  @override
  final String dataSource;

  bool initialized = false;
  bool disposed = false;
  int disposeCalls = 0;
  bool _isPlaying = false;
  final Future<void> Function()? onDispose;
  final Future<void> Function()? onInitialize;
  final Future<void> Function()? onWarmUp;

  @override
  Future<void> warmUp() async => onWarmUp?.call();

  @override
  bool get isInitialized => initialized;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await onDispose?.call();
    disposed = true;
    initialized = false;
    _isPlaying = false;
  }

  @override
  Future<void> initialize() async {
    await onInitialize?.call();
    initialized = true;
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
  }
}

class FailingVideoController extends FakeVideoController {
  FailingVideoController(super.dataSource);

  @override
  Future<void> initialize() => Future<void>.error(StateError('Unavailable'));
}
