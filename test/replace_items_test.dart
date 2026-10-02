import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_flux/video_flux.dart';

import 'support/fakes.dart';

List<String> _ids(Iterable<int> indexes) =>
    indexes.map((int i) => 'https://example.com/$i.mp4').toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<FakeVideoController> created;

  VideoFlux<TestVideo> build({
    required List<String> sources,
    VideoFluxConfig? config,
    Future<List<TestVideo>> Function()? onPaginationNeeded,
  }) {
    created = <FakeVideoController>[];
    return VideoFlux<TestVideo>(
      items: testVideos(sources),
      controllerFactory: (String source) {
        final FakeVideoController controller = FakeVideoController(source);
        created.add(controller);
        return controller;
      },
      config: config ??
          testConfig(preloadBackward: 1, preloadForward: 1, windowSize: 3),
      onPaginationNeeded: onPaginationNeeded,
    );
  }

  group('replaceItems', () {
    test('keeps ready controllers whose item survives, without reinitializing',
        () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 10)));
      await preloader.scroll(5);
      await settle();
      final CustomVideoController survivor = preloader.getControllerAtIndex(5)!;
      final int createdBefore = created.length;

      // Item 5 moves from index 5 to index 1.
      await preloader.replaceItems(testVideos(_ids(<int>[9, 5, 6, 7])));
      await settle();

      expect(preloader.getControllerById('https://example.com/5.mp4'),
          same(survivor));
      expect(preloader.getControllerAtIndex(1), same(survivor));
      expect(survivor.isInitialized, isTrue);
      expect(
        created.sublist(createdBefore).map((c) => c.dataSource),
        isNot(contains('https://example.com/5.mp4')),
      );

      await preloader.disposeAll();
    });

    test('releases controllers whose items disappeared and stays bounded',
        () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 10)));
      await preloader.scroll(4);
      await settle();
      final List<FakeVideoController> before = created.toList();

      await preloader.replaceItems(testVideos(_ids(range(20, 30))));
      await settle();

      expect(before.every((FakeVideoController c) => c.disposed), isTrue);
      expect(preloader.getActiveControllers().length, lessThanOrEqualTo(3));
      expect(preloader.itemCount, 10);

      await preloader.disposeAll();
    });

    test('the active item follows its id to a new index', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 8)));
      await preloader.scroll(3);
      await settle();

      await preloader.replaceItems(testVideos(_ids(<int>[7, 6, 5, 4, 3, 2])));
      await settle();

      expect(preloader.activeIndex, 4);
      expect(
          preloader.currentController?.dataSource, 'https://example.com/3.mp4');

      await preloader.disposeAll();
    });

    test('clamps the active index when its item is gone', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 8)));
      await preloader.scroll(6);
      await settle();

      await preloader.replaceItems(testVideos(_ids(range(20, 24))));
      await settle();

      expect(preloader.activeIndex, 3);
      expect(preloader.currentController, isNotNull);

      await preloader.disposeAll();
    });

    test('a surviving active controller keeps playing', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 6)));
      await preloader.scroll(2);
      await settle();
      final CustomVideoController active = preloader.currentController!;
      expect(active.isPlaying, isTrue);

      await preloader.replaceItems(testVideos(_ids(range(1, 6))));
      await settle();

      expect(preloader.currentController, same(active));
      expect(active.isPlaying, isTrue);
      expect(
        preloader
            .getActiveControllers()
            .where((CustomVideoController c) => c.isPlaying),
        hasLength(1),
      );

      await preloader.disposeAll();
    });

    test('replaces the controller when an item keeps its id but changes url',
        () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 4)));
      await preloader.scroll(1);
      await settle();
      final CustomVideoController old = preloader.getControllerAtIndex(1)!;

      await preloader.replaceItems(const <TestVideo>[
        TestVideo('https://example.com/0.mp4', 'https://example.com/0.mp4'),
        TestVideo('https://example.com/1.mp4', 'https://cdn.example.com/1.mp4'),
      ]);
      await settle();

      expect(preloader.getControllerAtIndex(1), isNot(same(old)));
      expect(preloader.getControllerAtIndex(1)?.dataSource,
          'https://cdn.example.com/1.mp4');

      await preloader.disposeAll();
    });

    test('an empty feed releases everything', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 4)));
      await preloader.scroll(1);
      await settle();

      await preloader.replaceItems(const <TestVideo>[]);

      expect(preloader.getActiveControllers(), isEmpty);
      expect(preloader.activeIndex, -1);
      expect(preloader.itemCount, 0);
      expect(created.every((FakeVideoController c) => c.disposed), isTrue);

      await preloader.replaceItems(testVideos(_ids(range(0, 4))));
      await preloader.scroll(0);
      await settle();
      expect(preloader.currentController?.isInitialized, isTrue);

      await preloader.disposeAll();
    });

    test('shrinking the feed while initializations are queued does not throw',
        () async {
      final VideoFlux<TestVideo> preloader = build(
        sources: _ids(range(0, 30)),
        config: testConfig(
          preloadBackward: 0,
          preloadForward: 4,
          windowSize: 5,
          maxConcurrentInitializations: 1,
        ),
      );
      final List<VideoFluxEvent> events = <VideoFluxEvent>[];
      preloader.events.listen(events.add);

      await preloader.replaceItems(testVideos(_ids(range(0, 2))));
      await settle();

      expect(preloader.itemCount, 2);
      expect(preloader.getActiveControllers().length, 2);
      expect(events.whereType<ItemsReplaced>(), hasLength(1));

      await preloader.disposeAll();
    });

    test('reports what it kept and released', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 6)));
      await preloader.scroll(2);
      await settle();
      final List<VideoFluxEvent> events = <VideoFluxEvent>[];
      preloader.events.listen(events.add);

      await preloader.replaceItems(testVideos(_ids(range(2, 8))));
      await settle();

      final ItemsReplaced event = events.whereType<ItemsReplaced>().single;
      expect(event.itemCount, 6);
      expect(event.retained, greaterThan(0));
      expect(event.released, greaterThan(0));

      await preloader.disposeAll();
    });

    test('rejects duplicate or empty ids and changes nothing', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 4)));
      await preloader.scroll(1);
      await settle();

      expect(
        () => preloader.replaceItems(const <TestVideo>[
          TestVideo('a', 'a.mp4'),
          TestVideo('a', 'b.mp4'),
        ]),
        throwsArgumentError,
      );
      expect(
        () => preloader.replaceItems(const <TestVideo>[TestVideo('', 'a.mp4')]),
        throwsArgumentError,
      );

      expect(preloader.itemCount, 4);
      expect(preloader.activeIndex, 1);
      expect(preloader.currentController?.isInitialized, isTrue);

      await preloader.disposeAll();
    });

    test('discards a page that was being fetched for the old feed', () async {
      final Completer<List<TestVideo>> page = Completer<List<TestVideo>>();
      final VideoFlux<TestVideo> preloader = build(
        sources: _ids(range(0, 3)),
        onPaginationNeeded: () => page.future,
      );
      await preloader.scroll(0);

      await preloader.replaceItems(testVideos(_ids(range(10, 13))));
      page.complete(<TestVideo>[
        const TestVideo('stale', 'stale.mp4'),
      ]);
      await settle();

      expect(preloader.getItemById('stale'), isNull);
      expect(preloader.itemCount, 3);

      await preloader.disposeAll();
    });

    test('clears hasReachedEnd so a refreshed feed can paginate again',
        () async {
      int calls = 0;
      final VideoFlux<TestVideo> preloader = build(
        sources: _ids(range(0, 3)),
        onPaginationNeeded: () async {
          calls++;
          return const <TestVideo>[];
        },
      );
      await preloader.scroll(0);
      await settle();
      expect(preloader.hasReachedEnd, isTrue);

      await preloader.replaceItems(testVideos(_ids(range(10, 13))));
      await settle();

      expect(calls, 2);

      await preloader.disposeAll();
    });

    test('publishes controller states at their new indexes', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 8)));
      await preloader.scroll(4);
      await settle();

      await preloader.replaceItems(testVideos(_ids(<int>[9, 4, 5])));
      await settle();

      final Map<String, int> indexById = <String, int>{
        for (final VideoFluxState<TestVideo> state
            in preloader.controllerStates.value)
          state.item.id: state.index,
      };
      expect(indexById['https://example.com/4.mp4'], 1);

      await preloader.disposeAll();
    });

    test('throws after disposal', () async {
      final VideoFlux<TestVideo> preloader = build(sources: _ids(range(0, 3)));
      await preloader.disposeAll();

      expect(
          () => preloader.replaceItems(const <TestVideo>[]), throwsStateError);
    });
  });
}

Iterable<int> range(int start, int end) =>
    List<int>.generate(end - start, (int i) => start + i);
