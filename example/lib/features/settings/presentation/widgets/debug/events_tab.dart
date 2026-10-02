import 'package:flutter/material.dart';

import '../../../../feed/presentation/controller/feed_controller.dart';
import '../../controller/event_description.dart';
import '../../../../../l10n/l10n_extensions.dart';

/// The live `VideoFlux.events` stream, newest first.
class EventsTab extends StatelessWidget {
  /// Creates the tab for [feed].
  const EventsTab({required this.feed, super.key});

  /// The feed being inspected.
  final FeedController feed;

  static String _timestamp(Duration at) {
    final String seconds = at.inSeconds.toString().padLeft(3, '0');
    final String millis = (at.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: feed.eventRevision,
        builder: (BuildContext context, int revision, Widget? child) {
          final List<LoggedEvent> log = feed.eventLog;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    Text(context.l10n.eventsCount(log.length)),
                    const Spacer(),
                    TextButton(
                      onPressed: feed.clearEventLog,
                      child: Text(context.l10n.clear),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: log.length,
                  itemBuilder: (BuildContext context, int index) {
                    final LoggedEvent entry = log[log.length - 1 - index];
                    final ({String text, Color color}) description =
                        describeEvent(entry.event);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(
                              text: '${_timestamp(entry.at)}  ',
                              style: const TextStyle(color: Colors.white38),
                            ),
                            TextSpan(
                              text: description.text,
                              style: TextStyle(color: description.color),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
}
