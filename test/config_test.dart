import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('configuration', () {
    test('rejects a window that cannot hold its preload counts', () {
      expect(
        () => testConfig(preloadBackward: 2, preloadForward: 2, windowSize: 4)
            .validate(),
        throwsArgumentError,
      );
    });

    test('rejects a concurrency limit below one', () {
      expect(
        () => testConfig(maxConcurrentInitializations: 0).validate(),
        throwsArgumentError,
      );
    });

    test('presets describe valid windows', () {
      for (final VideoFluxConfig preset in const <VideoFluxConfig>[
        VideoFluxConfig.tikTok(),
        VideoFluxConfig.shorts(),
        VideoFluxConfig.currentOnly(),
      ]) {
        expect(preset.validate, returnsNormally);
      }
    });

    test('copyWith replaces only the given fields', () {
      final VideoFluxConfig config =
          const VideoFluxConfig.tikTok().copyWith(preloadForward: 1);

      expect(config.preloadForward, 1);
      expect(config.preloadBackward, 1);
      expect(config.windowSize, 4);
    });
  });
}
