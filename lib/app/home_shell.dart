import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Swiping moves between the sections; a tap on a tab or an action link
  /// moves the page to match.
  final _pages = PageController();

  /// True while the page slides to a section chosen elsewhere, so that the
  /// sections it crosses are not opened one after the other.
  var _sliding = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _showSection(AppSection section) async {
    if (!_pages.hasClients) return;
    final page = _pages.page?.round() ?? 0;
    if (page == section.index) return;
    _sliding = true;
    try {
      await _pages.animateToPage(
        section.index,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } finally {
      _sliding = false;
    }
  }

  /// Starts or stops what a tab plays, on a long press.
  void _toggle(AppSection section) {
    final scope = AudioScope.of(context);
    HapticFeedback.mediumImpact();
    switch (section) {
      case AppSection.metronome:
        scope.metronome.toggle();
      case AppSection.drone:
        scope.drone.toggle();
      case AppSection.tuner:
        break;
    }
  }

  Widget _tab(AppSection section, Widget destination) {
    final l10n = AppLocalizations.of(context);
    if (section == AppSection.tuner) return destination;
    return Semantics(
      onLongPressHint: l10n.holdToToggle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _toggle(section),
        child: destination,
      ),
    );
  }

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSection(navigation.section);
        });
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
          body: PageView(
            controller: _pages,
            onPageChanged: (i) {
              if (!_sliding) navigation.open(AppSection.values[i]);
            },
            children: [for (final s in _screens) _KeepAlive(child: s)],
          ),
          // Each section starts and stops its own sound; the pulsing dot on
          // a tab says which ones are playing.
          bottomNavigationBar: NavigationBar(
            selectedIndex: section.index,
            onDestinationSelected: (i) => navigation.open(AppSection.values[i]),
            // In the order of AppSection.
            destinations: [
              _tab(
                AppSection.metronome,
                NavigationDestination(
                  icon: ActivityIcon(
                    icon: Icons.timer_outlined,
                    active: metronome.isPlaying,
                  ),
                  label: l10n.metronomeTab,
                  // No tooltip: holding the tab starts and stops it instead.
                  tooltip: '',
                ),
              ),
              _tab(
                AppSection.drone,
                NavigationDestination(
                  icon: ActivityIcon(
                    icon: Icons.graphic_eq,
                    active: drone.isPlaying,
                  ),
                  label: l10n.droneMode,
                  tooltip: '',
                ),
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

/// Keeps a section alive while it is off screen (its state, and the
/// microphone and sound it manages, must not restart on every swipe).
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
