package `in`.quiksee.dman

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object DriverKeepAliveScheduler {

    const val ACTION = "in.quiksee.dman.action.DRIVER_KEEP_ALIVE"
    private const val TAG = "DriverKeepAlive"
    private const val REQUEST_CODE = 7101
    private const val SHOW_REQUEST_CODE = 7102
    const val INTERVAL_MS = 40_000L

    fun schedule(context: Context) {
        val appCtx = context.applicationContext
        if (!isDriverOnline(appCtx)) {
            cancel(appCtx)
            return
        }
        val am = appCtx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pi = pendingIntent(appCtx)
        val triggerAtWall = System.currentTimeMillis() + INTERVAL_MS

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val show = PendingIntent.getActivity(
                    appCtx,
                    SHOW_REQUEST_CODE,
                    Intent(appCtx, MainActivity::class.java).addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP,
                    ),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                val info = AlarmManager.AlarmClockInfo(triggerAtWall, show)
                am.setAlarmClock(info, pi)
                Log.i(TAG, "AlarmClock keep-alive in ${INTERVAL_MS}ms")
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "setAlarmClock failed: ${e.message}")
        }

        // 2) Exact allow-while-idle
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtWall,
                    pi,
                )
            } else {
                @Suppress("DEPRECATION")
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAtWall, pi)
            }
            Log.i(TAG, "Exact keep-alive in ${INTERVAL_MS}ms")
            return
        } catch (e: SecurityException) {
            Log.w(TAG, "Exact alarm blocked: ${e.message}")
        } catch (e: Exception) {
            Log.w(TAG, "Exact schedule failed: ${e.message}")
        }

        // 3) Inexact fallback
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtWall,
                    pi,
                )
            } else {
                @Suppress("DEPRECATION")
                am.set(AlarmManager.RTC_WAKEUP, triggerAtWall, pi)
            }
            Log.i(TAG, "Inexact keep-alive scheduled")
        } catch (e: Exception) {
            Log.w(TAG, "Fallback alarm failed: ${e.message}")
        }
    }

    fun cancel(context: Context) {
        try {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(pendingIntent(context.applicationContext))
            Log.i(TAG, "Keep-alive cancelled")
        } catch (_: Exception) {
        }
    }

    fun isDriverOnline(context: Context): Boolean {
        return context.applicationContext
            .getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.driver_online", false)
    }

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, DriverKeepAliveReceiver::class.java).apply {
            action = ACTION
        }
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
