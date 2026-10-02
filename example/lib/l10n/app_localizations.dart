import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Flux'**
  String get appTitle;

  /// No description provided for @editContent.
  ///
  /// In en, this message translates to:
  /// **'Edit content'**
  String get editContent;

  /// No description provided for @editConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Edit configuration'**
  String get editConfiguration;

  /// No description provided for @resetStyle.
  ///
  /// In en, this message translates to:
  /// **'Reset {style} to its defaults'**
  String resetStyle(String style);

  /// No description provided for @debugPanel.
  ///
  /// In en, this message translates to:
  /// **'Debug panel'**
  String get debugPanel;

  /// No description provided for @closeDebugPanel.
  ///
  /// In en, this message translates to:
  /// **'Close debug panel'**
  String get closeDebugPanel;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get switchLanguage;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @styleFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get styleFacebook;

  /// No description provided for @styleTikTok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get styleTikTok;

  /// No description provided for @styleShorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get styleShorts;

  /// No description provided for @styleStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get styleStories;

  /// No description provided for @styleFacebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Facebook feed'**
  String get styleFacebookTitle;

  /// No description provided for @styleTikTokTitle.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get styleTikTokTitle;

  /// No description provided for @styleShortsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get styleShortsTitle;

  /// No description provided for @styleStoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get styleStoriesTitle;

  /// No description provided for @styleFacebookSummary.
  ///
  /// In en, this message translates to:
  /// **'Video posts between text posts in a scrolling list. Only the videos are preloaded, one ahead.'**
  String get styleFacebookSummary;

  /// No description provided for @styleTikTokSummary.
  ///
  /// In en, this message translates to:
  /// **'Full-screen vertical pages, one video each. Looks one behind and two ahead.'**
  String get styleTikTokSummary;

  /// No description provided for @styleShortsSummary.
  ///
  /// In en, this message translates to:
  /// **'Same shape, but keeps two behind as well, because people scrub backwards.'**
  String get styleShortsSummary;

  /// No description provided for @styleStoriesSummary.
  ///
  /// In en, this message translates to:
  /// **'Horizontal, tap to advance, auto-advances when a clip ends. Keeps only the next one warm.'**
  String get styleStoriesSummary;

  /// No description provided for @couldNotLoadFeed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the feed.'**
  String get couldNotLoadFeed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @clipCaption.
  ///
  /// In en, this message translates to:
  /// **'Clip {number} of {total}'**
  String clipCaption(int number, int total);

  /// No description provided for @videoNumber.
  ///
  /// In en, this message translates to:
  /// **'Video {number}'**
  String videoNumber(int number);

  /// No description provided for @authorName.
  ///
  /// In en, this message translates to:
  /// **'Author {number}'**
  String authorName(int number);

  /// No description provided for @positionOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{position} / {total}'**
  String positionOfTotal(int position, int total);

  /// No description provided for @outsideWindow.
  ///
  /// In en, this message translates to:
  /// **'Outside the preload window — not loaded'**
  String get outsideWindow;

  /// No description provided for @initializingAttempt.
  ///
  /// In en, this message translates to:
  /// **'Initializing (attempt {attempt})…'**
  String initializingAttempt(int attempt);

  /// No description provided for @couldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not load this video\n{error}'**
  String couldNotLoadVideo(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @commentsAndShares.
  ///
  /// In en, this message translates to:
  /// **'{comments} comments · {shares} shares'**
  String commentsAndShares(int comments, int shares);

  /// No description provided for @sampleCommenter.
  ///
  /// In en, this message translates to:
  /// **'Sara'**
  String get sampleCommenter;

  /// No description provided for @sampleComment.
  ///
  /// In en, this message translates to:
  /// **'Smooth! No stutter at all when I swipe.'**
  String get sampleComment;

  /// No description provided for @contentTitle.
  ///
  /// In en, this message translates to:
  /// **'{style} content'**
  String contentTitle(String style);

  /// No description provided for @configTitle.
  ///
  /// In en, this message translates to:
  /// **'{style} configuration'**
  String configTitle(String style);

  /// No description provided for @savingRestartsFeed.
  ///
  /// In en, this message translates to:
  /// **'Saving restarts the feed.'**
  String get savingRestartsFeed;

  /// No description provided for @applyingRestartsFeed.
  ///
  /// In en, this message translates to:
  /// **'Applying restarts the feed.'**
  String get applyingRestartsFeed;

  /// No description provided for @videoUrlsLabel.
  ///
  /// In en, this message translates to:
  /// **'Video URLs, one per line'**
  String get videoUrlsLabel;

  /// No description provided for @playableSummary.
  ///
  /// In en, this message translates to:
  /// **'{valid} playable'**
  String playableSummary(int valid);

  /// No description provided for @playableSummarySkipped.
  ///
  /// In en, this message translates to:
  /// **'{valid} playable, {skipped} skipped (not http/https)'**
  String playableSummarySkipped(int valid, int skipped);

  /// No description provided for @addBrokenUrl.
  ///
  /// In en, this message translates to:
  /// **'Add a broken URL'**
  String get addBrokenUrl;

  /// No description provided for @resetToSamples.
  ///
  /// In en, this message translates to:
  /// **'Reset to samples'**
  String get resetToSamples;

  /// No description provided for @textPostsLabel.
  ///
  /// In en, this message translates to:
  /// **'Text posts, one per line'**
  String get textPostsLabel;

  /// No description provided for @textPostBeforeEvery.
  ///
  /// In en, this message translates to:
  /// **'A text post before every'**
  String get textPostBeforeEvery;

  /// No description provided for @nthVideo.
  ///
  /// In en, this message translates to:
  /// **'Nth video'**
  String get nthVideo;

  /// No description provided for @videosPerPage.
  ///
  /// In en, this message translates to:
  /// **'Videos per page'**
  String get videosPerPage;

  /// No description provided for @repeatTheList.
  ///
  /// In en, this message translates to:
  /// **'Repeat the list'**
  String get repeatTheList;

  /// No description provided for @repeatHint.
  ///
  /// In en, this message translates to:
  /// **'After this many passes the feed ends.'**
  String get repeatHint;

  /// No description provided for @repeatCount.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String repeatCount(int count);

  /// No description provided for @feedHoldsTotal.
  ///
  /// In en, this message translates to:
  /// **'The feed holds {count} videos in total.'**
  String feedHoldsTotal(int count);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @resetToPreset.
  ///
  /// In en, this message translates to:
  /// **'Reset to preset'**
  String get resetToPreset;

  /// No description provided for @decreaseField.
  ///
  /// In en, this message translates to:
  /// **'Decrease {label}'**
  String decreaseField(String label);

  /// No description provided for @increaseField.
  ///
  /// In en, this message translates to:
  /// **'Increase {label}'**
  String increaseField(String label);

  /// No description provided for @sectionWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get sectionWindow;

  /// No description provided for @sectionFastScrolling.
  ///
  /// In en, this message translates to:
  /// **'Fast scrolling'**
  String get sectionFastScrolling;

  /// No description provided for @sectionPagination.
  ///
  /// In en, this message translates to:
  /// **'Pagination'**
  String get sectionPagination;

  /// No description provided for @sectionMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get sectionMemory;

  /// No description provided for @sectionFailures.
  ///
  /// In en, this message translates to:
  /// **'Failures'**
  String get sectionFailures;

  /// No description provided for @fieldBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind'**
  String get fieldBehind;

  /// No description provided for @fieldAhead.
  ///
  /// In en, this message translates to:
  /// **'Ahead'**
  String get fieldAhead;

  /// No description provided for @fieldWindowSize.
  ///
  /// In en, this message translates to:
  /// **'Window size'**
  String get fieldWindowSize;

  /// No description provided for @fieldWindowSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Must exceed behind + ahead.'**
  String get fieldWindowSizeHint;

  /// No description provided for @fieldDirectionBias.
  ///
  /// In en, this message translates to:
  /// **'Direction bias'**
  String get fieldDirectionBias;

  /// No description provided for @fieldDirectionBiasHint.
  ///
  /// In en, this message translates to:
  /// **'Extra items toward the scroll direction.'**
  String get fieldDirectionBiasHint;

  /// No description provided for @fieldVelocityPreload.
  ///
  /// In en, this message translates to:
  /// **'Velocity preload'**
  String get fieldVelocityPreload;

  /// No description provided for @fieldVelocityPreloadHint.
  ///
  /// In en, this message translates to:
  /// **'Extra items for fast scrolling (needs a velocity).'**
  String get fieldVelocityPreloadHint;

  /// No description provided for @fieldConcurrentInits.
  ///
  /// In en, this message translates to:
  /// **'Concurrent initializations'**
  String get fieldConcurrentInits;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'unlimited'**
  String get unlimited;

  /// No description provided for @fieldScrollDebounce.
  ///
  /// In en, this message translates to:
  /// **'Scroll debounce'**
  String get fieldScrollDebounce;

  /// No description provided for @millisecondsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String millisecondsValue(int value);

  /// No description provided for @fieldJumpThreshold.
  ///
  /// In en, this message translates to:
  /// **'Jump threshold'**
  String get fieldJumpThreshold;

  /// No description provided for @fieldJumpThresholdHint.
  ///
  /// In en, this message translates to:
  /// **'A move this big skips the debounce.'**
  String get fieldJumpThresholdHint;

  /// No description provided for @fieldPaginationThreshold.
  ///
  /// In en, this message translates to:
  /// **'Pagination threshold'**
  String get fieldPaginationThreshold;

  /// No description provided for @fieldPaginationThresholdHint.
  ///
  /// In en, this message translates to:
  /// **'Load more when this few items remain.'**
  String get fieldPaginationThresholdHint;

  /// No description provided for @fieldAdaptive.
  ///
  /// In en, this message translates to:
  /// **'Adaptive'**
  String get fieldAdaptive;

  /// No description provided for @fieldAdaptiveHint.
  ///
  /// In en, this message translates to:
  /// **'Narrow by device tier and memory pressure.'**
  String get fieldAdaptiveHint;

  /// No description provided for @fieldDeviceTier.
  ///
  /// In en, this message translates to:
  /// **'Device tier'**
  String get fieldDeviceTier;

  /// No description provided for @fieldRetryPolicy.
  ///
  /// In en, this message translates to:
  /// **'Retry policy'**
  String get fieldRetryPolicy;

  /// No description provided for @tierAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect'**
  String get tierAuto;

  /// No description provided for @tierLow.
  ///
  /// In en, this message translates to:
  /// **'Force low'**
  String get tierLow;

  /// No description provided for @tierMid.
  ///
  /// In en, this message translates to:
  /// **'Force mid'**
  String get tierMid;

  /// No description provided for @tierHigh.
  ///
  /// In en, this message translates to:
  /// **'Force high'**
  String get tierHigh;

  /// No description provided for @retryExponential.
  ///
  /// In en, this message translates to:
  /// **'Exponential, 1 retry'**
  String get retryExponential;

  /// No description provided for @retryExponentialThree.
  ///
  /// In en, this message translates to:
  /// **'Exponential, 3 retries'**
  String get retryExponentialThree;

  /// No description provided for @retryFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed delay, 2 retries'**
  String get retryFixed;

  /// No description provided for @retryNone.
  ///
  /// In en, this message translates to:
  /// **'No retry'**
  String get retryNone;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get tabWindow;

  /// No description provided for @tabEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get tabEvents;

  /// No description provided for @tabControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get tabControls;

  /// No description provided for @eventsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} events'**
  String eventsCount(int count);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @legendNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'not loaded'**
  String get legendNotLoaded;

  /// No description provided for @legendInitializing.
  ///
  /// In en, this message translates to:
  /// **'initializing'**
  String get legendInitializing;

  /// No description provided for @legendReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get legendReady;

  /// No description provided for @legendFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get legendFailed;

  /// No description provided for @firstRetainedIndex.
  ///
  /// In en, this message translates to:
  /// **'first retained index'**
  String get firstRetainedIndex;

  /// No description provided for @activeIndex.
  ///
  /// In en, this message translates to:
  /// **'active index'**
  String get activeIndex;

  /// No description provided for @direction.
  ///
  /// In en, this message translates to:
  /// **'direction'**
  String get direction;

  /// No description provided for @videosLoaded.
  ///
  /// In en, this message translates to:
  /// **'videos loaded'**
  String get videosLoaded;

  /// No description provided for @rowsLoaded.
  ///
  /// In en, this message translates to:
  /// **'rows loaded'**
  String get rowsLoaded;

  /// No description provided for @tapCellToJump.
  ///
  /// In en, this message translates to:
  /// **'Tap a cell to jump there.'**
  String get tapCellToJump;

  /// No description provided for @statsWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get statsWindow;

  /// No description provided for @statsWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get statsWork;

  /// No description provided for @statsScrolling.
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get statsScrolling;

  /// No description provided for @statsEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get statsEnvironment;

  /// No description provided for @statsEnforced.
  ///
  /// In en, this message translates to:
  /// **'Enforced vs configured'**
  String get statsEnforced;

  /// No description provided for @statRetainedWindow.
  ///
  /// In en, this message translates to:
  /// **'retained / window size'**
  String get statRetainedWindow;

  /// No description provided for @statReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get statReady;

  /// No description provided for @statInitializing.
  ///
  /// In en, this message translates to:
  /// **'initializing'**
  String get statInitializing;

  /// No description provided for @statFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get statFailed;

  /// No description provided for @statQueued.
  ///
  /// In en, this message translates to:
  /// **'queued for a slot'**
  String get statQueued;

  /// No description provided for @statInitsStarted.
  ///
  /// In en, this message translates to:
  /// **'initializations started'**
  String get statInitsStarted;

  /// No description provided for @statSucceeded.
  ///
  /// In en, this message translates to:
  /// **'succeeded'**
  String get statSucceeded;

  /// No description provided for @statFailedAttempts.
  ///
  /// In en, this message translates to:
  /// **'failed attempts'**
  String get statFailedAttempts;

  /// No description provided for @statRetried.
  ///
  /// In en, this message translates to:
  /// **'retried'**
  String get statRetried;

  /// No description provided for @statDropped.
  ///
  /// In en, this message translates to:
  /// **'dropped before starting'**
  String get statDropped;

  /// No description provided for @statReleased.
  ///
  /// In en, this message translates to:
  /// **'controllers released'**
  String get statReleased;

  /// No description provided for @statScrolls.
  ///
  /// In en, this message translates to:
  /// **'scrolls that took effect'**
  String get statScrolls;

  /// No description provided for @statPoolHit.
  ///
  /// In en, this message translates to:
  /// **'pool hit rate'**
  String get statPoolHit;

  /// No description provided for @statAvgInit.
  ///
  /// In en, this message translates to:
  /// **'avg init'**
  String get statAvgInit;

  /// No description provided for @statP95Init.
  ///
  /// In en, this message translates to:
  /// **'p95 init'**
  String get statP95Init;

  /// No description provided for @statDeviceTier.
  ///
  /// In en, this message translates to:
  /// **'device tier'**
  String get statDeviceTier;

  /// No description provided for @statMemoryPressure.
  ///
  /// In en, this message translates to:
  /// **'memory pressure'**
  String get statMemoryPressure;

  /// No description provided for @statPagination.
  ///
  /// In en, this message translates to:
  /// **'pagination'**
  String get statPagination;

  /// No description provided for @paginationReachedEnd.
  ///
  /// In en, this message translates to:
  /// **'reached the end'**
  String get paginationReachedEnd;

  /// No description provided for @paginationMoreAvailable.
  ///
  /// In en, this message translates to:
  /// **'more available'**
  String get paginationMoreAvailable;

  /// No description provided for @statBehindAhead.
  ///
  /// In en, this message translates to:
  /// **'behind / ahead'**
  String get statBehindAhead;

  /// No description provided for @statWindow.
  ///
  /// In en, this message translates to:
  /// **'window'**
  String get statWindow;

  /// No description provided for @statConcurrentInits.
  ///
  /// In en, this message translates to:
  /// **'concurrent inits'**
  String get statConcurrentInits;

  /// No description provided for @withConfig.
  ///
  /// In en, this message translates to:
  /// **'{value}   (config {config})'**
  String withConfig(String value, String config);

  /// No description provided for @controlsMemoryPressure.
  ///
  /// In en, this message translates to:
  /// **'Memory pressure'**
  String get controlsMemoryPressure;

  /// No description provided for @memoryPressureHint.
  ///
  /// In en, this message translates to:
  /// **'Shrinking is immediate. Choosing a milder level grows the window back one level at a time.'**
  String get memoryPressureHint;

  /// No description provided for @pressureNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get pressureNone;

  /// No description provided for @pressureModerate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get pressureModerate;

  /// No description provided for @pressureCritical.
  ///
  /// In en, this message translates to:
  /// **'critical'**
  String get pressureCritical;

  /// No description provided for @controlsScrolling.
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get controlsScrolling;

  /// No description provided for @flickForward.
  ///
  /// In en, this message translates to:
  /// **'Flick ×10 forward'**
  String get flickForward;

  /// No description provided for @flickBack.
  ///
  /// In en, this message translates to:
  /// **'Flick ×10 back'**
  String get flickBack;

  /// No description provided for @jumpFirst.
  ///
  /// In en, this message translates to:
  /// **'Jump to first'**
  String get jumpFirst;

  /// No description provided for @jumpMiddle.
  ///
  /// In en, this message translates to:
  /// **'Jump to middle'**
  String get jumpMiddle;

  /// No description provided for @jumpLast.
  ///
  /// In en, this message translates to:
  /// **'Jump to last loaded'**
  String get jumpLast;

  /// No description provided for @flickHint.
  ///
  /// In en, this message translates to:
  /// **'A flick steps one video every 40 ms: watch the debounce collapse it, and \"dropped before starting\" climb.'**
  String get flickHint;

  /// No description provided for @controlsFailures.
  ///
  /// In en, this message translates to:
  /// **'Failures'**
  String get controlsFailures;

  /// No description provided for @failNextPage.
  ///
  /// In en, this message translates to:
  /// **'Fail the next page request'**
  String get failNextPage;

  /// No description provided for @failNextPageHint.
  ///
  /// In en, this message translates to:
  /// **'Exercises pagination backoff.'**
  String get failNextPageHint;

  /// No description provided for @retryAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry every failed video'**
  String get retryAllFailed;

  /// No description provided for @failuresHint.
  ///
  /// In en, this message translates to:
  /// **'Add a broken URL in \"Edit content\" to see retries and failure states.'**
  String get failuresHint;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
