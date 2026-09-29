package `in`.quiksee.dman

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

class NavigationForegroundService : Service() {

    private var orderId: Int = 0
    private var addressLabel: String = ""

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        orderId = intent?.getIntExtra(EXTRA_ORDER_ID, 0) ?: 0
        addressLabel = intent?.getStringExtra(EXTRA_ADDRESS)?.trim().orEmpty()
        if (orderId <= 0) {
            runningOrderId = 0
            stopSelf()
            return START_NOT_STICKY
        }
        runningOrderId = orderId
        try {
            promoteToForeground()
        } catch (_: Exception) {
            runningOrderId = 0
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        if (runningOrderId == orderId) {
            runningOrderId = 0
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun promoteToForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active navigation",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Exit Google Maps and return to Quiksee delivery"
            setShowBadge(false)
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun launchFlags(): Int {
        return Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_SINGLE_TOP or
            Intent.FLAG_ACTIVITY_CLEAR_TOP or
            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
    }

    private fun returnPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(launchFlags())
            putExtra("navigation_return_wake", true)
            putExtra("navigation_return_order_id", orderId)
        }
        return PendingIntent.getActivity(
            this,
            920000 + orderId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun deliverPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(launchFlags())
            putExtra("navigation_deliver_wake", true)
            putExtra("navigation_deliver_order_id", orderId)
        }
        return PendingIntent.getActivity(
            this,
            930000 + orderId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun buildNotification(): Notification {
        val returnPi = returnPendingIntent()
        val deliverPi = deliverPendingIntent()

        val title = "Order #$orderId — Exit Maps"
        val body = if (addressLabel.isNotEmpty()) {
            "$addressLabel\nTap EXIT to leave Google Maps and open Quiksee"
        } else {
            "Tap EXIT to leave Google Maps and open Quiksee"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSmallIcon(R.drawable.notification_icon)
            .setContentIntent(returnPi)
            .setOngoing(true)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_NAVIGATION)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                0,
                "EXIT → Quiksee",
                returnPi,
            )
            .addAction(
                0,
                "Open & Deliver",
                deliverPi,
            )
            .build()
    }

    companion object {
        const val CHANNEL_ID = "quiksee_active_navigation_native_v2"
        private const val NOTIFICATION_ID = 9102
        private const val EXTRA_ORDER_ID = "order_id"
        private const val EXTRA_ADDRESS = "address"

        @Volatile
        private var runningOrderId: Int = 0

        fun start(context: Context, orderId: Int, address: String?) {
            if (orderId <= 0) return
            if (runningOrderId == orderId) return
            try {
                val intent = Intent(context, NavigationForegroundService::class.java).apply {
                    putExtra(EXTRA_ORDER_ID, orderId)
                    putExtra(EXTRA_ADDRESS, address?.trim().orEmpty())
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {
            }
        }

        fun stop(context: Context) {
            runningOrderId = 0
            try {
                context.stopService(Intent(context, NavigationForegroundService::class.java))
            } catch (_: Exception) {
            }
        }
    }
}
