import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/src/enums/video_flux_direction.dart';
import 'package:video_flux/src/internal/window_planner.dart';

WindowRange _plan(
  int active, {
  VideoFluxDirection direction = VideoFluxDirection.idle,
  int shift = 0,
  int itemCount = 20,
  int backward = 1,
  int windowSize = 4,
}) =>
    WindowPlanner.plan(
      activeIndex: active,
      direction: direction,
      directionalShift: shift,
      itemCount: itemCount,
      preloadBackward: backward,
      windowSize: windowSize,
    );

void main() {
  test('keeps the preferred number of items behind the active one', () {
    expect(_plan(10), (start: 9, end: 13));
  });

  test('clamps to the start of the feed', () {
    expect(_plan(0), (start: 0, end: 4));
  });

  test('clamps to the end of the feed', () {
    expect(_plan(19), (start: 16, end: 20));
  });

  test('never exceeds the item count when the feed is shorter than the window',
      () {
    expect(_plan(1, itemCount: 3), (start: 0, end: 3));
  });

  test('shifts toward the scroll direction', () {
    expect(
      _plan(10, direction: VideoFluxDirection.forward, shift: 1),
      (start: 10, end: 14),
    );
    expect(
      _plan(10, direction: VideoFluxDirection.backward, shift: 1),
      (start: 8, end: 12),
    );
  });

  test('always contains the active index, however large the shift', () {
    for (final VideoFluxDirection direction in VideoFluxDirection.values) {
      for (int active = 0; active < 20; active++) {
        final WindowRange range = _plan(active, direction: direction, shift: 9);
        expect(range.start <= active && active < range.end, isTrue,
            reason: '$direction at $active gave $range');
        expect(range.end - range.start <= 4, isTrue);
      }
    }
  });
}
