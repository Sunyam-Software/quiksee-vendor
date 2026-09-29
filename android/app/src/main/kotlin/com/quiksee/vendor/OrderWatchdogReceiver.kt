package com.quiksee.vendor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class OrderWatchdogReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_WATCHDOG) return

        OrderWatchAlarmScheduler.schedule(context)

        if (!VendorSessionHelper.isLoggedIn(context)) return

        VendorBackgroundServiceStarter.start(context)
    }

    companion object {
        const val ACTION_WATCHDOG = "in.quiksee.vendor.ORDER_WATCHDOG"
    }
}
