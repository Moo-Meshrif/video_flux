import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('device tier', () {
    test('classifies constrained devices as low', () {
      expect(
        DeviceTier.classify(
          processorCount: 4,
          refreshRate: 120,
          pixelRatio: 3,
        ),
        DeviceTier.low,
      );
    });

    test('classifies capable devices as high', () {
      expect(
        DeviceTier.classify(
          processorCount: 8,
          refreshRate: 120,
          pixelRatio: 2,
        ),
        DeviceTier.high,
      );
    });

    test('classifies eight cores on a basic display as mid', () {
      expect(
        DeviceTier.classify(
          processorCount: 8,
          refreshRate: 60,
          pixelRatio: 2,
        ),
        DeviceTier.mid,
      );
    });

    test('classifies an unknown processor count as mid', () {
      expect(
        DeviceTier.classify(
          processorCount: null,
          refreshRate: 120,
          pixelRatio: 3,
        ),
        DeviceTier.mid,
      );
    });

    test('narrows the configured window to the detected tier', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(20)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          preloadBackward: 3,
          preloadForward: 3,
          windowSize: 8,
          adaptive: true,
          deviceTierProbe: const FixedDeviceTierProbe(DeviceTier.low),
        ),
      );

      expect(preloader.deviceTier, DeviceTier.low);
      expect(preloader.effectiveLimits.windowSize, 2);
      expect(preloader.effectiveLimits.preloadBackward, 0);
      expect(preloader.effectiveLimits.preloadForward, 1);

      await preloader.scroll(10);

      expect(preloader.getActiveControllers(), hasLength(2));

      await preloader.disposeAll();
    });

    test('never widens the configuration on a high tier', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(20)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          preloadBackward: 1,
          preloadForward: 1,
          windowSize: 3,
          adaptive: true,
        ),
      );

      expect(preloader.effectiveLimits.windowSize, 3);

      await preloader.disposeAll();
    });

    test('ignores the tier when adaptive is off', () async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(20)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          deviceTierProbe: const FixedDeviceTierProbe(DeviceTier.low),
        ),
      );

      expect(preloader.effectiveLimits.windowSize, 8);

      await preloader.disposeAll();
    });
  });

  group('memory pressure', () {
    Future<VideoFlux> feedAt(int index, {bool adaptive = true}) async {
      final VideoFlux preloader = VideoFlux(
        items: testVideos(manySources(30)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(
          preloadBackward: 2,
          preloadForward: 3,
          windowSize: 8,
          adaptive: adaptive,
        ),
      );
      await preloader.scroll(index);
      return preloader;
    }

    test('shrinks the window immediately when pressure rises', () async {
      final VideoFlux preloader = await feedAt(10);

      preloader.reportMemoryPressure(MemoryPressureLevel.critical);
      await settle();

      expect(preloader.effectiveLimits.windowSize, 1);
      expect(preloader.getActiveControllers(), hasLength(1));
      expect(preloader.getControllerAtIndex(10), isNotNull);

      await preloader.disposeAll();
    });

    test('moderate pressure keeps a smaller window around the active item',
        () async {
      final VideoFlux preloader = await feedAt(10);

      preloader.reportMemoryPressure(MemoryPressureLevel.moderate);
      await settle();

      expect(preloader.effectiveLimits.windowSize, 4);
      expect(preloader.getActiveControllers(), hasLength(4));
      expect(preloader.getControllerAtIndex(10), isNotNull);

      await preloader.disposeAll();
    });

    test('grows back one level at a time after the recovery period', () async {
      final VideoFlux preloader = await feedAt(10);
      preloader.reportMemoryPressure(MemoryPressureLevel.critical);

      preloader.reportMemoryPressure(MemoryPressureLevel.none);
      expect(preloader.memoryPressure, MemoryPressureLevel.critical);

      await until(
        () => preloader.memoryPressure == MemoryPressureLevel.moderate,
      );
      expect(preloader.effectiveLimits.windowSize, lessThan(8));

      await until(() => preloader.memoryPressure == MemoryPressureLevel.none);
      await settle();
      expect(preloader.effectiveLimits.windowSize, 8);

      await preloader.disposeAll();
    });

    test('a new spike cancels a recovery in progress', () async {
      final VideoFlux preloader = await feedAt(10);
      preloader.reportMemoryPressure(MemoryPressureLevel.moderate);
      preloader.reportMemoryPressure(MemoryPressureLevel.none);

      preloader.reportMemoryPressure(MemoryPressureLevel.critical);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(preloader.memoryPressure, MemoryPressureLevel.critical);

      await preloader.disposeAll();
    });

    test('the platform low-memory warning reports critical pressure', () async {
      final VideoFlux preloader = await feedAt(10);

      preloader.didHaveMemoryPressure();

      expect(preloader.memoryPressure, MemoryPressureLevel.critical);

      await preloader.disposeAll();
    });

    test('is ignored when adaptive is off', () async {
      final VideoFlux preloader = await feedAt(10, adaptive: false);

      preloader.reportMemoryPressure(MemoryPressureLevel.critical);

      expect(preloader.memoryPressure, MemoryPressureLevel.none);
      expect(preloader.effectiveLimits.windowSize, 8);

      await preloader.disposeAll();
    });
  });
}
