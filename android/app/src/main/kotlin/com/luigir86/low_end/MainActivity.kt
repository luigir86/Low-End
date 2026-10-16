package com.luigir86.low_end

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity shares the Flutter engine with the media notification,
// so that its buttons reach the app while the screen is off.
class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The volume buttons set the drone's loudness (media volume), even
        // before it starts, rather than the ringer.
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Android 13+ shows the notification only if the user allows it.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "low_end/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method == "request") {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                        PackageManager.PERMISSION_GRANTED
                    ) {
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
