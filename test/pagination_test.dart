import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pagination', () {
    test('marks the end of the feed when a page comes back empty', () async {
      int calls = 0;
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(paginationThreshold: 5),
        onPaginationNeeded: () async {
          calls++;
          return const <TestVideo>[];
        },
      );

      await preloader.scroll(0);
      await preloader.scroll(1);

      expect(preloader.hasReachedEnd, isTrue);
      expect(calls, 1);

      await preloader.disposeAll();
    });

    test('reports a failure instead of throwing from scroll', () async {
      final List<Object> errors = <Object>[];
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
        onPaginationNeeded: () => Future<List<TestVideo>>.error(
          StateError('offline'),
        ),
        onPaginationError: (Object error, StackTrace _) => errors.add(error),
      );

      await preloader.scroll(0);

      expect(errors.single, isA<StateError>());
      expect(preloader.hasReachedEnd, isFalse);

      await preloader.disposeAll();
    });

    test('backs off after a failure and then tries again', () async {
      int calls = 0;
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config:
            testConfig(paginationRetryDelay: const Duration(milliseconds: 40)),
        onPaginationNeeded: () {
          calls++;
          return Future<List<TestVideo>>.error(StateError('offline'));
        },
      );
      await preloader.scroll(0);

      await preloader.scroll(1);
      expect(calls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      await preloader.scroll(2);

      expect(calls, 2);

      await preloader.disposeAll();
    });

    test('recovers and appends a page after a failure', () async {
      bool shouldFail = true;
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(paginationRetryDelay: Duration.zero),
        onPaginationNeeded: () async {
          if (shouldFail) {
            throw StateError('offline');
          }
          return <TestVideo>[const TestVideo('extra', 'extra.mp4')];
        },
      );
      await preloader.scroll(0);
      shouldFail = false;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await preloader.scroll(1);

      expect(preloader.getItemById('extra'), isNotNull);
      expect(preloader.itemCount, 4);

      await preloader.disposeAll();
    });

    test('reports duplicate ids in a page as a pagination error', () async {
      final List<Object> errors = <Object>[];
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
        onPaginationNeeded: () async => <TestVideo>[
          TestVideo(manySources(3).first, 'dup.mp4'),
        ],
        onPaginationError: (Object error, StackTrace _) => errors.add(error),
      );

      await preloader.scroll(0);

      expect(errors.single, isA<ArgumentError>());
      expect(preloader.itemCount, 3);

      await preloader.disposeAll();
    });

    test('rejects a page with a duplicate id without changing the feed',
        () async {
      final List<VideoFluxEvent> events = <VideoFluxEvent>[];
      final VideoFlux<TestVideo> preloader = VideoFlux<TestVideo>(
        items: testVideos(manySources(3)),
        controllerFactory: FakeVideoController.new,
        config: testConfig(),
        onPaginationNeeded: () async => <TestVideo>[
          const TestVideo('new', 'new.mp4'),
          TestVideo(manySources(3).first, 'duplicate.mp4'),
        ],
      );
      preloader.events.listen(events.add);

      await preloader.scroll(0);
      await settle();

      expect(events.whereType<PaginationFailed>(), hasLength(1));
      expect(preloader.itemCount, 3);
      expect(preloader.getItemById('new'), isNull);

      await preloader.disposeAll();
    });
  });
}
