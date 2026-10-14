import 'package:flutter/material.dart';

import '../features/library/library_screen.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/tuner_screen.dart';
import '../l10n/app_localizations.dart';

/// Main screen with bottom navigation between the app's sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [TunerScreen(), MetronomeScreen(), LibraryScreen()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.graphic_eq),
            label: l10n.tunerTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            label: l10n.metronomeTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            label: l10n.libraryTab,
          ),
        ],
      ),
    );
  }
}
