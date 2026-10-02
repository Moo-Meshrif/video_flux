import 'dart:async';

import 'package:video_flux/video_flux.dart';

/// Thrown by [verifyControllerContract] when an adapter breaks the contract
/// `VideoFlux` relies on.
class ControllerContractViolation implements Exception {
  /// Creates a violation listing every [problems] found.
  const ControllerContractViolation(this.problems);

  /// One human-readable line per broken rule.
  final List<String> problems;

  @override
  String toString() => 'ControllerContractViolation: '
      '${problems.length} problem(s) in the adapter\n'
      '${problems.map((String problem) => '  - $problem').join('\n')}';
}

/// Checks that the controllers made by [createController] behave the way
/// `VideoFlux` assumes, and throws [ControllerContractViolation] listing every
/// rule they break.
///
/// Run it against your real backend, with a [source] it can open (a small
/// asset or local file keeps it fast and offline):
///
/// ```dart
/// test('VideoPlayerAdapter honours the VideoFlux contract', () {
///   return verifyControllerContract(
///     VideoPlayerAdapter.new,
///     source: 'assets/clip.mp4',
///   );
/// });
/// ```
///
/// Use a plain `test`, not `testWidgets`: it needs real time to wait on the
/// backend. It checks that:
///
/// * every call returns a new, uninitialized, idle controller for [source];
/// * `initialize`, `warmUp`, `play`, `pause` and `togglePlayPause` are
///   reflected in `isInitialized` and `isPlaying`;
/// * a controller that never initialized can be disposed;
/// * `dispose` called while `initialize` is pending completes, and the pending
///   `initialize` then settles instead of staying open. This is how the
///   preloader stops an evicted or timed-out initialization, and a backend that
///   ignores it leaks a native decoder.
///
/// Each wait is bounded by [timeout]. Real network sources need a larger one.
Future<void> verifyControllerContract(
  VideoControllerFactory createController, {
  required String source,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final List<String> problems = <String>[];
  final _Checker check = _Checker(problems, timeout);

  await check.run('a new controller is fresh', () async {
    final CustomVideoController first = createController(source);
    final CustomVideoController second = createController(source);
    try {
      check.expect(
        !identical(first, second),
        'the factory returned the same instance twice; it must create a new '
        'controller on every call',
      );
      check.expect(
        first.dataSource == source,
        'dataSource is "${first.dataSource}", expected "$source"',
      );
      check.expect(
        !first.isInitialized,
        'isInitialized is true before initialize() was called',
      );
      check.expect(
        !first.isPlaying,
        'isPlaying is true before play() was called',
      );
    } finally {
      await check.disposeQuietly(first);
      await check.disposeQuietly(second);
    }
  });

  await check.run('an uninitialized controller can be disposed', () async {
    final CustomVideoController controller = createController(source);
    await check.within(controller.dispose(), 'dispose() before initialize()');
  });

  await check.run('the normal lifecycle is reflected in its state', () async {
    final CustomVideoController controller = createController(source);
    try {
      await check.within(controller.initialize(), 'initialize()');
      check.expect(
        controller.isInitialized,
        'isInitialized is false after initialize() completed',
      );
      await check.within(controller.warmUp(), 'warmUp()');
      check.expect(
        controller.isInitialized,
        'warmUp() left the controller uninitialized',
      );

      await check.within(controller.play(), 'play()');
      check.expect(controller.isPlaying, 'isPlaying is false after play()');
      await check.within(controller.pause(), 'pause()');
      check.expect(!controller.isPlaying, 'isPlaying is true after pause()');

      await check.within(controller.togglePlayPause(), 'togglePlayPause()');
      check.expect(controller.isPlaying, 'togglePlayPause() did not start');
      await check.within(controller.togglePlayPause(), 'togglePlayPause()');
      check.expect(!controller.isPlaying, 'togglePlayPause() did not stop');

      await check.within(controller.pause(), 'pause()');
    } finally {
      await check.disposeQuietly(controller);
    }
  });

  await check.run('dispose() aborts a pending initialize()', () async {
    final CustomVideoController controller = createController(source);
    final Completer<void> settled = Completer<void>();
    // An abandoned initialization is allowed to fail; it must only finish.
    unawaited(
      controller.initialize().then<void>(
            (_) => settled.complete(),
            onError: (Object _) => settled.complete(),
          ),
    );
    await Future<void>.delayed(Duration.zero);

    await check.within(
      controller.dispose(),
      'dispose() while initialize() is pending',
    );
    await check.within(
      settled.future,
      'initialize() to settle after dispose(); a pending initialization that '
      'dispose() does not abort keeps a native decoder alive',
    );
  });

  if (problems.isNotEmpty) {
    throw ControllerContractViolation(problems);
  }
}

class _Checker {
  _Checker(this._problems, this._timeout);

  final List<String> _problems;
  final Duration _timeout;

  void expect(bool condition, String problem) {
    if (!condition) {
      _problems.add(problem);
    }
  }

  /// Runs [body], recording a throw as a problem so later checks still run.
  Future<void> run(String name, Future<void> Function() body) async {
    try {
      await body();
    } on _Timeout catch (timeout) {
      _problems.add('$name: ${timeout.message}');
    } catch (error) {
      _problems.add('$name: threw $error');
    }
  }

  Future<void> within(Future<void> work, String what) =>
      work.timeout(_timeout, onTimeout: () => throw _Timeout(what, _timeout));

  Future<void> disposeQuietly(CustomVideoController controller) async {
    try {
      await controller.dispose().timeout(_timeout);
    } catch (_) {
      // Already reported by the check that owned the controller.
    }
  }
}

class _Timeout implements Exception {
  _Timeout(String what, Duration timeout)
      : message = 'timed out after ${timeout.inMilliseconds} ms waiting for '
            '$what';

  final String message;
}
