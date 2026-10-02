import 'package:video_flux/video_flux.dart';
import 'package:video_player/video_player.dart';

import 'playback_memory.dart';

/// Adapts `video_player` to the controller contract used by the package.
///
/// This is the only file in the example that knows which player is used.
class VideoPlayerControllerAdapter extends CustomVideoController {
  /// Creates an adapter for [dataSource].
  ///
  /// With a [memory], playback resumes where the user left it and stays
  /// paused if they paused it.
  VideoPlayerControllerAdapter(this.dataSource, {PlaybackMemory? memory})
      : _memory = memory,
        player = VideoPlayerController.networkUrl(Uri.parse(dataSource));

  @override
  final String dataSource;

  /// The backend controller rendered by the example views.
  final VideoPlayerController player;

  final PlaybackMemory? _memory;

  @override
  bool get isInitialized => player.value.isInitialized;

  @override
  bool get isPlaying => player.value.isPlaying;

  @override
  Future<void> initialize() => player.initialize();

  @override
  Future<void> warmUp() async {
    await player.seekTo(_memory?.positionOf(dataSource) ?? Duration.zero);
    await player.pause();
  }

  @override
  Future<void> play() async {
    if (_memory?.isPausedByUser(dataSource) ?? false) {
      return;
    }
    await player.play();
  }

  @override
  Future<void> pause() async {
    _rememberPosition();
    await player.pause();
  }

  @override
  Future<void> dispose() {
    _rememberPosition();
    return player.dispose();
  }

  void _rememberPosition() {
    if (player.value.isInitialized) {
      _memory?.savePosition(
        dataSource,
        player.value.position,
        player.value.duration,
      );
    }
  }
}
