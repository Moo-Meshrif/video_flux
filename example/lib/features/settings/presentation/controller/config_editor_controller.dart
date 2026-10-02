import 'package:flutter/foundation.dart';
import 'package:video_flux/video_flux.dart';

import '../../../feed/data/enums/feed_style.dart';
import '../../../feed/presentation/controller/feed_setup_controller.dart';
import '../../data/models/config_draft.dart';

/// The state behind the configuration editor: a draft and its validation.
///
/// Validation is the package's own, so an invalid combination is reported with
/// the message a real app would see.
class ConfigEditorController extends ChangeNotifier {
  /// Starts editing the configuration of [style].
  ConfigEditorController({required this.style, required this.setups})
      : draft = ConfigDraft.from(setups.setupOf(style).config);

  /// The feed style being configured.
  final FeedStyle style;

  /// Where the feed style's setup lives.
  final FeedSetupController setups;

  /// The values being edited.
  ConfigDraft draft;

  /// Why the last apply was rejected, or null.
  String? error;

  /// Runs [change] on the draft and clears any previous error.
  void edit(VoidCallback change) {
    change();
    error = null;
    notifyListeners();
  }

  /// Replaces the draft with the starting configuration of the feed style.
  void resetToPreset() =>
      edit(() => draft = ConfigDraft.from(style.defaultConfig));

  /// Applies the draft, which restarts the feed; returns whether it was valid.
  bool apply() {
    final VideoFluxConfig config = draft.toConfig();
    try {
      config.validate();
    } on ArgumentError catch (exception) {
      error = exception.message.toString();
      notifyListeners();
      return false;
    }
    setups.update(style, setups.setupOf(style).copyWith(config: config));
    return true;
  }
}
