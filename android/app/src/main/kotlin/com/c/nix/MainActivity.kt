package com.c.nix

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "audio_output"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getBluetoothDeviceName") {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

                if (audioManager.isBluetoothA2dpOn) {
                    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
                    val bondedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices

                    val connectedDevice = bondedDevices?.firstOrNull { device ->
                        // No public API for "connected", so we assume bonded device with recent connection
                        device.name != null
                    }

                    if (connectedDevice != null) {
                        result.success(connectedDevice.name)
                    } else {
                        result.success("Bluetooth device")
                    }
                } else {
                    result.success("Not using Bluetooth")
                }
            } else {
                result.notImplemented()
            }
        }
    }
}