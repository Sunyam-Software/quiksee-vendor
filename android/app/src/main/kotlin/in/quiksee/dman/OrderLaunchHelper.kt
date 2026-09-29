package `in`.quiksee.dman

import android.app.ActivityOptions
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager

/**
 * Wakes the device and launches [MainActivity] when a new-order FCM arrives
 * while the app is closed, backgrounded, or the screen is off / locked.
 */
object OrderLaunchHelper {

    val wakeOrderTypes: Set<String> = setOf(
        "delivery_assignment_offer",
        "new_order_assigned",
        "order",
    )

    private var wakeLock: PowerManager.WakeLock? = null
    private var cpuWakeLock: PowerManager.WakeLock? = null
    private val launchHandler = Handler(Looper.getMainLooper())

    fun shouldLaunchFor(data: Map<String, String>): Boolean {
        return wakeOrderTypes.contains(data["type"])
    }

    fun launchForOrder(context: Context, data: Map<String, String>) {
        if (!shouldLaunchFor(data)) return

        val appCtx = context.applicationContext
        wakeScreen(appCtx)

        val intent = buildLaunchIntent(appCtx, data)
        startActivitySafe(appCtx, intent)

        launchHandler.removeCallbacksAndMessages(null)
        launchHandler.postDelayed({ startActivitySafe(appCtx, intent) }, 700L)
        launchHandler.postDelayed({ startActivitySafe(appCtx, intent) }, 2_000L)
    }

    private fun startActivitySafe(context: Context, intent: Intent) {
        try {
            if (Build.VERSION.SDK_INT >= 34) {
                val options = ActivityOptions.makeBasic()
                try {
                    options.setPendingIntentBackgroundActivityStartMode(
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED,
                    )
                } catch (_: Throwable) {
                }
                context.startActivity(intent, options.toBundle())
            } else {
                context.startActivity(intent)
            }
        } catch (_: Exception) {
            try {
                context.startActivity(intent)
            } catch (_: Exception) {
            }
        }
    }

    fun buildLaunchIntent(context: Context, data: Map<String, String>): Intent {
        return Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                addFlags(Intent.FLAG_ACTIVITY_MATCH_EXTERNAL)
            }
            putExtra("new_order_wake", true)
            putExtra("wake_order_type", data["type"])
            data["order_id"]?.let { putExtra("wake_order_id", it) }
            data["offer_id"]?.let { putExtra("wake_offer_id", it) }
        }
    }

    fun wakeScreen(context: Context) {
        try {
            val powerManager =
                context.getSystemService(Context.POWER_SERVICE) as PowerManager

            releaseWakeLock()

            @Suppress("DEPRECATION")
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                "quiksee:new_order_wake",
            ).apply {
                acquire(120_000L)
            }

            cpuWakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "quiksee:new_order_cpu",
            ).apply {
                acquire(120_000L)
            }
        } catch (_: Exception) {
        }
    }

    fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) it.release()
            }
            cpuWakeLock?.let {
                if (it.isHeld) it.release()
            }
        } catch (_: Exception) {
        }
        wakeLock = null
        cpuWakeLock = null
    }
}
