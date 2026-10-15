import 'package:flutter/scheduler.dart';
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

/// Records when the microphone was first asked for.
class _WatchedMic extends FakeMicInput {
  SchedulerPhase? askedDuring;

  @override
  Future<bool> requestPermission() {
    askedDuring ??= SchedulerBinding.instance.schedulerPhase;
    return super.requestPermission();
  }
}

void main() {
  // Opening the app must stay instant: the first frame is drawn before the
  // microphone starts, and the audio engine waits for the first sound.
  testWidgets('the first frame comes before the microphone and the audio', (
    tester,
  ) async {
    final output = _WatchedToneOutput();
    final mic = _WatchedMic();
    await tester.pumpWidget(LowEndApp(toneOutput: output, micInput: mic));
    await tester.pumpAndSettle();

    // The tuner on screen starts listening by itself, but only once the
    // first frame has been drawn.
    expect(mic.askedDuring, SchedulerPhase.postFrameCallbacks);
    expect(find.text('Pause'), findsOneWidget);
    expect(output.used, isFalse);
  });
}
