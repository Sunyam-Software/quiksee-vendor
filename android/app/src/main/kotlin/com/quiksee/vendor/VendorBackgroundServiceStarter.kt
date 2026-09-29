package com.quiksee.vendor

import android.content.Context
import android.content.Intent
import android.os.Build

object VendorBackgroundServiceStarter {
    private const val SERVICE_CLASS =
        "id.flutter.flutter_background_service.BackgroundService"
    private const val PREFS = "FlutterSharedPreferences"
    private const val CONFIGURED_KEY = "flutter.order_watch_service_configured"

    private fun isServiceConfigured(context: Context): Boolean {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(CONFIGURED_KEY, false)
    }

    fun start(context: Context) {
        if (!VendorSessionHelper.isLoggedIn(context)) return
        if (!isServiceConfigured(context)) return

        VendorNotificationChannels.ensureCreated(context.applicationContext)

        try {
            val serviceIntent = Intent(context, Class.forName(SERVICE_CLASS))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {
        }
    }
}
