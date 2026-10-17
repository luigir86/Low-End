import 'dart:async';

import 'package:flutter/material.dart';

import '../actions/app_actions.dart';
import '../audio/audio_scope.dart';
import '../audio/click_output.dart';
import '../audio/mic_input.dart';
import '../audio/piano_output.dart';
import '../audio/pitch.dart';
import '../audio/tone_output.dart';
import '../features/metronome/metronome_controller.dart';
import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/drone/drone_panel.dart' show chordSymbol;
import '../features/tuner/tuner_controller.dart';
import '../l10n/app_localizations.dart';
import 'app_navigation.dart';
import 'background_audio.dart';
import 'settings.dart';
import 'home_shell.dart';
import 'screen_awake.dart';
import 'theme.dart';

class LowEndApp extends StatefulWidget {
  const LowEndApp({
    super.key,
    this.toneOutput,
    this.clickOutput,
    this.micInput,
    this.settings,
    this.backgroundAudio,
    this.pianoOutput,
    this.screenAwake,
  });

  /// Audio output for the drone; defaults to the device's speakers.
  final ToneOutput? toneOutput;

  /// Audio output for the drone's piano; defaults to the device's speakers.
  final PianoOutput? pianoOutput;

  /// Audio output for the metronome; defaults to the device's speakers.
  final ClickOutput? clickOutput;

  /// Audio input for the tuner; defaults to the device's microphone.
  final MicInput? micInput;

  /// Saved preferences (see [AppSettings.load]); unsaved defaults if null.
  final AppSettings? settings;

  /// Keeps the sound going in the background; the phone's foreground
  /// service by default.
  final BackgroundAudio? backgroundAudio;

  /// Keeps the screen on while something plays or the tuner listens; the
  /// phone's wake lock by default.
  final ScreenAwake? screenAwake;

  @override
  State<LowEndApp> createState() => _LowEndAppState();
}

class _LowEndAppState extends State<LowEndApp> with WidgetsBindingObserver {
  late final _drone = DroneController(
    widget.toneOutput ?? SoLoudToneOutput(),
    // Progressions change chord on the metronome's bars.
    clock: _metronome,
    // With a tone output given (as tests do) there is no piano, unless one
    // is given too: the real one needs the audio engine.
    piano:
        widget.pianoOutput ??
        (widget.toneOutput == null ? SoLoudPianoOutput() : null),
  );
  late final _metronome = MetronomeController(
    widget.clickOutput ?? SoLoudClickOutput(),
  );
  late final _tuner = TunerController(widget.micInput ?? RecordMicInput());
  late final BackgroundAudio _background =
      widget.backgroundAudio ?? MediaNotificationAudio();
  late final ScreenAwake _screenAwake =
      widget.screenAwake ?? WakelockScreenAwake();
  final _navigation = AppNavigation();

  /// Shows the notice that the sound paused for the tuner.
  final _messenger = GlobalKey<ScaffoldMessengerState>();
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
    _drone.setLevel(_settings.droneLevel);
    _metronome.setLevel(_settings.metronomeLevel);
    // The metronome comes back as it was left: time signature first, since
    // the fastest tempo depends on it.
    _metronome.setSignature(_settings.metronomeSignature);
    _metronome.setBpm(_settings.metronomeBpm);
    _metronome.setFeel(_settings.metronomeFeel);
    _metronome.addListener(_rememberMetronome);
    // The drone opens on the piano: the chord on every beat (set before it
    // plays, so nothing starts yet).
    if (_drone.hasPiano) _drone.setVoicing(DroneVoicing.chord);
    _settings.addListener(_onSettingsChanged);
    _lastSection = _navigation.section;
    _navigation.addListener(_onNavigationChanged);
    _drone.addListener(_onPlayingChanged);
    _metronome.addListener(_onPlayingChanged);
    _tuner.addListener(_keepScreenOn);
    _commands = _background.commands.listen(_onMediaCommand);
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

  void _rememberMetronome() => _settings.rememberMetronome(
    bpm: _metronome.bpm,
    signature: _metronome.signature,
    feel: _metronome.feel,
  );

  void _onSettingsChanged() {
    _keepScreenOn();
    // The notification names the notes in the player's way.
    if (_shown == MediaState.playing) _onPlayingChanged();
    // Both only act when their value really changed.
    _drone.setLevel(_settings.droneLevel);
    _metronome.setLevel(_settings.metronomeLevel);
    if (_settings.a4 == _droneA4) return;
    _droneA4 = _settings.a4;
    _drone.setReferencePitch(_droneA4);
  }

  /// The tuner listens whenever it is on screen, and only then; coming back
  /// it listens again, unless the player paused it.
  ///
  /// Coming to the Tuner tab, the drone and the metronome pause, or the
  /// microphone would hear them instead of the bass, and a notice says so,
  /// with a button to play them again. Leaving the tab, nothing starts by
  /// itself: a swipe too far must not bring the click back unasked, out of
  /// time with the band.
  void _onNavigationChanged() {
    _navigation.tunerVisible ? _tuner.resume() : _tuner.stop();
    final section = _navigation.section;
    final arrived =
        section == AppSection.tuner && _lastSection != AppSection.tuner;
    _lastSection = section;
    if (arrived) _pauseForTuner();
    _keepScreenOn();
  }

  /// The section on screen when the navigation last changed, to tell a
  /// move to the tuner from a page opened on top of it.
  AppSection _lastSection = AppSection.metronome;

  void _pauseForTuner() {
    final drone = _drone.isPlaying, metronome = _metronome.isPlaying;
    if (!drone && !metronome) return;
    if (drone) _drone.stop();
    if (metronome) _metronome.stop();
    final l10n = _notificationTexts();
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.pausedForTuner),
          persist: false,
          action: SnackBarAction(
            label: l10n.resume,
            onPressed: () {
              if (drone && !_drone.isPlaying) _drone.start();
              if (metronome && !_metronome.isPlaying) _metronome.start();
            },
          ),
        ),
      );
  }

  /// The screen stays on while anything plays or the tuner listens.
  void _keepScreenOn() => _screenAwake.keepOn(
    _settings.keepScreenOn &&
        (_drone.isPlaying || _metronome.isPlaying || _tuner.isListening),
  );

  /// With the screen off or the app in the background, the drone and the
  /// metronome carry on, kept alive by a media notification (see
  /// [BackgroundAudio]) that is there while one of them plays, and after a
  /// pause from the notification, to resume from.
  var _shown = MediaState.off;
  var _pausedFromNotification = false;
  var _stoppingFromNotification = false;
  var _heldDrone = false;
  var _heldMetronome = false;
  StreamSubscription<MediaCommand>? _commands;

  /// What the notification says is playing, kept while it is paused.
  var _nowPlaying = '';
  var _shownText = '';

  void _onPlayingChanged() {
    _keepScreenOn();
    final playing = _drone.isPlaying || _metronome.isPlaying;
    final l10n = _notificationTexts();
    // Not while the notification's own pause is stopping things: stopping
    // the drone first, with the metronome still sounding, would otherwise
    // look like a restart and forget the pause (and play would do nothing).
    if (playing && !_stoppingFromNotification) {
      _pausedFromNotification = false;
      _nowPlaying = _describePlaying(l10n);
    }
    final state = playing
        ? MediaState.playing
        : _pausedFromNotification
        ? MediaState.paused
        : MediaState.off;
    // A new tempo, note or chord changes the text, not the state.
    if (state == _shown && _nowPlaying == _shownText) return;
    _shown = state;
    _shownText = _nowPlaying;
    // What plays, and at what tempo, on the first line: that is what the
    // small notification shows beside the play button. The app's name and
    // icon sit in its header, as on a music player.
    final lines = _nowPlaying.split('\n').where((s) => s.isNotEmpty).toList();
    _background.show(
      state,
      title: lines.isEmpty ? l10n.backgroundPlaying : lines.first,
      text: lines.length > 1 ? lines[1] : l10n.appTitle,
    );
  }

  /// "Metronome 120 BPM · 4/4" and "Harmony A major", one per line: what is
  /// playing, for the notification.
  String _describePlaying(AppLocalizations l10n) {
    final parts = <String>[];
    if (_metronome.isPlaying) {
      parts.add(
        '${l10n.metronomeTab} ${l10n.bpmValue('${_metronome.bpm}')} · '
        '${_metronome.signature.label}',
      );
    }
    if (_drone.isPlaying) {
      final names = _settings.noteNames(_locale());
      final root = spell(_drone.rootPitchClass, _drone.rootLetter, names);
      final chord = _drone.currentChord;
      parts.add(
        '${l10n.harmonyTab} '
        '${chord == null ? root : chordSymbol(l10n, chord, root)}',
      );
    }
    return parts.join('\n');
  }

  void _onMediaCommand(MediaCommand command) {
    switch (command) {
      case MediaCommand.pause:
        if (!_drone.isPlaying && !_metronome.isPlaying) return;
        _heldDrone = _drone.isPlaying;
        _heldMetronome = _metronome.isPlaying;
        _pausedFromNotification = true;
        _stoppingFromNotification = true;
        _drone.stop();
        _metronome.stop();
        _stoppingFromNotification = false;
        // Shows the paused notification, whatever the stops showed.
        _onPlayingChanged();
      case MediaCommand.play:
        if (!_pausedFromNotification) return;
        if (_heldDrone) _drone.start();
        if (_heldMetronome) _metronome.start();
      case MediaCommand.stop:
        _pausedFromNotification = false;
        _drone.stop();
        _metronome.stop();
        // Nothing was playing when paused: the notification must go anyway.
        _onPlayingChanged();
    }
  }

  Locale _locale() =>
      _settings.locale ?? WidgetsBinding.instance.platformDispatcher.locale;

  AppLocalizations _notificationTexts() {
    final locale = _locale();
    return AppLocalizations.delegate.isSupported(locale)
        ? lookupAppLocalizations(locale)
        : lookupAppLocalizations(const Locale('en'));
  }

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
    _drone.removeListener(_onPlayingChanged);
    _metronome.removeListener(_onPlayingChanged);
    _metronome.removeListener(_rememberMetronome);
    _tuner.removeListener(_keepScreenOn);
    _commands?.cancel();
    _background.show(MediaState.off, title: '');
    _screenAwake.keepOn(false);
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
    scaffoldMessengerKey: _messenger,
    // Null follows the phone's language.
    locale: _settings.locale,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: LowEndTheme.light,
    darkTheme: LowEndTheme.dark,
    themeMode: _settings.themeMode,
    // Always start on the main screen: a launch link is an action, not a
    // page (see _runLink).
    onGenerateRoute: (_) =>
        MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    onGenerateInitialRoutes: (_) => [
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    ],
  );
}
