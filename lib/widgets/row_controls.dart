import 'package:flutter/material.dart';

import '../app/style.dart';

/// The pieces of the row of controls under a dial, shared by the metronome,
/// the harmony and the tuner so that the three look the same: a field with
/// its name on the border, round-cornered chips (like +7) and a plain icon
/// button in the primary colour (like the sound options).

/// A field in the style of the chord menu: its [label] written on the
/// border, the current [value] inside, a caret to say a touch opens a
/// choice.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      value: value,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.fromLTRB(12, 16, 4, 16),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 24,
            ),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

/// A chip of the row: "+7" on the harmony, TAP, − and + on the metronome.
/// With [onPressed] null it is dimmed (the end of a range).
class RowChip extends StatelessWidget {
  const RowChip({super.key, required this.label, this.tooltip, this.onPressed});

  final Widget label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: label,
    tooltip: tooltip,
    onPressed: onPressed,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    side: BorderSide(
      color: Theme.of(context).colorScheme.outline
          .withValues(alpha: onPressed == null ? 0.4 : 1),
    ),
  );
}

/// The text of a [RowChip]: bold, the size of a body.
TextStyle? rowChipStyle(BuildContext context, {Color? color}) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );

/// The icon button at the end of the row: the pencil, the sound options.
class RowIconButton extends StatelessWidget {
  const RowIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    iconSize: 28,
    // At least 48 dp wide and high, to be touched with a thumb.
    constraints: BoxConstraints.tightFor(
      width: LowEndShape.iconButton,
      height: LowEndShape.iconButton,
    ),
    color: Theme.of(context).colorScheme.primary,
    icon: Icon(icon),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}
