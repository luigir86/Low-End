import 'dart:async';
import 'dart:io' show File, Platform, Directory;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the notification asks for.
enum MediaCommand { play, pause, stop }

/// What the notification shows.
enum MediaState { off, playing, paused }

/// Keeps the sound going with the screen off or the app in the background,
/// and lets the notification pause, resume and stop it.
///
/// Android freezes an app that has gone to the background unless it runs a
/// foreground service, shown as a media notification. Kept behind an
/// interface so the rest of the app can be tested without a phone.
abstract class BackgroundAudio {
  /// What the user asks from the notification (or a headset button).
  Stream<MediaCommand> get commands;

  /// Shows the notification in [state], or removes it for [MediaState.off].
  Future<void> show(MediaState state, {required String title, String text});
}

/// [BackgroundAudio] backed by an Android media notification (and the
/// foreground service behind it).
class MediaNotificationAudio implements BackgroundAudio {
  static bool get _supported => !kIsWeb && Platform.isAndroid;

  static const _channel = MethodChannel('low_end/notifications');

  final _commands = StreamController<MediaCommand>.broadcast();
  _Handler? _handler;
  Future<_Handler>? _starting;
  var _askedPermission = false;

  @override
  Stream<MediaCommand> get commands => _commands.stream;

  Future<_Handler> _start() => _starting ??=
      AudioService.init(
        builder: () => _Handler(_commands),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.luigir86.low_end.playback',
          androidNotificationChannelName: 'Low End',
          // Paused, the notification stays (it is how the sound is resumed)
          // but the service leaves the foreground, Android's default: kept
          // in the foreground, the notification could not be removed when
          // the sound stops, and stayed with a play button that does
          // nothing.
          androidStopForegroundOnPause: true,
          // A plain white lion: Android paints the small icon of the
          // notification one colour, and the coloured launcher icon would
          // come out as a blob.
          androidNotificationIcon: 'drawable/ic_stat_low_end',
        ),
      ).then((h) => _handler = h).catchError((Object error) {
        _starting = null;
        throw error;
      });

  @override
  Future<void> show(
    MediaState state, {
    required String title,
    String text = '',
  }) async {
    if (!_supported) return;
    try {
      if (state == MediaState.off && _handler == null) return;
      if (state == MediaState.playing && !_askedPermission) {
        // Android 13+ hides the notification without this; the sound would
        // still play.
        _askedPermission = true;
        unawaited(
          _channel.invokeMethod<void>('request').catchError((Object _) {}),
        );
      }
      final handler = await _start();
      if (state == MediaState.off) {
        await handler.hide();
      } else {
        handler.show(
          playing: state == MediaState.playing,
          title: title,
          text: text,
          art: await _artwork(),
        );
      }
    } catch (error) {
      debugPrint('Background audio could not change: $error');
    }
  }

  Uri? _art;

  /// The logo as a file, for the cover of the notification, as a music
  /// player shows its album art. Null where it cannot be written.
  Future<Uri?> _artwork() async {
    if (_art != null) return _art;
    try {
      final data = await rootBundle.load('assets/brand/logo.png');
      final file = File('${Directory.systemTemp.path}/low_end_cover.png');
      // Only this asset's bytes: the data may be a view into a larger buffer.
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return _art = file.uri;
    } catch (error) {
      debugPrint('Notification cover not written: $error');
      return null;
    }
  }
}

class _Handler extends BaseAudioHandler {
  _Handler(this._commands);

  final StreamController<MediaCommand> _commands;

  void show({
    required bool playing,
    required String title,
    required String text,
    Uri? art,
  }) {
    mediaItem.add(
      MediaItem(id: 'low_end', title: title, artist: text, artUri: art),
    );
    playbackState.add(
      PlaybackState(
        // Only play and pause, on the right, as on a music player.
        controls: [if (playing) MediaControl.pause else MediaControl.play],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const [0],
        processingState: AudioProcessingState.ready,
        playing: playing,
      ),
    );
  }

  Future<void> hide() => super.stop();

  @override
  Future<void> play() async => _commands.add(MediaCommand.play);

  @override
  Future<void> pause() async => _commands.add(MediaCommand.pause);

  @override
  Future<void> stop() async => _commands.add(MediaCommand.stop);

  /// The user swiped the app away from the recent apps: the sound ends with
  /// it, the notification is only for an app that is still open.
  @override
  Future<void> onTaskRemoved() async {
    _commands.add(MediaCommand.stop);
    await super.stop();
  }
}
