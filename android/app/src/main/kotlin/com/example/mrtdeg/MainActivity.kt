package com.example.mrtdeg
import io.flutter.embedding.android.FlutterFragmentActivity


import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import com.example.mrtdeg.ImageUtil
import android.content.Context
import android.content.Intent
import android.nfc.NfcAdapter

class MainActivity: FlutterFragmentActivity(){
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "image_channel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "decodeImage" -> {
                        val jp2ImageData = call.argument<ByteArray?>("jp2ImageData")
                        if (jp2ImageData != null) {
                            ImageUtil.decodeImage(applicationContext, jp2ImageData, result)
                        } else {
                            result.error("INVALID_ARGUMENT", "jp2ImageData is null", null)
                        }
                    }
                    "checkNfcAvailability" -> checkNfcAvailability(result)
                    "openNFCSettings" -> openNFCSettings()
                    else -> result.notImplemented()
                }
            }
    }

    private fun openNFCSettings() {
        startActivity(Intent(android.provider.Settings.ACTION_NFC_SETTINGS))
    }

    private fun checkNfcAvailability(result: MethodChannel.Result) {
        val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        if (nfcAdapter != null && nfcAdapter.isEnabled) {
            result.success(true)
        } else {
            result.success(false)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // Ensure the activity has the latest intent if it's still running
    }
}
