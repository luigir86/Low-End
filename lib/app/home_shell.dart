import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/tuner_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pulsing_dot.dart';
import 'about.dart';
import 'app_navigation.dart';
import 'now_playing_strip.dart';

/// Main screen with bottom navigation between the app's sections.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const _screens = [TunerScreen(), MetronomeScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final scope = AudioScope.of(context);
    final drone = scope.drone;
    final navigation = scope.navigation;
    return ListenableBuilder(
      listenable: Listenable.merge([drone, navigation]),
      builder: (context, _) {
        final index = navigation.section == AppSection.metronome ? 1 : 0;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: l10n.aboutTooltip,
                onPressed: () => showLowEndAbout(context),
              ),
            ],
          ),
          body: IndexedStack(index: index, children: _screens),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NowPlayingStrip(
                sounds: [
                  if (drone.isPlaying)
                    ActiveSound(
                      icon: Icons.graphic_eq,
                      label: l10n.droneNowPlaying(drone.note.label(language)),
                      onStop: drone.stop,
                    ),
                ],
              ),
              NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => i == 0
                    ? navigation.openTunerTab()
                    : navigation.open(AppSection.metronome),
                destinations: [
                  NavigationDestination(
                    icon: ActivityIcon(
                      icon: Icons.graphic_eq,
                      active: drone.isPlaying,
                    ),
                    label: l10n.tunerTab,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.timer_outlined),
                    label: l10n.metronomeTab,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
