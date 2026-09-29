package com.quiksee.vendor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class OrderWakeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        when (action) {
            ACTION_WAKE_FOR_ORDER -> {
                val orderId = intent.getIntExtra(EXTRA_ORDER_ID, 0)
                OrderWakeHelper.wakeAndLaunch(
                    context.applicationContext,
                    orderId,
                    startAlert = true,
                )
            }
            ACTION_STOP_ORDER_ALERT -> {
                val orderId = intent.getIntExtra(EXTRA_ORDER_ID, 0)
                OrderAlertPlayer.stop(context.applicationContext, orderId)
            }
        }
    }

    companion object {
        const val ACTION_WAKE_FOR_ORDER = "in.quiksee.vendor.WAKE_FOR_ORDER"
        const val ACTION_STOP_ORDER_ALERT = "in.quiksee.vendor.STOP_ORDER_ALERT"
        const val EXTRA_ORDER_ID = "order_id"
    }
}
