import 'package:flutter/material.dart';
import '../../../../l10n/l10n_extensions.dart';

/// A labelled integer with minus and plus buttons.
class StepperField extends StatelessWidget {
  /// Creates a stepper for [value] between [min] and [max].
  const StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.format,
    this.hint,
    super.key,
  });

  /// What the value controls.
  final String label;

  /// The current value.
  final int value;

  /// Smallest allowed value.
  final int min;

  /// Largest allowed value.
  final int max;

  /// Amount each press changes the value by.
  final int step;

  /// Turns the value into display text; defaults to the number itself.
  final String Function(int value)? format;

  /// A short explanation shown under the label.
  final String? hint;

  /// Called with the new value.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label),
        subtitle: hint == null ? null : Text(hint!),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: context.l10n.decreaseField(label),
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min
                  ? () => onChanged((value - step).clamp(min, max))
                  : null,
            ),
            SizedBox(
              width: 72,
              child: Text(
                format?.call(value) ?? '$value',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: context.l10n.increaseField(label),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max
                  ? () => onChanged((value + step).clamp(min, max))
                  : null,
            ),
          ],
        ),
      );
}
