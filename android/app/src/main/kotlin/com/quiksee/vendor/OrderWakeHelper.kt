package com.quiksee.vendor

import android.content.Context
import android.content.Intent
import android.os.PowerManager

object OrderWakeHelper {
    private const val WAKE_LOCK_TAG = "quiksee:vendor_order_wake"

    fun wakeAndLaunch(context: Context, orderId: Int = 0, startAlert: Boolean = true) {
        acquireWakeLock(context)
        if (startAlert) {
            OrderAlertPlayer.start(context, orderId)
        }

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra("new_order_wake", true)
            if (orderId > 0) {
                putExtra("order_id", orderId)
            }
        }
        context.startActivity(launchIntent)
    }

    fun acquireWakeLock(context: Context) {
        try {
            val powerManager =
                context.getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                    PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    PowerManager.ON_AFTER_RELEASE,
                WAKE_LOCK_TAG
            )
            wakeLock.acquire(30_000L)
        } catch (_: Exception) {
        }
    }
}
