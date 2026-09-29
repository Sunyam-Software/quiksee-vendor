package `in`.quiksee.dman

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

/**
 * Fired by [DriverKeepAliveScheduler] while the driver is online.
 * Restarts the online FGS (GPS + pending-offers poll) after force-clear.
 */
class DriverKeepAliveReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != DriverKeepAliveScheduler.ACTION) return

        val appCtx = context.applicationContext
        if (!DriverKeepAliveScheduler.isDriverOnline(appCtx)) {
            DriverKeepAliveScheduler.cancel(appCtx)
            return
        }

        Log.i(TAG, "Keep-alive tick — restart online service")
        var wakeLock: PowerManager.WakeLock? = null
        try {
            val pm = appCtx.getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "quiksee:driver_keep_alive",
            ).apply { acquire(30_000L) }

            DriverOnlineService.start(appCtx)
        } catch (e: Exception) {
            Log.w(TAG, "Keep-alive start failed: ${e.message}")
        } finally {
            DriverKeepAliveScheduler.schedule(appCtx)
            try {
                if (wakeLock?.isHeld == true) wakeLock.release()
            } catch (_: Exception) {
            }
        }
    }

    companion object {
        private const val TAG = "DriverKeepAlive"
    }
}
