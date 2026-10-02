part of '../video_flux.dart';

/// Resolving the enforced limits, and reacting to memory pressure.
extension _LimitsAndPressure<T extends VideoFluxItem> on VideoFlux<T> {
  VideoFluxLimits _resolveLimits() => VideoFluxLimits.resolve(
        config: _config,
        tier: _deviceTier,
        pressure: _pressure,
      );

  /// Re-resolves the limits; returns whether they changed.
  bool _refreshLimits() {
    final VideoFluxLimits next = _resolveLimits();
    if (next == _limits) {
      return false;
    }
    _limits = next;
    _notify(LimitsChanged(next));
    _pumpInitializations();
    return true;
  }

  Future<void> _reconcileToLimits() {
    if (_isDisposed || _items.isEmpty) {
      return Future<void>.value();
    }
    return _reconcileWindow(
      _activeIndex < 0 ? 0 : _activeIndex,
      _preloadDirection,
      0,
    );
  }

  void _applyPressure(MemoryPressureLevel level) {
    _pressureRecoveryTimer?.cancel();
    _pressure = level;
    _notify(PressureChanged(level));
    if (_refreshLimits()) {
      unawaited(_enqueue(_reconcileToLimits));
    }
    _scheduleRecovery();
  }

  /// Steps pressure back toward the requested level, one level per period.
  void _scheduleRecovery() {
    _pressureRecoveryTimer?.cancel();
    _pressureRecoveryTimer = null;
    if (_pressure.index <= _pressureTarget.index) {
      return;
    }
    _pressureRecoveryTimer = Timer(_config.pressureRecoveryDuration, () {
      if (!_isDisposed) {
        _applyPressure(MemoryPressureLevel.values[_pressure.index - 1]);
      }
    });
  }
}
