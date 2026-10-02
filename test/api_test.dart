import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currentController is null, not an error, before any selection',
      () async {
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: FakeVideoController.new,
      config: testConfig(),
    );

    expect(preloader.activeIndex, -1);
    expect(preloader.currentController, isNull);

    await preloader.scroll(2);

    expect(preloader.activeIndex, 2);
    expect(preloader.currentController?.dataSource, defaultSources[2]);

    await preloader.disposeAll();
  });

  test('exposes the window start and item count as properties', () async {
    final VideoFlux preloader = VideoFlux(
      items: testVideos(manySources(10)),
      controllerFactory: FakeVideoController.new,
      config: testConfig(preloadBackward: 1, preloadForward: 1, windowSize: 3),
    );

    await preloader.scroll(6);

    expect(preloader.itemCount, 10);
    expect(preloader.windowStart, 5);

    await preloader.disposeAll();
  });

  test('paginationThreshold can be assigned and rejects negatives', () async {
    final VideoFlux preloader = VideoFlux(
      items: testVideos(defaultSources),
      controllerFactory: FakeVideoController.new,
      config: testConfig(paginationThreshold: 4),
    );

    expect(preloader.paginationThreshold, 4);
    preloader.paginationThreshold = 1;
    expect(preloader.paginationThreshold, 1);
    expect(() => preloader.paginationThreshold = -1, throwsArgumentError);

    await preloader.disposeAll();
  });
}
