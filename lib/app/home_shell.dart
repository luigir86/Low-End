import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_scope.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/tuner/drone/drone_panel.dart';
import '../features/tuner/tuner_panel.dart';
import '../l10n/app_localizations.dart';
import '../widgets/pulsing_dot.dart';
import 'app_navigation.dart';
import 'guide.dart';
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
  void initState() {
    super.initState();
    // The first time, the guide to the gestures.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = AudioScope.of(context).settings;
      if (settings.seenGuide) return;
      settings.markGuideSeen();
      showGuide(context);
    });
  }

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

  /// The hint shown over a tab after holding it, one per section.
  final _hints = {
    for (final s in AppSection.values) s: GlobalKey<TooltipState>(),
  };

  /// Starts or stops what a tab plays, on a long press. On the tuner, while
  /// the microphone listens, it only stops: the tuner pauses the sound so
  /// as to hear the bass, and holding a tab must not undo that unseen.
  void _toggle(AppSection section) {
    final scope = AudioScope.of(context);
    final playing = switch (section) {
      AppSection.metronome => scope.metronome.isPlaying,
      AppSection.drone => scope.drone.isPlaying,
      AppSection.tuner => true,
    };
    final listening =
        scope.navigation.section == AppSection.tuner && scope.tuner.isListening;
    if (listening && !playing) return;
    HapticFeedback.mediumImpact();
    switch (section) {
      case AppSection.metronome:
        scope.metronome.toggle();
      case AppSection.drone:
        scope.drone.toggle();
      case AppSection.tuner:
        break;
    }
    // Says what holding does, also to those who found it by chance.
    _hints[section]?.currentState?.ensureTooltipVisible();
  }

  Widget _tab(AppSection section, Widget destination, {required bool active}) {
    final l10n = AppLocalizations.of(context);
    if (section == AppSection.tuner) {
      // Holding does nothing here, but the tab still says it is listening.
      return Semantics(value: active ? l10n.playing : null, child: destination);
    }
    return Semantics(
      onLongPressHint: l10n.holdToToggle,
      // Screen readers hear it too, with the tab's name.
      value: active ? l10n.playing : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _toggle(section),
        // Shown only after a hold (the hold itself is the shortcut): a
        // tooltip of its own would take the long press away from it.
        child: Tooltip(
          key: _hints[section],
          message: l10n.holdToToggle,
          triggerMode: TooltipTriggerMode.manual,
          excludeFromSemantics: true,
          preferBelow: false,
          verticalOffset: 42,
          child: destination,
        ),
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
      listenable: Listenable.merge([drone, metronome, navigation, scope.tuner]),
      builder: (context, _) {
        final section = navigation.section;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSection(navigation.section);
        });
        return Scaffold(
          // No title bar: the three sections share the whole height, and the
          // name lives in About. Settings is the one button left, in the corner.
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                PageView(
                  controller: _pages,
                  onPageChanged: (i) {
                    if (!_sliding) navigation.open(AppSection.values[i]);
                  },
                  children: [for (final s in _screens) _KeepAlive(child: s)],
                ),
                PositionedDirectional(
                  top: 0,
                  end: 4,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: l10n.settingsTitle,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                active: metronome.isPlaying,
                NavigationDestination(
                  icon: ActivityIcon(
                    icon: Icons.timer_outlined,
                    activeIcon: Icons.timer,
                    active: metronome.isPlaying,
                  ),
                  label: l10n.metronomeTab,
                  // No tooltip: holding the tab starts and stops it instead.
                  tooltip: '',
                ),
              ),
              _tab(
                AppSection.drone,
                active: drone.isPlaying,
                NavigationDestination(
                  icon: ActivityIcon(
                    icon: Icons.graphic_eq,
                    active: drone.isPlaying,
                  ),
                  label: l10n.harmonyTab,
                  tooltip: '',
                ),
              ),
              _tab(
                AppSection.tuner,
                active: scope.tuner.isListening,
                NavigationDestination(
                  // It listens: the microphone says what the tab does, and
                  // the dot, as on the others, that it is on now.
                  icon: ActivityIcon(
                    icon: Icons.mic_none,
                    activeIcon: Icons.mic,
                    active: scope.tuner.isListening,
                  ),
                  label: l10n.tunerTab,
                ),
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
