import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/placeholder_section.dart';
import 'drone/drone_panel.dart';

enum _TunerMode { tune, drone }

/// Tuner section, with the drone as its second mode.
class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  var _mode = _TunerMode.tune;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<_TunerMode>(
            segments: [
              ButtonSegment(
                value: _TunerMode.tune,
                label: Text(l10n.tuneMode),
                icon: const Icon(Icons.tune),
              ),
              ButtonSegment(
                value: _TunerMode.drone,
                label: Text(l10n.droneMode),
                icon: const Icon(Icons.graphic_eq),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        Expanded(
          child: switch (_mode) {
            _TunerMode.tune => PlaceholderSection(
              icon: Icons.tune,
              description: l10n.tunerDescription,
            ),
            _TunerMode.drone => const DronePanel(),
          },
        ),
      ],
    );
  }
}
