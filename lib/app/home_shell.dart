import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/tuner_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pulsing_dot.dart';
import 'now_playing_strip.dart';

/// Main screen with bottom navigation between the app's sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [TunerScreen(), MetronomeScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final drone = AudioScope.of(context).drone;
    return ListenableBuilder(
      listenable: drone,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: IndexedStack(index: _index, children: _screens),
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
              selectedIndex: _index,
              onDestinationSelected: (i) {
                // The microphone only listens while the tuner is on screen.
                if (i != 0) AudioScope.of(context).tuner.stop();
                setState(() => _index = i);
              },
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
      ),
    );
  }
}
