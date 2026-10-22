package com.luigir86.low_end

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity shares the Flutter engine with the media notification,
// so that its buttons reach the app while the screen is off.
class MainActivity : AudioServiceActivity() {
    private var routeChannel: MethodChannel? = null

    // Headphones pulled out: Android is about to play through the speaker.
    private val noisyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                routeChannel?.invokeMethod("noisy", null)
            }
        }
    }

    // Headphones or a Bluetooth headset come or go: the sound's delay changes.
    private val deviceCallback = object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(added: Array<out AudioDeviceInfo>) = sendRoute()
        override fun onAudioDevicesRemoved(removed: Array<out AudioDeviceInfo>) = sendRoute()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The volume buttons set the drone's loudness (media volume), even
        // before it starts, rather than the ringer.
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Where the sound goes (see lib/audio/audio_route.dart).
        routeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "low_end/audio_route")
            .apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "route") result.success(outputKind()) else result.notImplemented()
                }
            }
        val noisy = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(noisyReceiver, noisy, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(noisyReceiver, noisy)
        }
        audioManager().registerAudioDeviceCallback(deviceCallback, Handler(Looper.getMainLooper()))
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
                } else if (call.method == "cancel") {
                    // The media notification, once nothing plays (1124 is
                    // audio_service's id for it).
                    NotificationManagerCompat.from(this).cancel(1124)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        // The app's page in the phone settings, to allow the microphone
        // after saying no.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "low_end/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "open") {
                    startActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ),
                    )
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        unregisterReceiver(noisyReceiver)
        audioManager().unregisterAudioDeviceCallback(deviceCallback)
        routeChannel?.setMethodCallHandler(null)
        routeChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun audioManager() = getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private fun sendRoute() {
        routeChannel?.invokeMethod("route", outputKind())
    }

    // "bluetooth", "ble", "wired" or "speaker": where music plays now. From
    // Android 13 the phone says so; before, a headset connected is taken to
    // be the one in use, as Android routes media to it.
    private fun outputKind(): String {
        val manager = audioManager()
        val devices = try {
            if (Build.VERSION.SDK_INT >= 33) {
                val media = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build()
                manager.getAudioDevicesForAttributes(media)
            } else {
                manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).toList()
            }
        } catch (e: RuntimeException) {
            emptyList()
        }
        val types = devices.map { it.type }.toSet()
        return when {
            types.any { it in BLUETOOTH } -> "bluetooth"
            types.any { it in BLE } -> "ble"
            types.any { it in WIRED } -> "wired"
            else -> "speaker"
        }
    }

    private companion object {
        val BLUETOOTH = setOf(AudioDeviceInfo.TYPE_BLUETOOTH_A2DP, AudioDeviceInfo.TYPE_HEARING_AID)

        // TYPE_BLE_HEADSET, TYPE_BLE_SPEAKER (Android 12), TYPE_BLE_BROADCAST
        // (Android 13): plain numbers, so the older phones need not know them.
        val BLE = setOf(26, 27, 30)
        val WIRED = setOf(
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_LINE_ANALOG,
        )
    }
}
