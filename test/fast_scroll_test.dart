import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the item a fast scroll stops on starts loading while others hang',
      () async {
    final Completer<void> network = Completer<void>();
    final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
      items: testVideos(manySources(60)),
      controllerFactory: (String url) =>
          FakeVideoController(url, onInitialize: () => network.future),
      config: testConfig(
        maxConcurrentInitializations: 2,
        scrollDebounce: const Duration(milliseconds: 10),
      ),
    );
    final Set<int> started = <int>{};
    preloader.events.listen((VideoFluxEvent event) {
      if (event is InitializationStarted) {
        started.add(event.index);
      }
    });

    await flick(preloader, 0, 30);

    await until(() => started.contains(30));
    network.complete();
    await preloader.disposeAll();
  });
}
