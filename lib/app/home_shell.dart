import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/drone/drone_panel.dart';
import '../features/tuner/tuner_panel.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pulsing_dot.dart';
import 'app_navigation.dart';
import 'now_playing_strip.dart';
import 'settings_page.dart';

/// Main screen with bottom navigation between the app's sections.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  /// One per [AppSection], in the same order.
  static const _screens = [TunerPanel(), DronePanel(), MetronomeScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AudioScope.of(context);
    final drone = scope.drone;
    final navigation = scope.navigation;
    return ListenableBuilder(
      listenable: Listenable.merge([drone, navigation, scope.settings]),
      builder: (context, _) {
        final names = scope.settings.noteNames(Localizations.localeOf(context));
        final section = navigation.section;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.settingsTitle,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                ),
              ),
            ],
          ),
          body: IndexedStack(index: section.index, children: _screens),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NowPlayingStrip(
                sounds: [
                  // On the Drone tab the lit key already says it.
                  if (drone.isPlaying && section != AppSection.drone)
                    ActiveSound(
                      icon: Icons.graphic_eq,
                      label: l10n.droneNowPlaying(drone.note.label(names)),
                      onStop: drone.stop,
                    ),
                ],
              ),
              NavigationBar(
                selectedIndex: section.index,
                onDestinationSelected: (i) =>
                    navigation.open(AppSection.values[i]),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.tune),
                    label: l10n.tunerTab,
                  ),
                  NavigationDestination(
                    icon: ActivityIcon(
                      icon: Icons.graphic_eq,
                      active: drone.isPlaying,
                    ),
                    label: l10n.droneMode,
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
