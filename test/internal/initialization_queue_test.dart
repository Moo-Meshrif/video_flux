import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/src/internal/initialization_queue.dart';

import '../support/fakes.dart';

PendingInitialization _job(int index) =>
    PendingInitialization(FakeVideoController('$index'), index, 1);

void main() {
  test('serves the job nearest the anchor first', () {
    final InitializationQueue queue = InitializationQueue()
      ..add(_job(9))
      ..add(_job(5))
      ..add(_job(6));

    expect(queue.takeNearest(5).index, 5);
    expect(queue.takeNearest(5).index, 6);
    expect(queue.takeNearest(5).index, 9);
    expect(queue.isEmpty, isTrue);
  });

  test('prefers the item ahead when two are equally near', () {
    final InitializationQueue queue = InitializationQueue()
      ..add(_job(4))
      ..add(_job(6));

    expect(queue.takeNearest(5).index, 6);
    expect(queue.takeNearest(5).index, 4);
  });

  test('clear drops everything waiting', () {
    final InitializationQueue queue = InitializationQueue()..add(_job(1));

    queue.clear();

    expect(queue.length, 0);
  });
}
