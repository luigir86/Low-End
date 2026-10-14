import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/app/low_end_app.dart';
import 'package:low_end/audio/mic_input.dart';
import 'package:low_end/audio/tone_output.dart';

/// Records whether anything touched the sound output.
class _WatchedToneOutput extends SilentToneOutput {
  var used = false;

  @override
  Future<void> play(List<double> f, List<double> gains, double v) {
    used = true;
    return super.play(f, gains, v);
  }

  @override
  void setVolume(double v) {
    used = true;
    super.setVolume(v);
  }
}

/// Records whether anything asked for the microphone.
class _WatchedMic extends FakeMicInput {
  var used = false;

  @override
  Future<bool> requestPermission() {
    used = true;
    return super.requestPermission();
  }
}

void main() {
  // Opening the app must stay instant: the audio engine and the microphone
  // start only when the player asks for them, never at launch.
  testWidgets('launching starts neither the audio engine nor the microphone', (
    tester,
  ) async {
    final output = _WatchedToneOutput();
    final mic = _WatchedMic();
    await tester.pumpWidget(LowEndApp(toneOutput: output, micInput: mic));
    await tester.pumpAndSettle();

    expect(find.text('Start listening'), findsOneWidget);
    expect(output.used, isFalse);
    expect(mic.used, isFalse);
  });
}
