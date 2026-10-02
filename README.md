# 🎬 video_flux

<div align="center">

**A player-agnostic video preloading window for Flutter feeds — keep a bounded set of controllers initialized around the active item so TikTok/Reels-style scrolling starts instantly and never runs out of memory.**

</div>

<p align="center">
  <img src="doc/video_flux.gif" alt="Video Flux demo: sliding window, fast scroll and feed styles on a real phone" width="760">
</p>

## ✨ Features

- 🎯 **Sliding Window Preload** - Only the items around the active one stay initialized
- 🔑 **ID-Keyed Items** - Look up, select and paginate by stable id, not index
- ⚡ **Fast-Scroll Debounce** - Flick past 40 items and 40 videos don't load
- ♻️ **Release Before Allocate** - Outgoing decoders are disposed before incoming ones exist
- 🚦 **Concurrency Limit** - Nearest item initializes first, never more than N at once
- 📱 **Device Tier Detection** - Auto low/mid/high clamping, no plugin required
- 🌡️ **Memory Pressure Response** - Shrinks instantly, recovers slowly, never oscillates
- 🔁 **Pluggable Retry Policies** - A waiting retry never holds a concurrency slot
- 🖼️ **Frame-Zero Warm-Up** - Optional hook removes the black flash before playback
- 📄 **Resilient Pagination** - Backoff on failure, `hasReachedEnd` when the feed is done
- 🔃 **Refresh Without Rebuilding** - `replaceItems` keeps every controller whose video survives
- 🔄 **Lifecycle Aware** - Pauses when the app goes inactive, resumes only the active video
- 📊 **Built-in Diagnostics** - Always-on stats plus a lazy, sealed event stream
- 🎥 **Any Video Player** - Binds to none of them; you write a small adapter
- 🧩 **State-Management Agnostic** - Bloc, Riverpod, Provider, GetX, or none

## 📦 Installation

```yaml
dependencies:
  video_flux: latest_version

  # …plus whichever video player you use. The package binds to none of them,
  # so the version is entirely your call.
  video_player: latest_version   # or chewie, better_player, media_kit, …
```

```bash
flutter pub get
```

> **💡 Note**: This package depends on Flutter and nothing else — it never
> imports a video player. You bring your own and adapt it to
> `CustomVideoController` (step 1 below).

**Requires**: Dart ≥ 3.0.0

## 🚀 Quick Start

### 1. Write Your Adapter

`video_flux` plays nothing itself. It creates, retains and disposes
**controllers**, and a `CustomVideoController` is what turns your player of
choice into one.

```dart
import 'package:video_flux/video_flux.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerAdapter extends CustomVideoController {
  VideoPlayerAdapter(this.dataSource)
      : player = VideoPlayerController.networkUrl(Uri.parse(dataSource));

  @override
  final String dataSource;
  final VideoPlayerController player;

  @override
  bool get isInitialized => player.value.isInitialized;

  @override
  bool get isPlaying => player.value.isPlaying;

  @override
  Future<void> initialize() => player.initialize();

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> dispose() => player.dispose();

  // Optional, but recommended: decode frame zero so the video paints at once.
  @override
  Future<void> warmUp() async {
    await player.seekTo(Duration.zero);
    await player.pause();
  }
}
```

> [!IMPORTANT]
> The factory must return a **new, uninitialized** controller on every call.
> Retries rely on this: a failed controller is replaced, never reused.

### 2. Describe Your Items

Every item implements `VideoFluxItem`: a stable `id` and a playable `url`.

```dart
class FeedVideo implements VideoFluxItem {
  const FeedVideo({required this.id, required this.url});

  @override
  final String id;   // unique and non-empty within one preloader

  @override
  final String url;
}
```

### 3. Create the Preloader

```dart
final preloader = VideoFlux<FeedVideo>(
  items: videos,
  controllerFactory: VideoPlayerAdapter.new,
  config: const VideoFluxConfig.tikTok(),
  onControllerInitialized: (controller) => setState(() {}),
  onControllerInitializationError: (controller, error, stackTrace) {
    // Report or render the backend error.
  },
);
```

### 4. Tell It Which Item Is Visible

```dart
PageView.builder(
  scrollDirection: Axis.vertical,
  itemCount: preloader.itemCount,
  onPageChanged: (index) => preloader.scroll(index),   // the entire contract
  itemBuilder: (context, index) => FeedPage(index: index),
)
```

### 5. Ask for a Controller When You Paint

```dart
final controller = preloader.getControllerAtIndex(index);

if (controller == null || !controller.isInitialized) {
  // Still warming, or outside the window — both are normal, not errors.
  return const Center(child: CircularProgressIndicator());
}

return VideoPlayer((controller as VideoPlayerAdapter).player);
```

> [!WARNING]
> **Pause, never dispose.** The controller belongs to the window; disposing it in
> your widget's `dispose()` pulls a live controller out from under the preloader.
> `scroll()` already plays the selected video and pauses the others.

### 6. Dispose

```dart
@override
void dispose() {
  preloader.disposeAll();   // native decoders aren't GC'd
  super.dispose();
}
```

That's the whole integration: no controller creation, no disposal, no pooling,
no counting.

> [!IMPORTANT]
> **Two obligations.** Call `disposeAll()` when the feed goes away, and make every
> item `id` **unique and non-empty** — the constructor throws otherwise.

## 💡 Pro Tip

```bash
cd example && flutter run
```

A complete demo feed lives in [`example/`](example). Start there if you'd rather
read a working integration than assemble one.

## 📖 Documentation

### 🎯 Presets & Configuration

Pick a preset that matches your feed shape, and adjust it with `copyWith`:

```dart
config: const VideoFluxConfig.tikTok().copyWith(autoplayFirstVideo: true),
```

| Preset | Behind | Ahead | Window | Use Case |
|--------|--------|-------|--------|----------|
| `.tikTok()` | 1 | 2 | 4 | Full-screen vertical feeds |
| `.shorts()` | 2 | 2 | 5 | Feeds users scrub backwards through |
| `.currentOnly()` | 0 | 0 | 1 | Baseline / very constrained devices |

Two feed shapes the presets don't cover, as used by the example app:

```dart
// Mixed timeline (video + text posts), one video on screen at a time
const timeline = VideoFluxConfig(
  preloadBackward: 1,
  preloadForward: 2,
  windowSize: 4,
  scrollDebounce: Duration(milliseconds: 150),
);

// Tap-through stories: advance instantly, no debounce
const stories = VideoFluxConfig(
  preloadBackward: 0,
  preloadForward: 1,
  windowSize: 2,
  scrollDebounce: Duration.zero,
);
```

Keep at least one item behind in any list a user scrolls back up: with
`preloadBackward: 0` the previous video is released and must initialize again
before it plays.

Or build your own with `VideoFluxConfig(...)`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `preloadBackward` | `3` | Items behind the active one to keep ready |
| `preloadForward` | `3` | Items ahead of the active one to keep ready |
| `windowSize` | `8` | Maximum controllers retained at once |
| `directionalPreloadBias` | `0` | Extra positions shifted toward the scroll direction |
| `maxVelocityPreload` | `0` | Maximum extra positions for fast scrolling (`0` disables) |
| `velocityPreloadThreshold` | `1` | Pages/second required per extra velocity position |
| `maxConcurrentInitializations` | `2` | Simultaneous `initialize` calls (`null` = unlimited) |
| `scrollDebounce` | `120 ms` | Coalesces the burst of index changes a flick produces |
| `jumpThreshold` | `5` | Index delta at or above which the debounce is bypassed |
| `paginationThreshold` | `5` | Remaining items at which `onPaginationNeeded` fires |
| `paginationRetryDelay` | `2 s` | Base pause after a pagination failure; doubles, capped at 30 s |
| `autoplayFirstVideo` | `false` | Play the first video once it initializes |
| `handleAppLifecycle` | `true` | Pause and resume with the app lifecycle |
| `retryPolicy` | `ExponentialBackoffRetryPolicy()` | How initialization failures are retried |
| `adaptive` | `true` | Narrow the config by device tier and memory pressure |
| `deviceTierProbe` | `PlatformDeviceTierProbe()` | Decides the device tier |
| `pressureRecoveryDuration` | `5 s` | Quiet period before limits grow back one level |
| `initializationTimeout` | `20 s` | Longest one `initialize` may take before it counts as failed and is retried (`null` = wait forever) |

`windowSize` is the maximum number of controllers retained at one time. It covers
the active video plus the videos you want ready on either side:

```dart
preloadBackward: 2,
preloadForward: 2,
windowSize: 5, // 2 previous + active + 2 next
```

> **💡 Note**: `windowSize` must be **greater than** `preloadBackward +
> preloadForward`, so `5` is the minimum valid window for the example above.
> Invalid configuration throws an `ArgumentError` at construction.

Choose the smallest window that keeps scrolling smooth on your target devices.
Larger windows reduce startup delays but retain more player memory and network
resources.

### 🔑 Stable IDs & Typed Items

`VideoFlux` stores your model directly. Use ids for lookup and navigation without
relying on an index:

```dart
await preloader.scrollToId(videoId);
final video = preloader.getItemById(videoId);
final controller = preloader.getControllerById(videoId);
```

`getControllerById` returns `null` for an item outside the window — that's the
signal it isn't warm, not an error.

### 🧭 Direction Bias & Velocity

The window is fixed by default. Bias it toward the user's direction of travel, and
pass `scrollVelocity` in pages per second to buffer more during fast movement:

```dart
config: const VideoFluxConfig(
  preloadBackward: 2,
  preloadForward: 2,
  windowSize: 5,
  directionalPreloadBias: 1,
  maxVelocityPreload: 2,
  velocityPreloadThreshold: 1,
),

await preloader.scroll(pageIndex, scrollVelocity: pagesPerSecond);
```

The resolved direction is available as `preloader.preloadDirection`
(`idle`, `forward` or `backward`).

### ⚡ Fast Scroll & Concurrency

Three mechanisms, all automatic:

| Mechanism | Default | What It Does |
|-----------|---------|--------------|
| **Debounce** | `120 ms` | A flick emits a burst of index changes; the preloader waits for it to settle instead of starting work for each |
| **Jump threshold** | `5` | A move of 5+ isn't a scroll — the debounce is skipped so the item the user is waiting for starts immediately |
| **Concurrency limit** | `2` | At most two `initialize` calls at once, **nearest item first** |

An initialization that is still queued when its controller leaves the window is
**dropped without ever starting**. `stats.initializationsCancelled` counts the
work that was avoided.

> **💡 Note**: `initialize()` cannot be aborted mid-flight — no player offers
> that. "Cancelled" means a stale task never *starts*. The debounce delays the
> *effects* of a small scroll (including starting playback) by `scrollDebounce`;
> set it to `Duration.zero` if you would rather trade that for instant reaction.

✅ **Verify it**: jump from 0 to 100. Items 1–99 never reach your factory, and
`stats.initializationsCancelled` climbs.

### ♻️ Release Before Allocate

When the window moves, every controller that leaves is disposed **before** any new
one is created. Creating first and disposing afterwards means the outgoing and
incoming decoders are alive at the same moment — the peak that gets a process
killed. A jump past the whole window is handled the same way.

### 📱 Device Tiers

Detection is automatic and free — no `device_info_plus`. It reads processor
count, refresh rate and pixel ratio.

| Tier | Behind / Ahead | Max Window |
|------|----------------|------------|
| `low` | 0 / 1 | 2 |
| `mid` | 1 / 2 | 4 |
| `high` | as configured | as configured |

The tier only ever *lowers* your config — it's a ceiling, resolved once at
startup.

> [!WARNING]
> Most emulators report few cores and will land on `low` or `mid`, so the window
> can look smaller than you configured. Check `preloader.deviceTier` and
> `preloader.effectiveLimits` before assuming something is broken.

Classify devices yourself if you can do better, or turn the whole thing off:

```dart
config: const VideoFluxConfig(
  deviceTierProbe: FixedDeviceTierProbe(DeviceTier.high),
  // adaptive: false,   // ignore tier and memory pressure entirely
),
```

### 🌡️ Memory Pressure

| Level | Window | Preload | Concurrency |
|-------|--------|---------|-------------|
| `none` | as configured | as configured | as configured |
| `moderate` | ×0.6 (≥2) | ×0.5 (≥1 ahead) | 1 |
| `critical` | 1 | 0 / 0 | 1 |

The platform's low-memory warning is reported as `critical` automatically.

**Shrink is immediate; growth is not.** Recovering steps back one level at a time,
each after `pressureRecoveryDuration`. That asymmetry is what stops a device near
its limit from flapping between panic and greed.

Feed it your own signal any time:

```dart
preloader.reportMemoryPressure(MemoryPressureLevel.moderate);
```

### 🔁 Retry Policies

| Policy | Behaviour |
|--------|-----------|
| `ExponentialBackoffRetryPolicy()` | **Default.** 1 retry, 500 ms initial, ×2, capped at 30 s |
| `FixedDelayRetryPolicy()` | 2 retries, fixed 500 ms |
| `NoRetryPolicy()` | Fail immediately |
| *your own* | One method — return `null` to give up permanently |

```dart
class TransientOnlyRetryPolicy extends RetryPolicy {
  const TransientOnlyRetryPolicy();

  @override
  Duration? nextDelay(int attempt, Object error, StackTrace stackTrace) {
    if (error is! SocketException) return null;   // a 404 stays a 404
    return attempt >= 3 ? null : Duration(milliseconds: 300 * attempt);
  }
}
```

`attempt` is the one-based number of the attempt that just failed. Two guarantees:
**a waiting retry never holds a concurrency slot**, so one dead URL can't starve
the queue; and every retry uses a **fresh** controller from your factory.

Once the final attempt fails, call `retry(index)` to try again — for example from
a "Tap to retry" button:

```dart
await preloader.retry(index);   // throws StateError if it hasn't failed
```

> **💡 Note**: Show failures in your UI. An endless spinner is indistinguishable
> from a slow network, which turns a dead URL into a bug report about your
> preloader.

### 🖼️ Frame-Zero Warm-Up

Override `warmUp()` on your controller to seek to the start and pause. It runs once
after `initialize()` succeeds and before the controller is marked ready, so the
first frame is already decoded when it appears. Failures are swallowed on purpose:
a missing warm-up costs a black flash, never the video.

### 📄 Pagination

Set `paginationThreshold` to the number of remaining items at which the package
should call `onPaginationNeeded`. Return the next page in feed order, or an empty
list when there are no more videos:

```dart
final preloader = VideoFlux<Video>(
  items: firstPage,
  controllerFactory: VideoPlayerAdapter.new,
  onPaginationNeeded: () => api.fetchNextPage(),   // Future<List<Video>>
  onPaginationError: (error, stackTrace) => report(error, stackTrace),
);
```

- Only one request runs at a time.
- An **empty page** sets `preloader.hasReachedEnd` and stops further calls.
- A **failure** is reported to `onPaginationError` — `scroll()` never throws for
  it — and pagination pauses with a doubling delay (`paginationRetryDelay`, capped
  at 30 s) before a later scroll tries again.
- Appended items are validated like the initial ones, so duplicate ids are
  reported as a pagination error.

### 📊 Observing Controller State

`controllerStates` is a `ValueListenable` for the controllers currently in the
window. A disposed controller is emitted **before** it is removed from the list.

| Status | Meaning |
|--------|---------|
| `initializing` | Initializing, or waiting for a concurrency slot |
| `ready` | Initialized successfully |
| `failed` | Initialization failed (after any retries) |
| `disposed` | Released; about to leave the window |

```dart
preloader.controllerStates.addListener(() {
  for (final state in preloader.controllerStates.value) {
    if (state.status == VideoFluxStatus.failed) {
      reportError(state.error, state.stackTrace);
    }
  }
});
```

Each state carries `index`, `item`, `controller`, `initializationAttempt`, and on
failure `error` and `stackTrace`.

### 📈 Diagnostics

Counters are always on and cost nothing:

```dart
print(preloader.stats);
// active 4/5, ready 4, queued 0, cancelled 37, released 12, retried 1,
// failed 1, hitRate 94%, p95 210ms, tier high, pressure none
```

| Reading | What It Means |
|---------|---------------|
| `initializationsCancelled` climbing during a flick | ✅ Healthy — avoided work |
| `activeControllers` pinned at the window + `controllersReleased` climbing | Window is bigger than the device will hold |
| `poolHitRate` low | Window is too small for the scroll speed |
| `p95InitializationDuration` | The number that predicts black frames — the mean hides the tail |
| `effectiveLimits` smaller than your config | A clamp, not a bug — check `deviceTier` and `memoryPressure` |

The event stream is lazy and sealed, so a `switch` over it is exhaustive:

```dart
preloader.events.listen((event) {
  switch (event) {
    case ControllerReady(:final index, :final duration):
      debugPrint('ready #$index in ${duration.inMilliseconds}ms');
    case InitializationFailed(:final id, :final error, :final willRetry):
      if (!willRetry) setState(() => _failures[id] = error.toString());
    case PressureChanged(:final level):
      debugPrint('pressure → ${level.name}');
    default:
      break;
  }
});
```

**All events**: `ScrollSelected` · `InitializationStarted` · `ControllerReady` ·
`InitializationFailed` · `InitializationCancelled` · `ControllerReleased` ·
`PressureChanged` · `LimitsChanged` · `PaginationCompleted` · `PaginationEnded` ·
`PaginationFailed`

### 🔃 Replacing the Feed

Pull-to-refresh, a deleted post or an inserted ad is a new list, not an appended
page. Hand the preloader the new list instead of building a new preloader:

```dart
await preloader.replaceItems(freshVideos);
```

A **ready** controller is kept, with no reinitialization and playback untouched,
when its item `id` is still present with the same `url` and falls inside the new
window. Everything else is released before anything new is created, so the memory
guarantee holds across a refresh.

| Situation | Result |
|-----------|--------|
| Active item moved in the new list | `activeIndex` follows its id |
| Active item is gone | Same position, clamped to the new length |
| Same id, different `url` | Controller replaced |
| Controller still initializing, or failed | Released; the new window starts fresh |
| Empty list | Everything is released; `activeIndex` is `-1` |
| Duplicate or empty id | `ArgumentError`, nothing changes |
| A page still being fetched | Discarded; `hasReachedEnd` is reset |

> [!NOTE]
> `await` the result before calling `scroll` with an index from the new list. The
> swap applies once earlier operations finish, so an index past the *old* length
> is still rejected until then. An `ItemsReplaced` event reports how many
> controllers were kept and released.

### 🔄 App Lifecycle

With `handleAppLifecycle: true` (the default), the preloader pauses playback when
the app becomes inactive, hidden, paused or detached, and on return resumes **only
the active video — and only if it was playing**.

Routing lifecycle yourself? Turn it off and drive it manually:

```dart
config: const VideoFluxConfig(handleAppLifecycle: false),

await preloader.pauseAll();
await preloader.resumeActive();
```

`bindToAppLifecycle()` and `unbindFromAppLifecycle()` toggle it at runtime.

### 🖼️ Poster Cache (optional)

A video that was released and has to initialize again shows nothing until it is
ready. A **poster** is a picture painted in its place: the last frame you saw of
that video. `PosterCache` stores those frames. `VideoFlux` never touches it,
because capturing and drawing depend on your player and your UI, so you wire it
in. This guide builds a complete poster widget in five steps.

**What a poster does and does not cover**

| Situation | Poster |
|-----------|--------|
| You watched a video, scrolled away, and it was released, then you come back | ✅ Shows its last frame |
| You flicked past a video and never watched it | ❌ Nothing was captured; show a thumbnail image from your own data |
| The video is still retained and ready | Not needed; the live picture shows |

#### Step 1. Create one cache and own it

Create one cache for the whole feed and dispose it once, with the screen that
owns the preloader.

```dart
late final VideoFlux<FeedVideo> preloader;
final PosterCache posters = PosterCache(); // 24 frames, 32 MiB by default

Future<void> close() async {
  await preloader.disposeAll();
  posters.dispose();
}
```

Key frames by anything stable: the item `id` or the `url`. A capture that
finishes after `dispose()` is released instead of stored, so a late capture
cannot leak.

#### Step 2. Wrap your video in a `RepaintBoundary`

`capture` reads what a `RepaintBoundary` currently paints, so give the one
around your video widget a `GlobalKey`:

```dart
final GlobalKey boundaryKey = GlobalKey();

RepaintBoundary(
  key: boundaryKey,
  child: VideoPlayer(controller.player), // your player's widget
)
```

#### Step 3. Capture while the video is on screen

Capture **once** after the video has been playing for a moment, and again as the
user leaves it only if that first capture did not happen. Capturing on every
rebuild wastes work.

```dart
Future<void> capture() async {
  final Object? boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is RenderRepaintBoundary) {
    await posters.capture(item.id, boundary, pixelRatio: 0.75);
  }
}
```

`capture` never throws: it returns `false` and keeps the previous poster when a
capture fails, because a missing poster must never break playback.

#### Step 4. Draw the poster while the video is not ready

```dart
Widget build(BuildContext context) {
  final CustomVideoController? controller = preloader.getControllerAtIndex(index);
  final bool isReady = controller != null && controller.isInitialized;
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: isReady ? RepaintBoundary(key: boundaryKey, child: yourVideo(controller)) : poster(),
  );
}

Widget poster() {
  final ui.Image? image = posters.of(item.id);
  return ColoredBox(
    color: Colors.black,
    child: image == null
        ? const SizedBox.expand()
        : RawImage(image: image, fit: BoxFit.cover),
  );
}
```

The cache owns every image: draw them, but never call `dispose()` on one.

#### Step 5. Rebuild when the controller state changes

Wrap the widget in `ValueListenableBuilder` over `preloader.controllerStates`, so
it swaps from the poster to the live picture as soon as the controller is ready.

#### The whole widget

This is a complete widget that you can paste and adapt. Replace `VideoPlayer(...)`
with your own player widget.

```dart
class PosterVideo extends StatefulWidget {
  const PosterVideo({
    required this.preloader,
    required this.posters,
    required this.index,
    super.key,
  });

  final VideoFlux<FeedVideo> preloader;
  final PosterCache posters;
  final int index;

  @override
  State<PosterVideo> createState() => _PosterVideoState();
}

class _PosterVideoState extends State<PosterVideo> {
  final GlobalKey _boundaryKey = GlobalKey();
  Timer? _captureTimer;
  bool _wasActive = false;
  bool _capturedThisVisit = false;

  String get _key => widget.preloader.getItemAtIndex(widget.index)!.id;

  @override
  void initState() {
    super.initState();
    widget.preloader.controllerStates.addListener(_onStatesChanged);
  }

  @override
  void dispose() {
    widget.preloader.controllerStates.removeListener(_onStatesChanged);
    _captureTimer?.cancel();
    super.dispose();
  }

  void _onStatesChanged() {
    final bool isActive = widget.preloader.activeIndex == widget.index;
    if (_wasActive && !isActive) {
      _captureTimer?.cancel();
      _capture(); // skipped when this visit already captured
      _capturedThisVisit = false;
    }
    _wasActive = isActive;
    final CustomVideoController? controller =
        widget.preloader.getControllerAtIndex(widget.index);
    if (isActive &&
        controller != null &&
        controller.isPlaying &&
        !_capturedThisVisit &&
        !(_captureTimer?.isActive ?? false)) {
      _captureTimer = Timer(const Duration(milliseconds: 500), _capture);
    }
  }

  Future<void> _capture() async {
    if (_capturedThisVisit) {
      return;
    }
    _capturedThisVisit = true;
    final Object? boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary) {
      await widget.posters.capture(_key, boundary, pixelRatio: 0.75);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<VideoFluxState<FeedVideo>>>(
        valueListenable: widget.preloader.controllerStates,
        builder: (BuildContext context, _, __) {
          final CustomVideoController? controller =
              widget.preloader.getControllerAtIndex(widget.index);
          final bool isReady = controller != null && controller.isInitialized;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isReady
                ? RepaintBoundary(
                    key: _boundaryKey,
                    child: VideoPlayer((controller as MyAdapter).player),
                  )
                : _poster(),
          );
        },
      );

  Widget _poster() {
    final ui.Image? image = widget.posters.of(_key);
    return ColoredBox(
      color: Colors.black,
      child: image == null
          ? const SizedBox.expand()
          : RawImage(image: image, fit: BoxFit.cover),
    );
  }
}
```

The example app's `VideoSurface` is a larger version of the same idea, with a
delayed spinner and a thumbnail placeholder.

#### Sizing the memory

The cache is bounded twice, and the least recently used frame is released first
when either limit is crossed:

| Setting | Default | Meaning |
|---------|---------|---------|
| `maxEntries` | `24` | Frames kept |
| `maxBytes` | `32 MiB` | Decoded pixels kept (`width × height × 4` bytes per frame) |

The newest frame is always kept, even when it alone exceeds `maxBytes`, and
`posters.of(key)` counts as a use, so a poster on screen is released last.
`posters.currentBytes` reports what is held.

`pixelRatio` multiplies the widget's logical size, so it is what controls the
cost of each frame. For a 411 × 915 logical screen:

| `pixelRatio` | One frame | 24 frames |
|--------------|-----------|-----------|
| `0.5` | about 0.4 MB | about 9 MB |
| `0.75` (recommended) | about 0.85 MB | about 20 MB |
| `1.0` | about 1.5 MB | about 36 MB (hits `maxBytes`) |
| `3.0` | about 13.5 MB | well over 300 MB (`maxBytes` keeps only about 2) |

A poster is shown only briefly and is scaled to fill the screen, so a low
`pixelRatio` looks fine and costs little.

#### Things to check

- **Platform-view players.** `capture` reads Flutter's own painting. A player that
  renders through a native platform view may capture a blank frame. Test one
  capture on a real device before relying on it.
- **Frame cost.** `capture` is an asynchronous GPU readback. Capture once per
  visit, not on every frame or every rebuild.
- **Never-watched videos.** They have no captured frame. Show a thumbnail from
  your own data (for example `Image.network(item.thumbnailUrl)`) when
  `posters.of(key)` is `null`.
- **Memory pressure.** The preloader does not know about your cache. When you
  call `preloader.reportMemoryPressure(...)`, you can also call
  `posters.dispose()` yourself and create a new cache when pressure recovers.

#### API

| Member | Purpose |
|--------|---------|
| `PosterCache({maxEntries = 24, maxBytes = 32 MiB})` | Creates the cache |
| `capture(key, boundary, {pixelRatio = 0.75})` | Stores what the boundary paints; returns whether it did |
| `put(key, image)` | Stores an image you made yourself; the cache takes ownership |
| `of(key)` | The stored `ui.Image`, or `null`; marks it as recently used |
| `currentBytes` | Decoded size currently held |
| `dispose()` | Releases every frame; later `put` calls release the image at once |

### 🎥 Custom Video Players

The package never inspects a player — it creates, retains and hands back your
controller. An adapter is just the contract below:

| Member | Responsibility |
|--------|----------------|
| `dataSource` | The source URL this controller was created for |
| `initialize()` | Prepare the source for playback |
| `play()` / `pause()` | Start and stop playback |
| `dispose()` | Release everything the backend holds |
| `isInitialized` | `true` once initialization succeeded |
| `isPlaying` | Whether the backend is currently playing |
| `warmUp()` | *Optional.* Decode frame zero after `initialize()` |
| `togglePlayPause()` | Provided for you; override if your player needs it |

## 🚀 How Scrolling Works

### 1. Operations Are Serialized

Every `scroll`, `retry`, `pauseAll` and dispose runs on one queue, so two
overlapping calls can never interleave window changes.

### 2. The Latest Selection Wins

Each `scroll` bumps a selection generation. A scroll that was superseded while it
waited — including during its debounce — is dropped rather than moving the window.

### 3. Flicks Are Coalesced, Jumps Are Not

A small move waits out `scrollDebounce`, so a flick through forty items takes
effect once. A jump is measured from the **last requested** index, so a flick of
single steps never adds up to a jump.

### 4. Release Before Allocate

Controllers leaving the window are disposed first; only then are new ones created.

### 5. Initialization Is Queued

New controllers wait for a free slot and start nearest-first. One that left the
window while it waited is dropped without starting.

### 6. Only the Active Video Plays

Selecting an item pauses every other retained controller and plays the selected
one once it is initialized.

## 🔧 API Reference

| Method | Description |
|--------|-------------|
| `scroll(index, {scrollVelocity})` | Selects an item, pauses the others and moves the window |
| `scrollToId(id, {scrollVelocity})` | Same, by item id |
| `getControllerAtIndex(index)` | Retained controller, or `null` outside the window |
| `getControllerById(id)` | Retained controller for an id, or `null` |
| `getActiveControllers()` | Unmodifiable list of every retained controller |
| `getItemAtIndex(index)` / `getItemById(id)` | The item model, or `null` |
| `forceAutoPlay(index)` | Play the controller at an index once initialized |
| `togglePlayPause(controller)` | Toggle one controller and pause the rest |
| `pauseAll()` / `resumeActive()` | Manual pause and resume |
| `replaceItems(items)` | Replace the feed, keeping ready controllers whose item survives |
| `retry(index)` | Retry a failed controller with a fresh backend |
| `reportMemoryPressure(level)` | Narrow the window under your own memory signal |
| `setControllerFactory(factory)` | Swap the factory for controllers created afterwards |
| `disposeAll()` | Release every controller, the state listenable and the event stream |

| Property | Description |
|----------|-------------|
| `controllerStates` | `ValueListenable` of per-controller status |
| `events` | Sealed, lazy stream of `VideoFluxEvent` |
| `stats` | Snapshot of counters and live state |
| `currentController` | Controller for the active item, or `null` when none is retained |
| `activeIndex` / `windowStart` | Last selected index / first index in the window |
| `itemCount` | Number of items currently loaded |
| `paginationThreshold` | Read or assign the pagination trigger |
| `effectiveLimits` | The limits being enforced right now |
| `deviceTier` / `memoryPressure` | Detected tier and current pressure level |
| `hasReachedEnd` | Pagination reported nothing more to load |
| `preloadDirection` | `idle`, `forward` or `backward` |

| Callback | Fires when |
|----------|------------|
| `onControllerInitialized` | A controller initializes successfully |
| `onControllerInitializationError` | A controller fails for good (not on retried failures) |
| `onPlayStateChanged` | The preloader starts or pauses playback |
| `onPaginationNeeded` | The active item nears the end; returns the next page |
| `onPaginationError` | `onPaginationNeeded` threw |

## ❓ FAQ

**Why do I have to write the adapter myself?**
Because binding to a player means depending on it. If this package shipped a
`video_player` binding, every `better_player` user would ship `video_player`'s
native code for nothing. The adapter is about 25 lines, written once.

**Does it work with Bloc / Riverpod / Provider / GetX?**
It has no idea which one you use and depends on none of them. `VideoFlux` is a
plain object; call it from whatever holds your feed.

**Does it handle scrolling?**
No, and it shouldn't. `PageView.onPageChanged` is yours; the preloader only needs
the resulting index.

**Can I use a `ListView` instead of a `PageView`?**
Yes. Anything that can tell you "item N is now focused" works — that's the only
input.

**Can I add or change items after creation?**
Not by mutating your list — it is copied on construction. Return the next page
from `onPaginationNeeded` to append, or call `replaceItems` to refresh, delete or
insert; controllers for items that survive are kept.

**Does it cache video files?**
No — it retains *initialized controllers*. Byte caching belongs in an HTTP cache
or a caching player.

**Why is my controller `null`?**
It is outside the window, or the window hasn't reached it yet. Both are normal —
show a placeholder and rebuild from `onControllerInitialized` or
`controllerStates`.

**Why is my window smaller than I configured?**
`adaptive` narrows it by device tier and memory pressure. Read
`preloader.effectiveLimits`, or set `adaptive: false`.

## 🤝 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.
