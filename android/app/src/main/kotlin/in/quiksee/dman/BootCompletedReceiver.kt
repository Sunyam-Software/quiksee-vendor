package `in`.quiksee.dman

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * After reboot / package replace, restore the online keep-alive so offers
 * can still arrive without the driver manually opening the app.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        Log.i(TAG, "Boot/replace received — restart online if needed")
        DriverOnlineService.restartIfOnline(context.applicationContext)
        if (DriverKeepAliveScheduler.isDriverOnline(context.applicationContext)) {
            DriverKeepAliveScheduler.schedule(context.applicationContext)
        }
    }

    companion object {
        private const val TAG = "QuikseeBoot"
    }
}
