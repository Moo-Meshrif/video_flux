import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_flux/video_flux.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/video_player_adapter.dart';
import '../controller/feed_controller.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Paints one video of a [FeedController]: the picture, its last frame while it
/// is not warm, or the failure with a retry button.
///
/// It never creates, disposes or starts anything: the controller belongs to the
/// preloader, and `scroll()` already plays the selected video.
///
/// While a video plays, and again as the user leaves it, the surface stores a
/// frame in the feed's poster cache. A video that has to initialize again shows
/// that frame, then fades to the live picture, instead of a blank box.
class VideoSurface extends StatefulWidget {
  /// Creates a surface for [videoIndex].
  const VideoSurface({
    required this.feed,
    required this.videoIndex,
    this.fit = BoxFit.cover,
    super.key,
  });

  /// The feed the video belongs to.
  final FeedController feed;

  /// Index among the feed's videos, not among its rows.
  final int videoIndex;

  /// How the picture fills the surface.
  final BoxFit fit;

  @override
  State<VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<VideoSurface> {
  static const Duration _captureDelay = Duration(milliseconds: 500);
  static const Duration _spinnerDelay = Duration(milliseconds: 300);
  static const Duration _fadeDuration = Duration(milliseconds: 200);
  static const double _posterPixelRatio = 0.75;

  final GlobalKey _pictureKey = GlobalKey();
  Timer? _captureTimer;
  bool _wasActive = false;
  bool _hasCapturedThisVisit = false;

  String get _url => widget.feed.videos[widget.videoIndex].url;

  String? get _thumbnailUrl =>
      widget.feed.videos[widget.videoIndex].thumbnailUrl;

  VideoPlayerControllerAdapter? get _adapter {
    final CustomVideoController? controller =
        widget.feed.controllerOf(widget.videoIndex);
    return controller is VideoPlayerControllerAdapter ? controller : null;
  }

  @override
  void initState() {
    super.initState();
    widget.feed.addListener(_onFeedChanged);
  }

  @override
  void didUpdateWidget(VideoSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed != widget.feed) {
      oldWidget.feed.removeListener(_onFeedChanged);
      widget.feed.addListener(_onFeedChanged);
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    widget.feed.removeListener(_onFeedChanged);
    super.dispose();
  }

  void _onFeedChanged() {
    final VideoPlayerControllerAdapter? adapter = _adapter;
    final bool isActive =
        widget.feed.activeVideo == widget.videoIndex && adapter != null;
    if (_wasActive && !isActive) {
      _captureTimer?.cancel();
      _captureOnce();
      _hasCapturedThisVisit = false;
    }
    _wasActive = isActive;
    if (isActive &&
        adapter.isInitialized &&
        adapter.isPlaying &&
        !_hasCapturedThisVisit &&
        !(_captureTimer?.isActive ?? false)) {
      _captureTimer = Timer(_captureDelay, _captureOnce);
    }
  }

  /// Stores the frame unless this visit already did, which skips a duplicate
  /// capture when the user leaves a video whose poster is fresh.
  Future<void> _captureOnce() async {
    if (_hasCapturedThisVisit) {
      return;
    }
    _hasCapturedThisVisit = true;
    final Object? boundary = _pictureKey.currentContext?.findRenderObject();
    final PosterCache? posters = widget.feed.posters;
    if (posters == null || boundary is! RenderRepaintBoundary) {
      return;
    }
    await posters.capture(_url, boundary, pixelRatio: _posterPixelRatio);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.feed,
        builder: (BuildContext context, Widget? child) {
          final VideoFluxState<dynamic>? state =
              widget.feed.stateOf(widget.videoIndex);
          if (state?.status == VideoFluxStatus.failed) {
            return _failure(context, state!);
          }
          final VideoPlayerControllerAdapter? adapter = _adapter;
          final bool isReady = adapter != null && adapter.isInitialized;
          return AnimatedSwitcher(
            duration: _fadeDuration,
            child: isReady
                ? KeyedSubtree(
                    key: const ValueKey<String>('picture'),
                    child: _picture(adapter),
                  )
                : KeyedSubtree(
                    key: const ValueKey<String>('poster'),
                    child: _poster(
                        isWaiting: state?.status != VideoFluxStatus.ready),
                  ),
          );
        },
      );

  Widget _picture(VideoPlayerControllerAdapter adapter) {
    final Size size = adapter.player.value.size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.feed.togglePlayback(adapter),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            key: _pictureKey,
            child: ColoredBox(
              color: Colors.black,
              child: FittedBox(
                fit: widget.fit,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: size.width <= 0 ? 16 : size.width,
                  height: size.height <= 0 ? 9 : size.height,
                  child: VideoPlayer(adapter.player),
                ),
              ),
            ),
          ),
          if (!adapter.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, size: 64, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  /// The last frame of this video, or black when none was captured, with a
  /// spinner that only appears if the wait is long enough to be noticed.
  Widget _poster({required bool isWaiting}) {
    final ui.Image? image = widget.feed.posters?.of(_url);
    final String? thumbnailUrl = _thumbnailUrl;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (image != null)
            RawImage(image: image, fit: widget.fit)
          else if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              fit: widget.fit,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          if (isWaiting)
            const Center(child: _DelayedSpinner(delay: _spinnerDelay)),
        ],
      ),
    );
  }

  Widget _failure(BuildContext context, VideoFluxState<dynamic> state) =>
      ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 12),
                Text(
                  context.l10n.couldNotLoadVideo('${state.error}'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () =>
                      widget.feed.preloader.retry(widget.videoIndex),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
}

/// A small spinner that appears only after [delay].
class _DelayedSpinner extends StatefulWidget {
  const _DelayedSpinner({required this.delay});

  final Duration delay;

  @override
  State<_DelayedSpinner> createState() => _DelayedSpinnerState();
}

class _DelayedSpinnerState extends State<_DelayedSpinner> {
  Timer? _timer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _isVisible
      ? const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white70,
          ),
        )
      : const SizedBox.shrink();
}
