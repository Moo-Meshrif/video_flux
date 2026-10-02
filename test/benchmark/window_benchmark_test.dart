// Measures what the README promises: a bounded number of live controllers and
// a controller that is ready by the time the user lands on an item.
//
//   flutter test test/benchmark
//
// Controllers are fakes with a fixed initialization latency, so the numbers
// compare presets with each other rather than predict a real device.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import '../support/fakes.dart';

const int _feedLength = 120;
const int _swipes = 60;
const Duration _initializationLatency = Duration(milliseconds: 15);
const Duration _dwell = Duration(milliseconds: 40);

class _Result {
  const _Result(this.preset, this.peakLive, this.readyOnArrival, this.created);

  final String preset;
  final int peakLive;
  final double readyOnArrival;
  final int created;
}

Future<_Result> _run(String preset, VideoFluxConfig config) async {
  int live = 0;
  int peak = 0;
  int created = 0;
  int ready = 0;
  int landings = 0;

  final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
    items: testVideos(manySources(_feedLength)),
    controllerFactory: (String source) {
      created++;
      peak = ++live > peak ? live : peak;
      return FakeVideoController(
        source,
        onInitialize: () => Future<void>.delayed(_initializationLatency),
        onDispose: () async => live--,
      );
    },
    config: config.copyWith(
      adaptive: false,
      scrollDebounce: Duration.zero,
      maxConcurrentInitializations: 2,
    ),
  );
  final StreamSubscription<VideoFluxEvent> subscription =
      preloader.events.listen((VideoFluxEvent event) {
    if (event is ScrollSelected) {
      landings++;
      if (event.wasReady) {
        ready++;
      }
    }
  });

  for (int index = 0; index < _swipes; index++) {
    await preloader.scroll(index);
    await Future<void>.delayed(_dwell);
  }
  await subscription.cancel();
  await preloader.disposeAll();

  return _Result(preset, peak, landings == 0 ? 0 : ready / landings, created);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('window presets stay bounded and ready on arrival', () async {
    final Map<String, VideoFluxConfig> presets = <String, VideoFluxConfig>{
      'tikTok': const VideoFluxConfig.tikTok(),
      'shorts': const VideoFluxConfig.shorts(),
      'currentOnly': const VideoFluxConfig.currentOnly(),
    };

    final List<_Result> results = <_Result>[
      for (final MapEntry<String, VideoFluxConfig> entry in presets.entries)
        await _run(entry.key, entry.value),
    ];

    // ignore: avoid_print
    print('\npreset       peak live  ready on arrival  controllers created');
    for (final _Result result in results) {
      // ignore: avoid_print
      print(
        '${result.preset.padRight(12)} '
        '${'${result.peakLive}'.padLeft(9)}  '
        '${'${(result.readyOnArrival * 100).round()}%'.padLeft(16)}  '
        '${'${result.created}'.padLeft(19)}',
      );
    }

    for (final _Result result in results) {
      expect(
        result.peakLive,
        lessThanOrEqualTo(presets[result.preset]!.windowSize),
        reason: '${result.preset} held more controllers than its window',
      );
    }
  });
}
