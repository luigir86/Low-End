import 'package:flutter/material.dart';

import '../audio/audio_scope.dart';
import '../audio/mic_input.dart';
import '../audio/tone_output.dart';
import '../features/tuner/drone/drone_controller.dart';
import '../features/tuner/tuner_controller.dart';
import '../l10n/app_localizations.dart';
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

class _LowEndAppState extends State<LowEndApp> {
  late final _drone = DroneController(widget.toneOutput ?? SoLoudToneOutput());
  late final _tuner = TunerController(widget.micInput ?? RecordMicInput());

  @override
  void dispose() {
    _drone.dispose();
    _tuner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AudioScope(
      drone: _drone,
      tuner: _tuner,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B4513)),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
