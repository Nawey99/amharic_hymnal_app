package com.nawey99.wudase

import android.os.StatFs
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val secureScreenChannel = "wudase/secure_screen"
    private val storageChannel = "wudase/storage"
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Bytes free on the volume holding the given directory.
                    "freeBytes" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "A path is required.", null)
                        } else {
                            try {
                                result.success(StatFs(path).availableBytes)
                            } catch (error: IllegalArgumentException) {
                                result.error("failed", error.message, null)
                            }
                        }
                    }
                    // The app opts out of Android backup entirely
                    // (allowBackup="false"), so there is nothing to exclude.
                    "excludeFromBackup" -> result.success(null)
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
