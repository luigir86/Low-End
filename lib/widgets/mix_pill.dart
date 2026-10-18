import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../l10n/app_localizations.dart';
import 'pill_switch.dart';

/// What can sound: nothing, the metronome, the harmony, or both.
enum Mix { metronome, both, drone }

/// The third row of the metronome and the harmony, the same on both: a pill
/// with three parts, Metronome | Both | Harmony, that shows what plays and
/// chooses it. Nothing is lit while nothing plays; touching a part plays what
/// it says (and stops what it does not), and touching the lit one stops
/// everything. It keeps no state of its own: it reads the two players.
class MixPill extends StatelessWidget {
  const MixPill({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AudioScope.of(context);
    final metronome = scope.metronome;
    final drone = scope.drone;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([metronome, drone]),
      builder: (context, _) {
        final current = switch ((metronome.isPlaying, drone.isPlaying)) {
          (true, true) => Mix.both,
          (true, false) => Mix.metronome,
          (false, true) => Mix.drone,
          (false, false) => null,
        };
        void choose(Mix mix) {
          if (mix == current) {
            metronome.stop();
            drone.stop();
            return;
          }
          // Stops what is not asked for first; the harmony starts before the
          // click, which then comes in on its bar line.
          if (mix == Mix.drone) metronome.stop();
          if (mix == Mix.metronome) drone.stop();
          if (mix != Mix.metronome) drone.start();
          if (mix != Mix.drone) metronome.start();
        }

        Widget part(
          Mix mix,
          String name, {
          required Widget Function(Widget) wrap,
          Key? key,
        }) {
          final selected = current == mix;
          return wrap(
            Semantics(
              button: true,
              selected: selected,
              label: name,
              excludeSemantics: true,
              onTap: () => choose(mix),
              child: InkWell(
                key: key,
                onTap: () => choose(mix),
                child: PillSwitch.label(
                  context,
                  selected,
                  Text(name, maxLines: 1),
                ),
              ),
            ),
          );
        }

        return Semantics(
          label: l10n.mixLabel,
          container: true,
          child: PillSwitch(
            key: const Key('mixPill'),
            leftFilled: current == Mix.metronome,
            middleFilled: current == Mix.both,
            rightFilled: current == Mix.drone,
            left: part(
              Mix.metronome,
              l10n.metronomeTab,
              key: const Key('mixMetronome'),
              wrap: (child) => PillSwitch.half(left: true, child: child),
            ),
            middle: part(
              Mix.both,
              l10n.mixBoth,
              key: const Key('mixBoth'),
              wrap: (child) => PillSwitch.middleHalf(child: child),
            ),
            right: part(
              Mix.drone,
              l10n.harmonyTab,
              key: const Key('mixDrone'),
              wrap: (child) => PillSwitch.half(left: false, child: child),
            ),
          ),
        );
      },
    );
  }
}
