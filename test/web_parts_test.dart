import 'package:flutter_test/flutter_test.dart';
import 'package:low_end/audio/audio_route.dart';
import 'package:low_end/audio/off_thread.dart';
import 'package:low_end/audio/soloud_engine.dart';
import 'package:low_end/audio/web_audio_session.dart';

// The pieces the web app uses in place of Android's (docs/web.md).
void main() {
  test('the web route is the speaker, and never unplugged', () async {
    final route = SpeakerAudioRoute();
    expect(route.outputLatency, outputLatencyFor(AudioOutputKind.speaker));
    expect(await route.unplugged.isEmpty, isTrue);
    route.dispose();
  });

  test('offThread gives back what the work makes', () async {
    expect(await offThread(() => List.generate(4, (i) => i * i)), [0, 1, 4, 9]);
  });

  test('the audio session is left alone outside a web page', () {
    setWebAudioSession(listening: true);
    setWebAudioSession(listening: false);
  });
}
