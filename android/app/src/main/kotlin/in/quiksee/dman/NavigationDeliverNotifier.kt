package `in`.quiksee.dman

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Heads-up when rider is near the customer during Google Maps navigation.
 * Shows EXIT → Quiksee and Open & Deliver. EXIT dismisses this alert.
 */
object NavigationDeliverNotifier {

    private const val CHANNEL_ID = "quiksee_navigation_deliver_v4"
    private const val CHANNEL_NAME = "Near customer — deliver"
    const val NOTIFICATION_ID = 882401

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description =
                "Shows EXIT and Open & Deliver when you are near the customer"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 400, 200, 400)
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            setShowBadge(true)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                setAllowBubbles(true)
            }
        }
        manager.createNotificationChannel(channel)
    }

    /** Matches Flutter: showNavigationDeliverAlert(orderId, title, address). */
    fun showArrivalAlert(
        context: Context,
        orderId: Int,
        title: String?,
        address: String?,
    ) {
        if (orderId <= 0) return
        ensureChannel(context)
        val appContext = context.applicationContext

        val openDeliverIntent = Intent(appContext, MainActivity::class.java).apply {
            action = "in.quiksee.dman.NAVIGATION_DELIVER"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("navigation_deliver_wake", true)
            putExtra("navigation_deliver_order_id", orderId)
            putExtra("order_id", orderId)
            putExtra("open_for_deliver", true)
        }
        val openDeliverPending = PendingIntent.getActivity(
            appContext,
            9100 + (orderId % 1000),
            openDeliverIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val exitIntent = Intent(appContext, MainActivity::class.java).apply {
            action = "in.quiksee.dman.NAVIGATION_EXIT_NEAR"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("navigation_return_wake", true)
            putExtra("navigation_return_order_id", orderId)
            putExtra("order_id", orderId)
            putExtra("dismiss_near_alert", true)
        }
        val exitPending = PendingIntent.getActivity(
            appContext,
            9200 + (orderId % 1000),
            exitIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val addressLine = address?.trim().orEmpty()
        val contentTitle = title?.trim()?.ifEmpty { null }
            ?: "Order #$orderId — near customer"
        val contentText = if (addressLine.isNotEmpty()) {
            addressLine
        } else {
            "EXIT → Quiksee, or Open & Deliver"
        }

        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.notification_icon)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(
                        if (addressLine.isNotEmpty()) {
                            "$contentTitle\n$addressLine\nTap EXIT to leave Maps and open Quiksee"
                        } else {
                            "$contentTitle\nTap EXIT to leave Maps and open Quiksee"
                        },
                    ),
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setOngoing(false)
            .setOnlyAlertOnce(true)
            .setContentIntent(openDeliverPending)
            .setFullScreenIntent(openDeliverPending, true)
            .addAction(0, "EXIT → Quiksee", exitPending)
            .addAction(0, "Open & Deliver", openDeliverPending)
            .setTimeoutAfter(10 * 60 * 1000L)
            .build()

        try {
            NotificationManagerCompat.from(appContext).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS may be denied on Android 13+.
        }
    }

    fun dismiss(context: Context, orderId: Int = 0) {
        try {
            NotificationManagerCompat.from(context.applicationContext)
                .cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
            // ignore
        }
    }
}
