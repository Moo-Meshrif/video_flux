import 'package:flutter/material.dart';

/// One label/value line in the debug panel.
class DebugRow extends StatelessWidget {
  /// Creates a row showing [value] next to [label].
  const DebugRow({required this.label, required this.value, super.key});

  /// What is being shown.
  final String label;

  /// Its current value.
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white60)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

/// A heading that separates groups of [DebugRow]s.
class DebugHeading extends StatelessWidget {
  /// Creates a heading with [text].
  const DebugHeading(this.text, {super.key});

  /// The heading text.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1,
              ),
        ),
      );
}
