import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'support/controller_contract.dart';
import 'support/fakes.dart';

const Duration _fast = Duration(milliseconds: 200);

Future<ControllerContractViolation> _violation(
  _FakeFactory factory,
) async {
  try {
    await verifyControllerContract(factory, source: 'clip.mp4', timeout: _fast);
  } on ControllerContractViolation catch (violation) {
    return violation;
  }
  fail('Expected the contract to be violated.');
}

typedef _FakeFactory = FakeVideoController Function(String source);

/// Reports `isInitialized` before initialize() was ever called.
class _StartsInitialized extends FakeVideoController {
  _StartsInitialized(super.dataSource);

  @override
  bool get isInitialized => true;
}

/// Never reflects play().
class _IgnoresPlay extends FakeVideoController {
  _IgnoresPlay(super.dataSource);

  @override
  bool get isPlaying => false;
}

void main() {
  test('passes for a well-behaved adapter', () async {
    await verifyControllerContract(
      FakeVideoController.new,
      source: 'clip.mp4',
      timeout: _fast,
    );
  });

  test('passes when initialization is slow but dispose aborts it', () async {
    await verifyControllerContract(
      (String source) => FakeVideoController(
        source,
        onInitialize: () => Future<void>.delayed(
          const Duration(milliseconds: 50),
        ),
      ),
      source: 'clip.mp4',
      timeout: _fast,
    );
  });

  test('reports a factory that reuses one controller', () async {
    final FakeVideoController shared = FakeVideoController('clip.mp4');

    final ControllerContractViolation violation =
        await _violation((_) => shared);

    expect(
      violation.problems,
      contains(contains('same instance')),
    );
  });

  test('reports a controller that is initialized before initialize()',
      () async {
    final ControllerContractViolation violation =
        await _violation(_StartsInitialized.new);

    expect(
      violation.problems,
      contains(contains('before initialize() was called')),
    );
  });

  test('reports a play() that is not reflected in isPlaying', () async {
    final ControllerContractViolation violation =
        await _violation(_IgnoresPlay.new);

    expect(violation.problems, contains(contains('after play()')));
  });

  test('reports an initialize() that dispose() does not abort', () async {
    final ControllerContractViolation violation = await _violation(
      (String source) => FakeVideoController(
        source,
        onInitialize: () => Completer<void>().future,
      ),
    );

    expect(
      violation.problems,
      contains(contains('keeps a native decoder alive')),
    );
  });

  test('reports a dispose() that hangs, and keeps checking the rest', () async {
    final ControllerContractViolation violation = await _violation(
      (String source) => FakeVideoController(
        source,
        onDispose: () => Completer<void>().future,
      ),
    );

    expect(
      violation.problems,
      contains(contains('dispose() before initialize()')),
    );
    expect(violation.problems.length, greaterThan(1));
  });

  test('lists every problem in the exception message', () async {
    final ControllerContractViolation violation =
        await _violation(_StartsInitialized.new);

    expect(violation.toString(), contains('problem(s)'));
    expect(violation.toString(), contains('before initialize() was called'));
  });
}
