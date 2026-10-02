/// Remembers where the user left each video and whether they paused it.
///
/// Lives only as long as the app process: nothing is written to disk, so a
/// restart starts every video afresh. Keyed by video URL, so a clip resumes
/// the same way in every feed style.
class PlaybackMemory {
  final Map<String, Duration> _positions = <String, Duration>{};
  final Set<String> _pausedByUser = <String>{};

  /// Where playback of [url] should resume; the start when never watched.
  Duration positionOf(String url) => _positions[url] ?? Duration.zero;

  /// Records that [url] was left at [position] of [duration].
  ///
  /// A video left within half a second of its end resumes from the start.
  void savePosition(String url, Duration position, Duration duration) {
    final bool isFinished = duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 500);
    _positions[url] = isFinished ? Duration.zero : position;
  }

  /// Whether the user chose to pause [url], so it should not start by itself.
  bool isPausedByUser(String url) => _pausedByUser.contains(url);

  /// Records the user's choice to pause ([paused] true) or resume [url].
  void setPausedByUser(String url, {required bool paused}) =>
      paused ? _pausedByUser.add(url) : _pausedByUser.remove(url);
}
