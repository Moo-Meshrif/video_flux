import '../video_controller.dart';

/// An initialization waiting for a concurrency slot.
class PendingInitialization {
  /// Creates a pending initialization of [controller] for item [index].
  const PendingInitialization(this.controller, this.index, this.attempt);

  /// The controller to initialize.
  final CustomVideoController controller;

  /// The item index the controller serves.
  final int index;

  /// The 1-based attempt number.
  final int attempt;
}

/// Pending initializations, served nearest-to-the-active-item first.
class InitializationQueue {
  final List<PendingInitialization> _pending = <PendingInitialization>[];

  /// Whether nothing is waiting.
  bool get isEmpty => _pending.isEmpty;

  /// Whether something is waiting.
  bool get isNotEmpty => _pending.isNotEmpty;

  /// How many initializations are waiting.
  int get length => _pending.length;

  /// Queues [job].
  void add(PendingInitialization job) => _pending.add(job);

  /// Drops everything that is waiting.
  void clear() => _pending.clear();

  /// Removes and returns everything that is waiting, in queue order.
  List<PendingInitialization> drain() {
    final List<PendingInitialization> drained =
        List<PendingInitialization>.of(_pending);
    _pending.clear();
    return drained;
  }

  /// Removes and returns the job for item [index], or null when none waits.
  PendingInitialization? takeIndex(int index) {
    final int position =
        _pending.indexWhere((PendingInitialization job) => job.index == index);
    return position == -1 ? null : _pending.removeAt(position);
  }

  /// Removes and returns the job closest to [anchor].
  ///
  /// Ties go to the higher index, so the item ahead of a scroll wins over the
  /// one behind it.
  PendingInitialization takeNearest(int anchor) {
    int best = 0;
    for (int i = 1; i < _pending.length; i++) {
      if (_isCloser(_pending[i], _pending[best], anchor)) {
        best = i;
      }
    }
    return _pending.removeAt(best);
  }

  static bool _isCloser(
    PendingInitialization candidate,
    PendingInitialization current,
    int anchor,
  ) {
    final int byDistance = (candidate.index - anchor)
        .abs()
        .compareTo((current.index - anchor).abs());
    return byDistance != 0 ? byDistance < 0 : candidate.index > current.index;
  }
}
