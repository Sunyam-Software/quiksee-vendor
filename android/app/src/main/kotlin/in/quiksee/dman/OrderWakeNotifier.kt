package `in`.quiksee.dman

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Full-screen / heads-up wake when the app is closed or the screen is locked.
 * NativeOrderAlert already rings + vibrates; this notification opens MainActivity.
 */
object OrderWakeNotifier {

    const val CHANNEL_ID = "quiksee_new_order_v5"
    private const val CHANNEL_NAME = "New orders"
    private const val NOTIFICATION_ID = 9001
    private val dismissHandler = Handler(Looper.getMainLooper())

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        // Drop older channels so importance / sound settings apply.
        for (legacy in listOf(
            "quiksee_new_order",
            "quiksee_new_order_v3",
            "quiksee_new_order_v4",
        )) {
            try {
                manager.deleteNotificationChannel(legacy)
            } catch (_: Exception) {
            }
        }
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Wakes phone and opens Quiksee for a new delivery offer"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 900, 250, 900, 250, 900)
            setBypassDnd(true)
            if (alarmUri != null) {
                setSound(alarmUri, audioAttributes)
            }
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
    }

    /**
     * Show only when the Flutter UI is not already on screen.
     */
    fun showOrderAlert(context: Context, data: Map<String, String>) {
        if (AppForegroundState.isResumed) {
            dismiss(context)
            return
        }

        ensureChannel(context.applicationContext)
        val appContext = context.applicationContext

        val orderId = data["order_id"] ?: "?"
        val storeName = data["store_name"]?.takeIf { it.isNotBlank() } ?: "New order"

        val launchIntent = OrderLaunchHelper.buildLaunchIntent(appContext, data)
        val pendingFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val requestCode = (orderId.hashCode() and 0x7fffffff)
        val fullScreenPending = PendingIntent.getActivity(
            appContext,
            requestCode,
            launchIntent,
            pendingFlags,
        )

        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.notification_icon)
            .setContentTitle("New delivery order!")
            .setContentText("$storeName — Order #$orderId")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Opening Quiksee — Order #$orderId. Tap if app does not open."),
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(false)
            .setAutoCancel(true)
            .setOnlyAlertOnce(false)
            .setContentIntent(fullScreenPending)
            .setFullScreenIntent(fullScreenPending, true)
            .setTimeoutAfter(45_000L)
            .setVibrate(longArrayOf(0, 900, 250, 900, 250, 900))
            .setDefaults(NotificationCompat.DEFAULT_LIGHTS)
            .build()

        try {
            NotificationManagerCompat.from(appContext).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
        }

        // Keep FSI alive long enough for lock-screen open; MainActivity dismisses on resume.
        dismissHandler.removeCallbacksAndMessages(null)
        dismissHandler.postDelayed({
            if (!AppForegroundState.isResumed) return@postDelayed
            dismiss(appContext)
        }, 12_000L)
    }

    fun dismiss(context: Context) {
        dismissHandler.removeCallbacksAndMessages(null)
        try {
            NotificationManagerCompat.from(context.applicationContext)
                .cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
    }
}
