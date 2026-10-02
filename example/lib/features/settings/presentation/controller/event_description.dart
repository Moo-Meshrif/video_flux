import 'package:flutter/material.dart';
import 'package:video_flux/video_flux.dart';

/// A one-line, colour-coded description of a [VideoFluxEvent].
///
/// The switch is exhaustive over the sealed hierarchy: adding an event to the
/// package makes this stop compiling until it is described here.
({String text, Color color}) describeEvent(VideoFluxEvent event) =>
    switch (event) {
      ScrollSelected(:final index, :final wasReady) => (
          text: 'scroll → #$index ${wasReady ? '(hit)' : '(miss)'}',
          color: wasReady ? Colors.lightGreenAccent : Colors.orangeAccent,
        ),
      InitializationStarted(:final index, :final attempt) => (
          text: 'init start #$index (attempt $attempt)',
          color: Colors.lightBlueAccent,
        ),
      ControllerReady(:final index, :final duration) => (
          text: 'ready #$index in ${duration.inMilliseconds} ms',
          color: Colors.greenAccent,
        ),
      InitializationFailed(:final index, :final attempt, :final retryDelay) => (
          text: 'init failed #$index (attempt $attempt) — '
              '${retryDelay == null ? 'giving up' : 'retry in '
                  '${retryDelay.inMilliseconds} ms'}',
          color: Colors.redAccent,
        ),
      InitializationCancelled(:final index) => (
          text: 'init dropped #$index (left the window while queued)',
          color: Colors.blueGrey,
        ),
      ControllerReleased(:final index) => (
          text: 'released #$index',
          color: Colors.grey,
        ),
      PressureChanged(:final level) => (
          text: 'memory pressure → ${level.name}',
          color: Colors.deepOrangeAccent,
        ),
      LimitsChanged(:final limits) => (
          text: 'limits → $limits',
          color: Colors.amberAccent,
        ),
      ItemsReplaced(:final itemCount, :final retained, :final released) => (
          text: 'feed replaced: $itemCount items, '
              'kept $retained, released $released',
          color: Colors.purpleAccent,
        ),
      PaginationCompleted(:final itemCount) => (
          text: 'page loaded: +$itemCount videos',
          color: Colors.tealAccent,
        ),
      PaginationEnded() => (
          text: 'pagination ended (empty page)',
          color: Colors.tealAccent,
        ),
      PaginationFailed(:final retryAfter) => (
          text: 'pagination failed — paused ${retryAfter.inMilliseconds} ms',
          color: Colors.redAccent,
        ),
    };
