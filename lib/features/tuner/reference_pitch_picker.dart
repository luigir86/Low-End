import 'package:flutter/material.dart';

import '../../audio/pitch.dart';
import '../../l10n/app_localizations.dart';
import 'drone/drone_controller.dart';

/// Row with the reference A, shared by the tuner and the drone so both agree
/// on the same pitch.
class ReferencePitchPicker extends StatelessWidget {
  const ReferencePitchPicker({super.key, required this.drone});

  final DroneController drone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.referencePitch,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        // Screen readers would otherwise announce only "440 Hz".
        Semantics(
          label: l10n.referencePitch,
          child: DropdownButton<double>(
            value: drone.a4,
            items: [
              for (final hz in referencePitches)
                DropdownMenuItem(value: hz, child: Text('${hz.round()} Hz')),
            ],
            onChanged: (hz) => drone.setReferencePitch(hz!),
          ),
        ),
      ],
    );
  }
}
