import 'package:flutter/foundation.dart';

import '../../data/models/feed_setup.dart';
import '../../data/enums/feed_style.dart';
import '../../data/repositories/feed_setup_repository.dart';

/// Exposes every feed style's setup to the UI and announces changes.
///
/// A change restarts the feed it belongs to, because a preloader's
/// configuration is fixed when it is created.
class FeedSetupController extends ChangeNotifier {
  /// Creates a controller over [repository].
  FeedSetupController(this._repository);

  final FeedSetupRepository _repository;

  /// The setup currently applied to [style].
  FeedSetup setupOf(FeedStyle style) => _repository.setupOf(style);

  /// Replaces the setup of [style] and restarts its feed.
  void update(FeedStyle style, FeedSetup setup) {
    _repository.update(style, setup);
    notifyListeners();
  }

  /// Restores the starting setup of [style].
  void reset(FeedStyle style) {
    _repository.reset(style);
    notifyListeners();
  }
}
