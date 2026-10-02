import 'package:flutter/widgets.dart';
import 'package:video_flux/video_flux.dart';

import '../features/feed/data/enums/feed_style.dart';
import '../features/settings/data/enums/retry_choice.dart';
import '../features/settings/data/enums/tier_choice.dart';
import 'app_localizations.dart';

/// Shortcut to the current [AppLocalizations].
extension AppLocalizationsContext on BuildContext {
  /// The strings for the locale in effect.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Display text for a [FeedStyle].
extension FeedStyleL10n on FeedStyle {
  /// Full name, as used in headings.
  String title(AppLocalizations l10n) => switch (this) {
        FeedStyle.facebook => l10n.styleFacebookTitle,
        FeedStyle.tikTok => l10n.styleTikTokTitle,
        FeedStyle.shorts => l10n.styleShortsTitle,
        FeedStyle.stories => l10n.styleStoriesTitle,
      };

  /// A label short enough for the style toggle.
  String shortTitle(AppLocalizations l10n) => switch (this) {
        FeedStyle.facebook => l10n.styleFacebook,
        FeedStyle.tikTok => l10n.styleTikTok,
        FeedStyle.shorts => l10n.styleShorts,
        FeedStyle.stories => l10n.styleStories,
      };

  /// One-line description of the feed shape.
  String summary(AppLocalizations l10n) => switch (this) {
        FeedStyle.facebook => l10n.styleFacebookSummary,
        FeedStyle.tikTok => l10n.styleTikTokSummary,
        FeedStyle.shorts => l10n.styleShortsSummary,
        FeedStyle.stories => l10n.styleStoriesSummary,
      };
}

/// Display text for a [RetryChoice].
extension RetryChoiceL10n on RetryChoice {
  /// Name shown in the UI.
  String label(AppLocalizations l10n) => switch (this) {
        RetryChoice.exponential => l10n.retryExponential,
        RetryChoice.exponentialThree => l10n.retryExponentialThree,
        RetryChoice.fixed => l10n.retryFixed,
        RetryChoice.none => l10n.retryNone,
      };
}

/// Display text for a [TierChoice].
extension TierChoiceL10n on TierChoice {
  /// Name shown in the UI.
  String label(AppLocalizations l10n) => switch (this) {
        TierChoice.auto => l10n.tierAuto,
        TierChoice.low => l10n.tierLow,
        TierChoice.mid => l10n.tierMid,
        TierChoice.high => l10n.tierHigh,
      };
}

/// Display text for a [MemoryPressureLevel].
extension MemoryPressureLevelL10n on MemoryPressureLevel {
  /// Name shown in the UI.
  String label(AppLocalizations l10n) => switch (this) {
        MemoryPressureLevel.none => l10n.pressureNone,
        MemoryPressureLevel.moderate => l10n.pressureModerate,
        MemoryPressureLevel.critical => l10n.pressureCritical,
      };
}
