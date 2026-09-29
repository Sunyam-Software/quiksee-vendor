package com.quiksee.vendor

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock

object OrderWatchAlarmScheduler {
    private const val REQUEST_CODE = 9101
    private const val INTERVAL_MS = 30_000L

    fun schedule(context: Context) {
        if (!VendorSessionHelper.isLoggedIn(context)) return

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = watchdogPendingIntent(context)

        val triggerAt = SystemClock.elapsedRealtime() + INTERVAL_MS
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pendingIntent,
                )
            } else {
                @Suppress("DEPRECATION")
                alarmManager.set(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    pendingIntent,
                )
            }
        } catch (_: Exception) {
        }
    }

    fun cancel(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(watchdogPendingIntent(context))
    }

    private fun watchdogPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, OrderWatchdogReceiver::class.java).apply {
            action = OrderWatchdogReceiver.ACTION_WATCHDOG
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(context, REQUEST_CODE, intent, flags)
    }
}
