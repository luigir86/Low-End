import 'package:flutter/material.dart';

import '../actions/app_actions.dart';
import '../audio/audio_scope.dart';
import '../audio/click_output.dart';
import '../audio/mic_input.dart';
import '../audio/tone_output.dart';
import '../features/metronome/metronome_controller.dart';
import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/tuner_controller.dart';
import '../l10n/app_localizations.dart';
import 'app_navigation.dart';
import 'settings.dart';
import 'home_shell.dart';
import 'theme.dart';

class LowEndApp extends StatefulWidget {
  const LowEndApp({
    super.key,
    this.toneOutput,
    this.clickOutput,
    this.micInput,
    this.settings,
  });

  /// Audio output for the drone; defaults to the device's speakers.
  final ToneOutput? toneOutput;

  /// Audio output for the metronome; defaults to the device's speakers.
  final ClickOutput? clickOutput;

  /// Audio input for the tuner; defaults to the device's microphone.
  final MicInput? micInput;

  /// Saved preferences (see [AppSettings.load]); unsaved defaults if null.
  final AppSettings? settings;

  @override
  State<LowEndApp> createState() => _LowEndAppState();
}

class _LowEndAppState extends State<LowEndApp> with WidgetsBindingObserver {
  late final _drone = DroneController(widget.toneOutput ?? SoLoudToneOutput());
  late final _metronome = MetronomeController(
    widget.clickOutput ?? SoLoudClickOutput(),
  );
  late final _tuner = TunerController(widget.micInput ?? RecordMicInput());
  final _navigation = AppNavigation();
  late final _settings = widget.settings ?? AppSettings();
  late final _actions = AppActions(
    drone: _drone,
    metronome: _metronome,
    tuner: _tuner,
    navigation: _navigation,
    settings: _settings,
  );

  // The reference A last given to the drone: the settings also change for
  // the language and the note names, which must not retune it.
  late double _droneA4 = _settings.a4;

  @override
  void initState() {
    super.initState();
    // The drone plays at the reference A chosen in the settings.
    _drone.setReferencePitch(_droneA4);
    _settings.addListener(_onSettingsChanged);
    _navigation.addListener(_onNavigationChanged);
    _lifecycle; // Starts listening to the app going to the background.
    // If the app opens on the tuner (a link), start listening once the first
    // frame is up, so the microphone never delays it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigation.tunerVisible) _tuner.resume();
    });
    // Registered before MaterialApp's own observer, so action links are
    // handled here instead of being treated as pages to open.
    WidgetsBinding.instance.addObserver(this);
    final initial = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (initial != '/') _runLink(Uri.parse(initial));
  }

  void _onSettingsChanged() {
    if (_settings.a4 == _droneA4) return;
    _droneA4 = _settings.a4;
    _drone.setReferencePitch(_droneA4);
  }

  /// The tuner listens whenever it is on screen, and only then; coming back
  /// it listens again, unless the player paused it.
  ///
  /// On the Tuner tab the drone and the metronome pause, or the microphone
  /// would hear them instead of the bass; leaving it, the ones that were
  /// playing carry on.
  void _onNavigationChanged() {
    _navigation.tunerVisible ? _tuner.resume() : _tuner.stop();
    final onTuner = _navigation.section == AppSection.tuner;
    if (onTuner) {
      if (_drone.isPlaying) {
        _droneWaiting = true;
        _drone.stop();
      }
      if (_metronome.isPlaying) {
        _metronomeWaiting = true;
        _metronome.stop();
      }
    } else {
      if (_droneWaiting) _drone.start();
      if (_metronomeWaiting) _metronome.start();
      _droneWaiting = _metronomeWaiting = false;
    }
  }

  /// Paused by the tuner, to start again when it is left.
  var _droneWaiting = false;
  var _metronomeWaiting = false;

  /// With the screen off or the app in the background, the drone and the
  /// metronome stop for good (playing on there would need a notification
  /// to stop them from).
  late final _lifecycle = AppLifecycleListener(
    onHide: () {
      _droneWaiting = _metronomeWaiting = false;
      _drone.stop();
      _metronome.stop();
    },
  );

  @override
  Future<bool> didPushRouteInformation(RouteInformation info) async =>
      _runLink(info.uri);

  /// Handles every link the app is opened with: runs an action link such as
  /// `lowend://action/drone_play?note=A`, sent by an assistant, a shortcut or
  /// an automation app.
  bool _runLink(Uri uri) {
    final link = AppActions.parseLink(uri);
    if (link == null) {
      // The app has a single page, so there is nothing else to open.
      debugPrint('Ignored link: $uri');
      return true;
    }
    final (name, args) = link;
    _actions.call(name, args).then((result) {
      if (result['ok'] != true) debugPrint('Action link failed: $result');
    });
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // The settings may come from main() and outlive this state.
    _settings.removeListener(_onSettingsChanged);
    _navigation.removeListener(_onNavigationChanged);
    _lifecycle.dispose();
    _drone.dispose();
    _metronome.dispose();
    _tuner.dispose();
    _navigation.dispose();
    if (widget.settings == null) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AudioScope(
      drone: _drone,
      metronome: _metronome,
      tuner: _tuner,
      navigation: _navigation,
      actions: _actions,
      settings: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => _app(),
      ),
    );
  }

  Widget _app() => MaterialApp(
    // Null follows the phone's language.
    locale: _settings.locale,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: LowEndTheme.light,
    darkTheme: LowEndTheme.dark,
    // Always start on the main screen: a launch link is an action, not a
    // page (see _runLink).
    onGenerateRoute: (_) =>
        MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    ],
  );
}
