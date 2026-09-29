package com.quiksee.vendor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class VendorBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            ACTION_QUICKBOOT_POWERON,
            ACTION_HTC_QUICKBOOT -> {
                if (!VendorSessionHelper.isLoggedIn(context)) return
                OrderWatchAlarmScheduler.schedule(context)
                VendorBackgroundServiceStarter.start(context)
            }
        }
    }

    companion object {
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
        private const val ACTION_HTC_QUICKBOOT = "com.htc.intent.action.QUICKBOOT_POWERON"
    }
}
