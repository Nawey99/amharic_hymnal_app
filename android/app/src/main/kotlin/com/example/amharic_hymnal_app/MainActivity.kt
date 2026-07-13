package com.example.amharic_hymnal_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    private val secureScreenChannel = "wudase/secure_screen"
    private var appliedSecureScreenState: Boolean? = null

    companion object {
        @Volatile
        private var secureScreenRequested = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, secureScreenChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enable" -> {
                        setSecureScreenEnabled(true)
                        result.success(null)
                    }
                    "disable" -> {
                        setSecureScreenEnabled(false)
                        result.success(null)
                    }
                    "isCaptured" -> result.success(false)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        applySecureScreenState()
    }

    private fun setSecureScreenEnabled(enabled: Boolean) {
        secureScreenRequested = enabled
        applySecureScreenState()
    }

    private fun applySecureScreenState() {
        if (appliedSecureScreenState == secureScreenRequested) return

        if (secureScreenRequested) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        appliedSecureScreenState = secureScreenRequested
    }
}
