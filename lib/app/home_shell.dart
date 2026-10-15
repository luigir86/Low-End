import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/drone/drone_panel.dart';
import '../features/tuner/tuner_panel.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pulsing_dot.dart';
import 'app_navigation.dart';
import 'settings_page.dart';

/// Main screen with bottom navigation between the app's sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// One per [AppSection], in the same order.
  static const _screens = [MetronomeScreen(), DronePanel(), TunerPanel()];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The settings page or a dialog on top hides the tuner, and the
    // microphone must stop with it (see AppNavigation.tunerVisible).
    final route = ModalRoute.of(context);
    final navigation = AudioScope.of(context).navigation;
    // Not while building, since the tuner's own widgets listen to the
    // change; read again then, in case the page came and went meanwhile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) navigation.setCovered(!(route?.isCurrent ?? true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AudioScope.of(context);
    final drone = scope.drone;
    final metronome = scope.metronome;
    final navigation = scope.navigation;
    return ListenableBuilder(
      listenable: Listenable.merge([drone, metronome, navigation]),
      builder: (context, _) {
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
          // Each section starts and stops its own sound; the pulsing dot on
          // a tab says which ones are playing.
          bottomNavigationBar: NavigationBar(
            selectedIndex: section.index,
            onDestinationSelected: (i) => navigation.open(AppSection.values[i]),
            // In the order of AppSection.
            destinations: [
              NavigationDestination(
                icon: ActivityIcon(
                  icon: Icons.timer_outlined,
                  active: metronome.isPlaying,
                ),
                label: l10n.metronomeTab,
              ),
              NavigationDestination(
                icon: ActivityIcon(
                  icon: Icons.graphic_eq,
                  active: drone.isPlaying,
                ),
                label: l10n.droneMode,
              ),
              NavigationDestination(
                icon: const Icon(Icons.tune),
                label: l10n.tunerTab,
              ),
            ],
          ),
        );
      },
    );
  }
}
