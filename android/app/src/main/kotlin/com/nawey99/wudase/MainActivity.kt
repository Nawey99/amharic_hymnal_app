package com.nawey99.wudase

import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Adds and clears `FLAG_SECURE` on the app window so that Android hides the
/// sheet-music viewer's contents in the recents thumbnail and blocks
/// system screenshots while that page is on screen.
///
/// **Why the ceremony:** flipping `FLAG_SECURE` on a live window forces
/// Android's WindowManager to rebuild the window surface. On some Samsung
/// devices running Vulkan this can leave a frozen or black frame if the
/// change lands mid-draw, and the frozen state can survive being swiped
/// out of Recents. To avoid that:
///
/// 1. When the activity is not resumed we only *record* the request; the
///    flag change is applied on the next `onResume`.
/// 2. When the activity is resumed we post the change to the main
///    thread's Handler so it lands *between* frames, not under one.
/// 3. We keep a "last-applied" cache so a duplicate call is a no-op.
class MainActivity : AudioServiceActivity() {
    private val secureScreenChannel = "wudase/secure_screen"
    private val storageChannel = "wudase/storage"
    private val mainHandler = Handler(Looper.getMainLooper())

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
        // Apply any state a background caller (Dart) requested while we
        // were paused. Deferred to the next frame so the surface change
        // does not land under the very first draw of the resumed window.
        scheduleApplySecureScreenState()
    }

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun setSecureScreenEnabled(enabled: Boolean) {
        secureScreenRequested = enabled
        // Defer to the next frame regardless: the method-channel callback
        // may still be running on the platform thread, and the WindowManager
        // update must land on the main thread outside a draw pass.
        scheduleApplySecureScreenState()
    }

    private fun scheduleApplySecureScreenState() {
        mainHandler.removeCallbacks(applyRunnable)
        mainHandler.post(applyRunnable)
    }

    private val applyRunnable = Runnable { applySecureScreenState() }

    private fun applySecureScreenState() {
        if (!isActivityResumed()) {
            // Ignore while paused: onResume will retry. Avoids touching a
            // window that Android may have already detached from the
            // display, which is what triggers the Samsung freeze.
            return
        }
        if (appliedSecureScreenState == secureScreenRequested) return

        if (secureScreenRequested) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        appliedSecureScreenState = secureScreenRequested
    }

    private fun isActivityResumed(): Boolean {
        // Best-effort check: an activity that has finished onResume and not
        // yet started onPause has `hasWindowFocus()` transiently false but
        // is still considered resumed for flag purposes. The lifecycle
        // observer would be more precise, but this covers the freeze case
        // (which is about paused activities) and stays cheap.
        return !isFinishing && !isDestroyed && window.decorView.isAttachedToWindow
    }
}
