package com.quiksee.vendor

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.os.Build

object VendorNotificationChannels {
    const val ORDER_CHANNEL_ID = "quiksee_new_order"
    const val WATCH_CHANNEL_ID = "quiksee_order_watch"

    fun ensureCreated(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val orderChannel = NotificationChannel(
            ORDER_CHANNEL_ID,
            "New orders",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Ring and vibrate when a new vendor order arrives"
            enableVibration(true)
            enableLights(true)
            setShowBadge(true)
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(null, attrs)
        }

        val watchChannel = NotificationChannel(
            WATCH_CHANNEL_ID,
            "Order listening service",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps Quiksee Vendor listening for new orders in background"
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }

        manager.createNotificationChannel(orderChannel)
        manager.createNotificationChannel(watchChannel)
    }
}
