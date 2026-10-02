import '../enums/video_flux_direction.dart';

/// The half-open range `[start, end)` of item indexes the window should hold.
typedef WindowRange = ({int start, int end});

/// Decides which items the window should retain. Pure, so every edge case can
/// be tested without controllers, timers or a binding.
abstract final class WindowPlanner {
  /// Plans the window around [activeIndex].
  ///
  /// The window prefers [preloadBackward] items behind the active one, shifted
  /// toward [direction] by [directionalShift]. It is then clamped so it never
  /// exceeds [windowSize], always contains [activeIndex] and stays inside
  /// `[0, itemCount)`.
  static WindowRange plan({
    required int activeIndex,
    required VideoFluxDirection direction,
    required int directionalShift,
    required int itemCount,
    required int preloadBackward,
    required int windowSize,
  }) {
    final int start = _start(
      activeIndex: activeIndex,
      direction: direction,
      directionalShift: directionalShift,
      itemCount: itemCount,
      preloadBackward: preloadBackward,
      windowSize: windowSize,
    );
    final int end = start + windowSize;
    return (start: start, end: end < itemCount ? end : itemCount);
  }

  static int _start({
    required int activeIndex,
    required VideoFluxDirection direction,
    required int directionalShift,
    required int itemCount,
    required int preloadBackward,
    required int windowSize,
  }) {
    final int effectiveSize = itemCount < windowSize ? itemCount : windowSize;
    final int latestStart = itemCount - effectiveSize;
    int preferredStart = activeIndex - preloadBackward;
    if (direction == VideoFluxDirection.forward) {
      preferredStart += directionalShift;
    } else if (direction == VideoFluxDirection.backward) {
      preferredStart -= directionalShift;
    }
    final int minimumStart = activeIndex - windowSize + 1;
    final int boundedMinimumStart = minimumStart < 0 ? 0 : minimumStart;
    final int boundedMaximumStart =
        activeIndex < latestStart ? activeIndex : latestStart;
    if (preferredStart < boundedMinimumStart) {
      return boundedMinimumStart;
    }
    if (preferredStart > boundedMaximumStart) {
      return boundedMaximumStart;
    }
    return preferredStart;
  }
}
