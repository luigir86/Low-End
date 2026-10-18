import 'package:flutter/material.dart';

/// The pieces of the row of controls under a dial, shared by the metronome,
/// the harmony and the tuner so that the three look the same: a field with
/// its name on the border, round-cornered chips (like +7) and a plain icon
/// button in the primary colour (like the sound options).

/// A field in the style of the chord menu: its [label] written on the
/// border, the current [value] inside, a caret to say a touch opens a
/// choice. With [showLabel] false the border stays bare, as for the time
/// signature, where "4/4" says it all; the [label] is still what a screen
/// reader announces.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.showLabel = true,
  });

  final String label;
  final bool showLabel;
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
            labelText: showLabel ? label : null,
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

/// The height of a line of text in a row, and the padding above and below
/// the label of a chip that makes a chip as tall as the field beside it (a
/// line, 16 dp of padding on both sides, and the border).
const rowLineHeight = 24.0;
const chipPadding = 15.0;

/// A chip of the row: "+7" on the harmony, TAP, − and + on the metronome.
/// With [onPressed] null it is dimmed (the end of a range). With [filled]
/// it is coloured in the container colour, to say that it is a button to
/// press (TAP), unlike the chips that only show a value.
class RowChip extends StatelessWidget {
  const RowChip({
    super.key,
    required this.label,
    this.tooltip,
    this.onPressed,
    this.filled = false,
  });

  final Widget label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => ActionChip(
    // At least as tall as a line of text, so that an icon chip grows with
    // large text as the field beside it does.
    label: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.textScalerOf(context).scale(rowLineHeight),
      ),
      child: Center(widthFactor: 1, child: label),
    ),
    tooltip: tooltip,
    onPressed: onPressed,
    backgroundColor: filled
        ? Theme.of(context).colorScheme.primaryContainer
        : null,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: chipPadding),
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

/// The button at the end of the row (the pencil, the sound options): boxed
/// like the chips beside it, with its icon in the ink of their text (the
/// borders carry the tab's colour), so that the row is a line of equal
/// blocks. The gap before it is its own.
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 4),
    child: RowChip(
      label: Icon(
        icon,
        size: 24,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}
