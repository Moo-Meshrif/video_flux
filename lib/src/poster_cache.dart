import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Optional helper that keeps a recent frame of each video, so one that has to
/// initialize again can show its last picture instead of a blank box.
///
/// `VideoFlux` never uses it: decoding and painting belong to your player, so
/// you decide when to capture and how to draw the poster. The cache only holds
/// the images, bounded by both [maxEntries] and [maxBytes]. The least recently
/// used frame is released first, so memory never grows with the feed, however
/// large each frame is. Key it by anything stable, such as a URL or an item id.
class PosterCache {
  /// Creates a cache holding at most [maxEntries] frames and about [maxBytes]
  /// of decoded pixels.
  PosterCache({this.maxEntries = 24, this.maxBytes = 32 * 1024 * 1024})
      : assert(maxEntries > 0),
        assert(maxBytes > 0);

  /// How many frames are kept before the least recently used is released.
  final int maxEntries;

  /// The decoded size, in bytes, kept before the least recently used frame is
  /// released.
  ///
  /// A frame is `width * height * 4` bytes, so a few full-resolution posters
  /// can outweigh [maxEntries] small ones. The newest frame is always kept,
  /// even when it alone exceeds this budget.
  final int maxBytes;

  /// The decoded size of the frames currently held.
  int get currentBytes => _currentBytes;

  int _currentBytes = 0;
  bool _isDisposed = false;

  final LinkedHashMap<String, ui.Image> _images =
      LinkedHashMap<String, ui.Image>();

  /// The stored frame for [key], or null when none was captured.
  ///
  /// The cache owns the image: draw it, but do not dispose it.
  ui.Image? of(String key) {
    final ui.Image? image = _images.remove(key);
    if (image != null) {
      _images[key] = image;
    }
    return image;
  }

  /// Stores [image] as the poster of [key], taking ownership of it.
  ///
  /// After [dispose], the image is released at once instead of stored: a
  /// capture that finishes after the cache is gone must not leak its frame.
  void put(String key, ui.Image image) {
    if (_isDisposed) {
      image.dispose();
      return;
    }
    _release(_images.remove(key));
    _images[key] = image;
    _currentBytes += _bytesOf(image);
    while (_images.length > 1 &&
        (_images.length > maxEntries || _currentBytes > maxBytes)) {
      _release(_images.remove(_images.keys.first));
    }
  }

  static int _bytesOf(ui.Image image) => image.width * image.height * 4;

  void _release(ui.Image? image) {
    if (image == null) {
      return;
    }
    _currentBytes -= _bytesOf(image);
    image.dispose();
  }

  /// Captures what [boundary] currently paints and stores it under [key].
  ///
  /// [pixelRatio] scales the logical size, so a small value keeps posters
  /// cheap. Returns whether a frame was stored; a capture that fails leaves the
  /// previous poster in place, since a missing poster must never break playback.
  Future<bool> capture(
    String key,
    RenderRepaintBoundary boundary, {
    double pixelRatio = 0.75,
  }) async {
    try {
      put(key, await boundary.toImage(pixelRatio: pixelRatio));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Releases every stored frame.
  void dispose() {
    _isDisposed = true;
    for (final ui.Image image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _currentBytes = 0;
  }
}
