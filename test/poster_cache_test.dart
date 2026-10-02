import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

Future<ui.Image> _image([int size = 4]) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint(),
  );
  return recorder.endRecording().toImage(size, size);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('of_isNullUntilAFrameIsStored', () async {
    final PosterCache cache = PosterCache();
    expect(cache.of('a'), isNull);

    final ui.Image image = await _image();
    cache.put('a', image);

    expect(cache.of('a'), same(image));
    cache.dispose();
  });

  test('put_releasesTheOldestBeyondMaxEntries', () async {
    final PosterCache cache = PosterCache(maxEntries: 2);
    final ui.Image first = await _image();

    cache.put('a', first);
    cache.put('b', await _image());
    cache.put('c', await _image());

    expect(cache.of('a'), isNull);
    expect(cache.of('b'), isNotNull);
    expect(cache.of('c'), isNotNull);
    expect(first.debugDisposed, isTrue);
    cache.dispose();
  });

  test('put_replacingAKeyReleasesItsPreviousFrame', () async {
    final PosterCache cache = PosterCache();
    final ui.Image first = await _image();
    final ui.Image second = await _image();

    cache.put('a', first);
    cache.put('a', second);

    expect(cache.of('a'), same(second));
    expect(first.debugDisposed, isTrue);
    cache.dispose();
  });

  test('dispose_releasesEveryFrame', () async {
    final PosterCache cache = PosterCache();
    final ui.Image image = await _image();
    cache.put('a', image);

    cache.dispose();

    expect(cache.of('a'), isNull);
    expect(image.debugDisposed, isTrue);
  });

  test('put_releasesTheLeastRecentlyUsedBeyondMaxBytes', () async {
    // 10x10 frames are 400 bytes each; the budget holds two.
    final PosterCache cache = PosterCache(maxBytes: 900);
    final ui.Image first = await _image(10);

    cache.put('a', first);
    cache.put('b', await _image(10));
    cache.of('a');
    cache.put('c', await _image(10));

    expect(cache.of('b'), isNull);
    expect(cache.of('a'), same(first));
    expect(cache.of('c'), isNotNull);
    expect(cache.currentBytes, 800);
    cache.dispose();
    expect(cache.currentBytes, 0);
  });

  test('put_keepsTheNewestFrameEvenWhenItExceedsMaxBytes', () async {
    final PosterCache cache = PosterCache(maxBytes: 100);
    final ui.Image small = await _image();
    final ui.Image large = await _image(10);

    cache.put('a', small);
    cache.put('b', large);

    expect(cache.of('a'), isNull);
    expect(cache.of('b'), same(large));
    expect(small.debugDisposed, isTrue);
    cache.dispose();
  });

  test('put_afterDisposeReleasesTheFrameInsteadOfStoringIt', () async {
    final PosterCache cache = PosterCache()..dispose();
    final ui.Image late = await _image();

    cache.put('a', late);

    expect(cache.of('a'), isNull);
    expect(late.debugDisposed, isTrue);
    expect(cache.currentBytes, 0);
  });
}
