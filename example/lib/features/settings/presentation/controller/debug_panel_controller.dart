import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ticks on an interval so the debug panel re-reads the live counters.
///
/// Counters such as the queue length change without any state change the feed
/// would notify about, so the panel polls instead of only listening.
class DebugPanelController extends ChangeNotifier {
  /// Starts ticking every [refreshEvery].
  DebugPanelController({
    Duration refreshEvery = const Duration(milliseconds: 300),
  }) {
    _timer = Timer.periodic(refreshEvery, (Timer _) => notifyListeners());
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
