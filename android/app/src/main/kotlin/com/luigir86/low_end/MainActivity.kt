package com.luigir86.low_end

import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The volume buttons set the drone's loudness (media volume), even
        // before it starts, rather than the ringer.
        volumeControlStream = AudioManager.STREAM_MUSIC
    }
}
