# video_flux example

A playground for the `video_flux` package. One feed screen with a toggle between
four styles that run the same package with different tuning, each with its own
content and configuration, and a live debug panel that shows what the preloader
is doing.

```bash
flutter run
```

## The feed styles

| Feed | Layout | Preset | Shows |
|------|--------|--------|-------|
| **TikTok** | Full-screen vertical pages | `VideoFluxConfig.tikTok()` | The baseline: one video per page |
| **Shorts** | Same, keeps two behind | `VideoFluxConfig.shorts()` | A window that looks backwards as well |
| **Facebook feed** | Scrolling list of video and text posts | 1 behind, 2 ahead, window 4, 150 ms debounce | A mixed feed: only videos are preloaded |
| **Stories** | Horizontal, tap to advance | 0 behind, 1 ahead, window 2, no debounce | Auto-advance, no debounce |

The exact configurations (defined in `lib/features/feed/data/enums/feed_style.dart`):

```dart
// Facebook
VideoFluxConfig(
  preloadBackward: 1,
  preloadForward: 2,
  windowSize: 4,
  scrollDebounce: Duration(milliseconds: 150),
)

VideoFluxConfig.tikTok()   // behind 1, ahead 2, window 4
VideoFluxConfig.shorts()   // behind 2, ahead 2, window 5

// Stories
VideoFluxConfig(
  preloadBackward: 0,
  preloadForward: 1,
  windowSize: 2,
  scrollDebounce: Duration.zero,
)
```

Every other field keeps the package default, and the example forces
`autoplayFirstVideo: true`.

Switch between them with the toggle under the toolbar. Each style keeps its own
content and configuration, so toggling away and back returns to what you set.
The restore icon resets the current style to its defaults.

## Use your own content

**Edit content** (the note icon) lets you paste your own video
URLs, one per line. Lines that are not http(s) URLs are reported and skipped.

- **Videos per page** and **Repeat the list** decide how pagination behaves. After
  the last repeat the feed returns an empty page, so you can see `hasReachedEnd`.
- **Add a broken URL** puts an unloadable video in the list, to see retries and
  the failure state.
- The Facebook feed also takes **text posts**, and a text post appears before every
  Nth video.

## Change the configuration

**Edit configuration** (the tune icon) exposes window size, behind/ahead,
direction bias, concurrency, debounce, jump threshold, pagination threshold,
adaptive mode, a forced device tier and the retry policy.
Invalid combinations are rejected with the package's own error message.

Applying either editor restarts the feed, because a preloader's configuration
is fixed when it is created. Settings live in memory only.

## The debug panel

The bug icon opens a panel over the lower half of the feed. The feed stays
interactive, so you can scroll and watch at the same time.

| Tab | What it shows |
|-----|---------------|
| **Stats** | `VideoFlux.stats` live, and the enforced limits next to the configured ones |
| **Window** | Every loaded video coloured by state; tap a cell to jump there |
| **Events** | The `VideoFlux.events` stream, newest first |
| **Controls** | Memory pressure, flick and jump buttons, a failing page request, retry |

Things worth trying:

- **Flick ×10** with a debounce set: "dropped before starting" climbs while few
  decoders start.
- **Memory pressure → critical**: the window collapses to one video at once, then
  grows back one level at a time.
- **Force the tier to low** and compare *enforced* with *configured* on the Stats
  tab.
- **Fail the next page request** and keep scrolling: pagination backs off, then
  recovers.

## How it is put together

MVVM, feature-first: a feature splits into `data` and `presentation`.

```text
lib/
  app.dart, app_dependencies.dart    wiring: the one place that picks data sources
  core/                              the only code that knows about video_player
  features/
    feed/                            the feed, all four styles
      data/
        models/                      FeedPost, FeedContent, FeedSetup
        enums/                       FeedStyle, FeedLayout
        datasources/                 FeedDataSource (simulated pages), FeedSetupDataSource
        repositories/                FeedRepository, FeedSetupRepository
      presentation/
        controller/                  FeedController (owns VideoFlux), FeedStatus,
                                     FeedSetupController, and one controller per layout
        pages/                       FeedPage: the toggle, toolbar, layout and debug panel
        widgets/                     VideoSurface, the style toggle, and a folder per
                                     layout: vertical/  timeline/  stories/
    settings/                        the tools around a feed
      data/models/                   ConfigDraft
      data/enums/                    TierChoice, RetryChoice
      presentation/
        controller/                  the two editor controllers, DebugPanelController
        pages/                       the content and configuration editor sheets
        widgets/                     StepperField, and debug/  the debug panel
```

Dependencies point one way: widgets and pages read a controller, a controller
reads a repository, a repository reads a data source. `FeedPage` is the one
place that composes `settings` (the editors and the debug panel), and `settings`
reads `FeedController` and the feed models, so the two features depend on each
other.

`FeedController` owns one `VideoFlux`. A feed has *rows* (what is drawn) and
*videos* (what `VideoFlux` manages); in the Facebook style they differ, and the
controller maps between them, so text posts never reach the package.
`core/video_player_adapter.dart` is the reference adapter to copy.
