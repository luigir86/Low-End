import 'package:flutter/material.dart';

import '../actions/app_actions.dart';
import '../audio/audio_scope.dart';
import '../audio/mic_input.dart';
import '../audio/tone_output.dart';
import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/tuner_controller.dart';
import '../l10n/app_localizations.dart';
import 'app_navigation.dart';
import 'home_shell.dart';

class LowEndApp extends StatefulWidget {
  const LowEndApp({super.key, this.toneOutput, this.micInput});

  /// Audio output for the drone; defaults to the device's speakers.
  final ToneOutput? toneOutput;

  /// Audio input for the tuner; defaults to the device's microphone.
  final MicInput? micInput;

  @override
  State<LowEndApp> createState() => _LowEndAppState();
}

// Built once, not on every rebuild. The launch screen colours in
// android/app/src/main/res/values*/colors.xml match these backgrounds.
final _lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B4513)),
);
final _darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B4513),
    brightness: Brightness.dark,
  ),
);

class _LowEndAppState extends State<LowEndApp> with WidgetsBindingObserver {
  late final _drone = DroneController(widget.toneOutput ?? SoLoudToneOutput());
  late final _tuner = TunerController(widget.micInput ?? RecordMicInput());
  final _navigation = AppNavigation();
  late final _actions = AppActions(
    drone: _drone,
    tuner: _tuner,
    navigation: _navigation,
  );

  @override
  void initState() {
    super.initState();
    // The microphone only listens while the tuner is on screen.
    _navigation.addListener(() {
      if (!_navigation.tunerVisible) _tuner.stop();
    });
    // Registered before MaterialApp's own observer, so action links are
    // handled here instead of being treated as pages to open.
    WidgetsBinding.instance.addObserver(this);
    final initial = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (initial != '/') _runLink(Uri.parse(initial));
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
    _drone.dispose();
    _tuner.dispose();
    _navigation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AudioScope(
      drone: _drone,
      tuner: _tuner,
      navigation: _navigation,
      actions: _actions,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: _lightTheme,
        darkTheme: _darkTheme,
        // Always start on the main screen: a launch link is an action, not a
        // page (see _runLink).
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const HomeShell()),
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(builder: (_) => const HomeShell()),
        ],
      ),
    );
  }
}
