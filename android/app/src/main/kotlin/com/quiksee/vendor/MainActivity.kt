package com.quiksee.vendor

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        VendorNotificationChannels.ensureCreated(applicationContext)
        super.onCreate(savedInstanceState)
        enableShowWhenLocked()
        handleIncomingOrderIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingOrderIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        if (intent?.getBooleanExtra("new_order_wake", false) == true) {
            wakeUpScreen()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "in.quiksee.vendor/foreground"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToForeground" -> {
                    bringAppToForeground()
                    result.success(true)
                }
                "wakeScreen" -> {
                    wakeUpScreen()
                    result.success(true)
                }
                "requestBatteryOptimizationExemption" -> {
                    result.success(DeviceWakeHelper.requestBatteryOptimizationExemption(this))
                }
                "openManufacturerAutoStartSettings" -> {
                    result.success(DeviceWakeHelper.openManufacturerAutoStartSettings(this))
                }
                "openAppNotificationSettings" -> {
                    result.success(DeviceWakeHelper.openAppNotificationSettings(this))
                }
                "openBatterySettings" -> {
                    result.success(DeviceWakeHelper.openBatterySettings(this))
                }
                "openFullScreenIntentSettings" -> {
                    result.success(DeviceWakeHelper.openFullScreenIntentSettings(this))
                }
                "isBatteryOptimizationIgnored" -> {
                    result.success(DeviceWakeHelper.isIgnoringBatteryOptimizations(this))
                }
                "canUseFullScreenIntent" -> {
                    result.success(DeviceWakeHelper.canUseFullScreenIntent(this))
                }
                "startNativeOrderAlert" -> {
                    val orderId = call.argument<Number>("order_id")?.toInt() ?: 0
                    OrderAlertPlayer.start(this, orderId)
                    result.success(true)
                }
                "stopNativeOrderAlert" -> {
                    val orderId = call.argument<Number>("order_id")?.toInt() ?: 0
                    OrderAlertPlayer.stop(this, orderId)
                    result.success(true)
                }
                "scheduleOrderWatchdog" -> {
                    OrderWatchAlarmScheduler.schedule(this)
                    result.success(true)
                }
                "cancelOrderWatchdog" -> {
                    OrderWatchAlarmScheduler.cancel(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleIncomingOrderIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("new_order_wake", false) == true) {
            wakeUpScreen()
        }
    }

    private fun bringAppToForeground() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra("new_order_wake", true)
            intent?.getIntExtra("order_id", 0)?.takeIf { it > 0 }?.let {
                putExtra("order_id", it)
            }
        }
        startActivity(launchIntent)
        wakeUpScreen()
    }

    private fun wakeUpScreen() {
        enableShowWhenLocked()
        acquireWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            dismissKeyguard()
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    private fun dismissKeyguard() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        keyguardManager.requestDismissKeyguard(this, null)
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock?.let {
                if (it.isHeld) it.release()
            }
            @Suppress("DEPRECATION")
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                "quiksee:vendor_order_wake"
            ).apply {
                acquire(30_000L)
            }
        } catch (_: Exception) {
        }
    }

    private fun enableShowWhenLocked() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun onDestroy() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
        super.onDestroy()
    }
}
